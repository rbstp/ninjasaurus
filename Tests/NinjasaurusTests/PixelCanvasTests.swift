import XCTest
@testable import Ninjasaurus

final class PixelCanvasTests: XCTestCase {
    private let palette: Palette = ["R": PixelColor(0xFF0000), "G": PixelColor(0x00FF00)]

    func testSpriteDimensionsAndTransparency() throws {
        let sprite = try PixelSprite(validating: palette, rows: ["R.G", ".R."])
        XCTAssertEqual(sprite.width, 3)
        XCTAssertEqual(sprite.height, 2)
        XCTAssertEqual(sprite.pixel(x: 0, y: 0), PixelColor(0xFF0000))
        XCTAssertTrue(sprite.pixel(x: 1, y: 0).isTransparent)
        XCTAssertEqual(sprite.pixel(x: 2, y: 0), PixelColor(0x00FF00))
    }

    func testValidationErrors() {
        XCTAssertThrowsError(try PixelSprite(validating: palette, rows: ["RR", "R"])) { error in
            XCTAssertEqual(error as? PixelSpriteError, .raggedRow(index: 1))
        }
        XCTAssertThrowsError(try PixelSprite(validating: palette, rows: ["RZ"])) { error in
            XCTAssertEqual(error as? PixelSpriteError, .unknownCharacter("Z", row: 0))
        }
        XCTAssertThrowsError(try PixelSprite(validating: palette, rows: [])) { error in
            XCTAssertEqual(error as? PixelSpriteError, .emptySprite)
        }
    }

    func testFlipAndRecolor() throws {
        let sprite = try PixelSprite(validating: palette, rows: ["R.G"])
        let flipped = sprite.flippedHorizontally()
        XCTAssertEqual(flipped.pixel(x: 0, y: 0), PixelColor(0x00FF00))
        XCTAssertEqual(flipped.pixel(x: 2, y: 0), PixelColor(0xFF0000))
        let white = sprite.flashedWhite()
        XCTAssertEqual(white.pixel(x: 0, y: 0), .white)
        XCTAssertTrue(white.pixel(x: 1, y: 0).isTransparent)
        let mapped = sprite.recolored(mapping: [PixelColor(0xFF0000): PixelColor(0x0000FF)])
        XCTAssertEqual(mapped.pixel(x: 0, y: 0), PixelColor(0x0000FF))
        XCTAssertEqual(mapped.pixel(x: 2, y: 0), PixelColor(0x00FF00))
    }

    func testCanvasPremultipliesAlpha() throws {
        var canvas = PixelCanvas(width: 4, height: 4)
        let half = PixelColor(r: 200, g: 100, b: 0, a: 128)
        let sprite = try PixelSprite(validating: ["H": half], rows: ["H"])
        canvas.draw(sprite, x: 1, y: 2)
        let drawn = canvas.pixel(x: 1, y: 2)
        XCTAssertEqual(drawn.a, 128)
        XCTAssertEqual(Int(drawn.r), 100, accuracy: 1)
        XCTAssertEqual(Int(drawn.g), 50, accuracy: 1)
        XCTAssertTrue(canvas.pixel(x: 0, y: 0).isTransparent)
    }

    func testAtlasRectsDoNotOverlapAndFit() throws {
        var sprites: [String: PixelSprite] = [:]
        for i in 0..<40 {
            let size = 8 + (i % 3) * 8
            let rows = Array(repeating: String(repeating: "R", count: size), count: size)
            sprites["s\(i)"] = try PixelSprite(validating: palette, rows: rows)
        }
        let layout = try AtlasBuilder.build(sprites, size: 256)
        let rects = Array(layout.rects.values)
        XCTAssertEqual(rects.count, 40)
        for i in 0..<rects.count {
            for j in (i + 1)..<rects.count {
                XCTAssertFalse(rects[i].intersects(rects[j]), "\(rects[i]) overlaps \(rects[j])")
            }
            XCTAssertLessThanOrEqual(rects[i].x + rects[i].width, 256)
            XCTAssertLessThanOrEqual(rects[i].y + rects[i].height, 256)
        }
        // The drawn pixel lands where the rect says it does.
        let rect = layout.rects["s0"]!
        XCTAssertEqual(layout.canvas.pixel(x: rect.x, y: rect.y), PixelColor(0xFF0000))
    }

    func testAtlasThrowsWhenTooSmall() throws {
        let big = try PixelSprite(validating: palette, rows: Array(repeating: String(repeating: "R", count: 100), count: 100))
        XCTAssertThrowsError(try AtlasBuilder.build(["a": big], size: 64)) { error in
            XCTAssertEqual(error as? AtlasError, .doesNotFit(size: 64))
        }
    }

    func testRegistryFitsInAnAtlasAndHasNoDuplicates() throws {
        let layout = try AtlasBuilder.buildFitting(SpriteArt.registry)
        XCTAssertEqual(layout.rects.count, SpriteArt.registry.count)
        XCTAssertLessThanOrEqual(layout.canvas.width, 2048)
        for name in ["ninja.small.idle", "ninja.big.idle", "raptor.walk1", "rex.idle", "tile.brick", "item.onigiri", "hud.heart"] {
            XCTAssertEqual(SpriteArt.registry[name]?.scale, 2, name)
        }
        XCTAssertEqual(SpriteArt.registry["ninja.small.idle"]?.unitHeight, 16)
        XCTAssertEqual(SpriteArt.registry["ninja.big.idle"]?.unitHeight, 32)
        XCTAssertEqual(SpriteArt.registry["tile.brick"]?.unitWidth, 16)
    }

    func testPainterShapesOutlineAndBevel() {
        var p = PixelPainter(width: 8, height: 8)
        p.fillEllipse(cx: 4, cy: 4, rx: 3, ry: 3, PixelColor(0x808080))
        XCTAssertFalse(p[4, 4].isTransparent)
        XCTAssertTrue(p[0, 0].isTransparent)
        p.outline(.black)
        XCTAssertEqual(p[4, 1], .black)
        XCTAssertEqual(p[4, 4], PixelColor(0x808080))
        p.bevel(outline: .black)
        XCTAssertGreaterThan(p[4, 2].r, 0x80)
        XCTAssertLessThan(p[4, 6].r, 0x80)
        var q = PixelPainter(width: 8, height: 8)
        q.fillPolygon([(0, 0), (8, 0), (8, 8), (0, 8)], .white)
        XCTAssertEqual(q.pixels.filter { !$0.isTransparent }.count, 64)
        q.line(0, 0, 7, 7, .black)
        XCTAssertEqual(q[3, 3], .black)
        XCTAssertEqual(q[3, 4], .white)
        let sprite = q.sprite(scale: 2)
        XCTAssertEqual(sprite.unitWidth, 4)
    }

    func testAnimationClipFrames() {
        let clip = AnimationClip(["a", "b", "c"], hold: 4)
        XCTAssertEqual(clip.frame(at: 0), "a")
        XCTAssertEqual(clip.frame(at: 3), "a")
        XCTAssertEqual(clip.frame(at: 4), "b")
        XCTAssertEqual(clip.frame(at: 11), "c")
        XCTAssertEqual(clip.frame(at: 12), "a")
        let once = AnimationClip(["a", "b"], hold: 2, loops: false)
        XCTAssertEqual(once.frame(at: 100), "b")
    }

    func testFontHasEveryGlyphTheGameUses() {
        for character in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?:.-x'>" {
            XCTAssertNotNil(PixelFont.spriteName(for: character), "missing glyph \(character)")
        }
        XCTAssertEqual(PixelFont.spriteName(for: "a"), PixelFont.spriteName(for: "A"))
        XCTAssertNil(PixelFont.spriteName(for: "€"))
    }
}
