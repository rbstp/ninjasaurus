struct PixelCanvas: Sendable {
    let width: Int
    let height: Int
    private(set) var bytes: [UInt8]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        bytes = [UInt8](repeating: 0, count: width * height * 4)
    }

    mutating func draw(_ sprite: PixelSprite, x originX: Int, y originY: Int) {
        for y in 0..<sprite.height {
            let ty = originY + y
            guard ty >= 0, ty < height else { continue }
            for x in 0..<sprite.width {
                let tx = originX + x
                guard tx >= 0, tx < width else { continue }
                let color = sprite.pixel(x: x, y: y)
                guard !color.isTransparent else { continue }
                let index = (ty * width + tx) * 4
                let alpha = UInt32(color.a)
                bytes[index] = UInt8((UInt32(color.r) * alpha + 127) / 255)
                bytes[index + 1] = UInt8((UInt32(color.g) * alpha + 127) / 255)
                bytes[index + 2] = UInt8((UInt32(color.b) * alpha + 127) / 255)
                bytes[index + 3] = color.a
            }
        }
    }

    func pixel(x: Int, y: Int) -> PixelColor {
        let index = (y * width + x) * 4
        return PixelColor(r: bytes[index], g: bytes[index + 1], b: bytes[index + 2], a: bytes[index + 3])
    }
}

struct AtlasRect: Equatable, Sendable {
    var x: Int
    var y: Int
    var width: Int
    var height: Int

    func intersects(_ other: AtlasRect) -> Bool {
        x < other.x + other.width && x + width > other.x && y < other.y + other.height && y + height > other.y
    }
}

struct AtlasLayout: Sendable {
    let canvas: PixelCanvas
    let rects: [String: AtlasRect]
}

enum AtlasError: Error, Equatable {
    case doesNotFit(size: Int)
}

enum AtlasBuilder {
    static func build(_ sprites: [String: PixelSprite], size: Int, gutter: Int = 1) throws -> AtlasLayout {
        let ordered = sprites.sorted { lhs, rhs in
            if lhs.value.height != rhs.value.height { return lhs.value.height > rhs.value.height }
            return lhs.key < rhs.key
        }
        var canvas = PixelCanvas(width: size, height: size)
        var rects: [String: AtlasRect] = [:]
        var cursorX = gutter
        var cursorY = gutter
        var shelfHeight = 0
        for (name, sprite) in ordered {
            if cursorX + sprite.width + gutter > size {
                cursorX = gutter
                cursorY += shelfHeight + gutter
                shelfHeight = 0
            }
            if cursorY + sprite.height + gutter > size {
                throw AtlasError.doesNotFit(size: size)
            }
            canvas.draw(sprite, x: cursorX, y: cursorY)
            rects[name] = AtlasRect(x: cursorX, y: cursorY, width: sprite.width, height: sprite.height)
            cursorX += sprite.width + gutter
            shelfHeight = max(shelfHeight, sprite.height)
        }
        return AtlasLayout(canvas: canvas, rects: rects)
    }

    static func buildFitting(_ sprites: [String: PixelSprite]) throws -> AtlasLayout {
        var lastError: Error = AtlasError.doesNotFit(size: 2048)
        for size in [256, 512, 1024, 2048] {
            do {
                return try build(sprites, size: size)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}
