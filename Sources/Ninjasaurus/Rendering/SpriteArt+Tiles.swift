/// Tiles, items, props and UI, drawn at 2 pixels per unit.
extension SpriteArt {
    struct GroundColors {
        var top: PixelColor
        var topLight: PixelColor
        var topDark: PixelColor
        var fill: PixelColor
        var fillDark: PixelColor
        var fillLight: PixelColor
    }

    static let grounds: [Theme: GroundColors] = [
        .grass: GroundColors(top: PixelColor(0x48C050), topLight: PixelColor(0x98E870), topDark: PixelColor(0x207830), fill: PixelColor(0xB07038), fillDark: PixelColor(0x7C4820), fillLight: PixelColor(0xD09050)),
        .cave: GroundColors(top: PixelColor(0x9098B0), topLight: PixelColor(0xC8D0E0), topDark: PixelColor(0x505870), fill: PixelColor(0x384870), fillDark: PixelColor(0x243050), fillLight: PixelColor(0x506090)),
        .sky: GroundColors(top: PixelColor(0xF0D890), topLight: PixelColor(0xFCF0C0), topDark: PixelColor(0xB89850), fill: PixelColor(0xD8C0A0), fillDark: PixelColor(0xA89070), fillLight: PixelColor(0xF0E0C8)),
        .lava: GroundColors(top: PixelColor(0x707080), topLight: PixelColor(0xA0A0B0), topDark: PixelColor(0x404050), fill: PixelColor(0x4A2828), fillDark: PixelColor(0x301818), fillLight: PixelColor(0x684040)),
    ]

    static let scenery: [String: PixelSprite] = {
        var out: [String: PixelSprite] = [:]
        for (theme, colors) in grounds {
            out["tile.\(theme.rawValue).groundTop"] = groundTop(colors)
            out["tile.\(theme.rawValue).fill"] = groundFill(colors, seed: UInt64(theme.rawValue.count))
        }
        out["tile.brick"] = brick()
        out["tile.question1"] = question(PixelColor(0xF8C830))
        out["tile.question2"] = question(PixelColor(0xE0A820))
        out["tile.question3"] = question(PixelColor(0xFCE060))
        out["tile.used"] = usedBlock()
        out["tile.logCap"] = logCap()
        out["tile.logBody"] = logBody()
        out["tile.cloud"] = cloud()
        for (index, rx) in [10.0, 6.5, 2.5, 6.5].enumerated() {
            out["tile.coin\(index + 1)"] = coin(rx: rx)
        }
        out["tile.hazard.spikes"] = spikes()
        out["tile.hazard.lava1"] = lava(0)
        out["tile.hazard.lava2"] = lava(1)
        out["tile.lantern"] = lantern(lit: false)
        out["tile.lanternLit"] = lantern(lit: true)
        out["tile.wall"] = wall()
        out["prop.torii"] = torii()
        out["prop.toriiDark"] = torii().recolored { _ in Colors.darkStone }
        out["item.onigiri"] = onigiri()
        out["item.scroll"] = scroll(paper: PixelColor(0xF0D8A8), ribbon: Colors.red, emblem: true)
        out["item.greenScroll"] = scroll(paper: PixelColor(0x68C868), ribbon: Colors.gold, emblem: false)
        out["item.katana"] = katana()
        out["shuriken1"] = shuriken(rotated: false)
        out["shuriken2"] = shuriken(rotated: true)
        out.merge(hud) { _, new in new }
        return out
    }()

    private static let ink = PixelColor(0x101018)

    private static func speckle(_ p: inout PixelPainter, from y0: Int, to y1: Int, _ colors: GroundColors, seed: UInt64) {
        var rng = SeededRandom(seed: seed)
        for _ in 0..<26 {
            let x = Int(rng.next() % 32), y = y0 + Int(rng.next() % UInt64(y1 - y0 + 1))
            p.fillRect(x, y, x + 1, y, rng.nextUnit() < 0.6 ? colors.fillDark : colors.fillLight)
        }
        for _ in 0..<3 {
            let x = Int(rng.next() % 28), y = y0 + Int(rng.next() % UInt64(max(1, y1 - y0 - 3)))
            p.fillEllipse(cx: Double(x) + 2, cy: Double(y) + 1.5, rx: 2.2, ry: 1.4, colors.fillLight)
            p.fillRect(x + 1, y + 2, x + 3, y + 2, colors.fillDark)
        }
    }

    static func groundTop(_ c: GroundColors) -> PixelSprite {
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(0, 0, 31, 31, c.fill)
        speckle(&p, from: 10, to: 31, c, seed: 11)
        p.fillRect(0, 8, 31, 9, c.fillDark)
        p.fillRect(0, 1, 31, 7, c.top)
        p.fillRect(0, 7, 31, 7, c.topDark)
        for x in stride(from: 1, to: 32, by: 6) {
            p.fillRect(x, 7, x + 1, 8, c.topDark)
        }
        p.fillRect(0, 1, 31, 2, c.topLight)
        for x in stride(from: 0, to: 32, by: 5) {
            p.fillRect(x + 1, 0, x + 2, 0, c.topLight)
            p.fillRect(x + 3, 3, x + 3, 4, c.topLight)
        }
        return p.sprite(scale: 2)
    }

    static func groundFill(_ c: GroundColors, seed: UInt64) -> PixelSprite {
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(0, 0, 31, 31, c.fill)
        speckle(&p, from: 0, to: 31, c, seed: 23 + seed)
        return p.sprite(scale: 2)
    }

    static func brick() -> PixelSprite {
        let face = PixelColor(0xC85838), light = PixelColor(0xE88060), dark = PixelColor(0x8C3820), mortar = PixelColor(0x60301C)
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(0, 0, 31, 31, mortar)
        for row in 0..<2 {
            let y0 = row * 16 + 1
            let offset = row == 0 ? 0 : 8
            for i in -1..<3 {
                let x0 = i * 16 + offset + 1
                let x1 = x0 + 13
                guard x1 >= 0, x0 <= 31 else { continue }
                p.fillRect(max(0, x0), y0, min(31, x1), y0 + 13, face)
                p.fillRect(max(0, x0), y0, min(31, x1), y0, light)
                if x0 >= 0 { p.fillRect(x0, y0, x0, y0 + 13, light) }
                p.fillRect(max(0, x0), y0 + 13, min(31, x1), y0 + 13, dark)
                if x1 <= 31 { p.fillRect(x1, y0 + 1, x1, y0 + 13, dark) }
            }
        }
        return p.sprite(scale: 2)
    }

    private static func block(_ face: PixelColor, light: PixelColor, dark: PixelColor, edge: PixelColor) -> PixelPainter {
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(0, 0, 31, 31, edge)
        p.fillRect(2, 2, 29, 29, face)
        p.fillRect(2, 2, 29, 3, light); p.fillRect(2, 2, 3, 29, light)
        p.fillRect(2, 28, 29, 29, dark); p.fillRect(28, 2, 29, 29, dark)
        for (x, y) in [(0, 0), (31, 0), (0, 31), (31, 31)] {
            p[x, y] = .clear
        }
        for (x, y) in [(4, 4), (26, 4), (4, 26), (26, 26)] {
            p.fillRect(x, y, x + 1, y + 1, dark)
        }
        return p
    }

    static func question(_ yellow: PixelColor) -> PixelSprite {
        var p = block(yellow, light: yellow.lightened(0.45), dark: yellow.darkened(0.35), edge: PixelColor(0x805018))
        let glyph = PixelColor(0x7A4810)
        p.fillRect(11, 7, 20, 9, glyph)
        p.fillRect(9, 9, 12, 12, glyph)
        p.fillRect(19, 9, 22, 14, glyph)
        p.fillRect(14, 14, 20, 16, glyph)
        p.fillRect(14, 16, 17, 20, glyph)
        p.fillRect(14, 22, 17, 25, glyph)
        return p.sprite(scale: 2)
    }

    static func usedBlock() -> PixelSprite {
        let brown = PixelColor(0xA86838)
        let p = block(brown, light: brown.lightened(0.35), dark: brown.darkened(0.35), edge: PixelColor(0x503018))
        return p.sprite(scale: 2)
    }

    static func logCap() -> PixelSprite {
        let bark = PixelColor(0x8C5A2C), barkDark = PixelColor(0x5C3814), wood = PixelColor(0xE0B878), ring = PixelColor(0xB08848)
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(0, 8, 31, 31, bark)
        for x in [3, 11, 20, 27] { p.fillRect(x, 10, x, 31, barkDark) }
        p.fillRect(0, 8, 0, 31, barkDark); p.fillRect(31, 8, 31, 31, barkDark)
        p.fillEllipse(cx: 16, cy: 8, rx: 15.5, ry: 7, barkDark)
        p.fillEllipse(cx: 16, cy: 8, rx: 14, ry: 5.8, wood)
        p.fillEllipse(cx: 16, cy: 8, rx: 9, ry: 3.6, ring)
        p.fillEllipse(cx: 16, cy: 8, rx: 7.5, ry: 2.8, wood)
        p.fillEllipse(cx: 16, cy: 8, rx: 3.5, ry: 1.4, ring)
        return p.sprite(scale: 2)
    }

    static func logBody() -> PixelSprite {
        let bark = PixelColor(0x8C5A2C), barkDark = PixelColor(0x5C3814), barkLight = PixelColor(0xA87040)
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(0, 0, 31, 31, bark)
        for x in [3, 11, 20, 27] { p.fillRect(x, 0, x, 31, barkDark) }
        for x in [6, 15, 23] { p.fillRect(x, 0, x, 31, barkLight) }
        p.fillRect(0, 0, 0, 31, barkDark); p.fillRect(31, 0, 31, 31, barkDark)
        return p.sprite(scale: 2)
    }

    static func cloud() -> PixelSprite {
        let white = PixelColor.white, shade = PixelColor(0xB8DCF8), edge = PixelColor(0x78B0E8)
        var p = PixelPainter(width: 32, height: 32)
        p.fillEllipse(cx: 8, cy: 9, rx: 8.5, ry: 8, edge)
        p.fillEllipse(cx: 19, cy: 7.5, rx: 9.5, ry: 8.5, edge)
        p.fillEllipse(cx: 27, cy: 10, rx: 5.5, ry: 6, edge)
        p.fillRect(0, 10, 31, 17, edge)
        p.fillEllipse(cx: 8, cy: 9, rx: 7.5, ry: 7, white)
        p.fillEllipse(cx: 19, cy: 7.5, rx: 8.5, ry: 7.5, white)
        p.fillEllipse(cx: 27, cy: 10, rx: 4.5, ry: 5, white)
        p.fillRect(1, 10, 30, 15, white)
        p.fillRect(1, 13, 30, 15, shade)
        p.fillRect(3, 16, 28, 16, shade)
        return p.sprite(scale: 2)
    }

    static func coin(rx: Double) -> PixelSprite {
        let gold = Colors.gold, dark = Colors.darkGold, pale = Colors.paleGold
        var p = PixelPainter(width: 32, height: 32)
        p.fillEllipse(cx: 16, cy: 16, rx: rx + 1.5, ry: 13.5, PixelColor(0x805010))
        p.fillEllipse(cx: 16, cy: 16, rx: rx, ry: 12, dark)
        p.fillEllipse(cx: 15.5, cy: 15.5, rx: max(1, rx - 1.5), ry: 10.5, gold)
        if rx > 4 {
            p.fillEllipse(cx: 16, cy: 16, rx: rx - 3.5, ry: 8, dark)
            p.fillEllipse(cx: 16, cy: 16, rx: rx - 4.5, ry: 7, gold)
            p.fillEllipse(cx: 13.5, cy: 10, rx: rx * 0.25, ry: 2.5, pale)
        }
        return p.sprite(scale: 2)
    }

    static func spikes() -> PixelSprite {
        var p = PixelPainter(width: 32, height: 32)
        let base = grounds[.cave]!
        p.fillRect(0, 24, 31, 31, base.fill)
        p.fillRect(0, 24, 31, 25, base.topDark)
        for x in [6.0, 16.0, 26.0] {
            p.fillPolygon([(x - 4.5, 25), (x, 8), (x + 4.5, 25)], PixelColor(0x505868))
            p.fillPolygon([(x - 3, 24), (x, 10), (x + 3, 24)], PixelColor(0xC0C8D8))
            p.fillPolygon([(x, 10), (x + 3, 24), (x, 24)], PixelColor(0x8890A0))
        }
        return p.sprite(scale: 2)
    }

    static func lava(_ frame: Int) -> PixelSprite {
        let lava = Colors.lava, bright = Colors.lavaBright, dark = PixelColor(0xC03810)
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(0, 8, 31, 31, lava)
        for x in stride(from: frame == 0 ? 0 : 5, to: 32, by: 10) {
            p.fillEllipse(cx: Double(x) + 3, cy: 8, rx: 4.5, ry: 3, lava)
        }
        p.fillRect(0, 9, 31, 10, bright)
        var rng = SeededRandom(seed: UInt64(40 + frame))
        for _ in 0..<7 {
            let x = Int(rng.next() % 30), y = 12 + Int(rng.next() % 18)
            p.fillEllipse(cx: Double(x) + 1, cy: Double(y), rx: 2, ry: 1.2, rng.nextUnit() < 0.5 ? bright : dark)
        }
        return p.sprite(scale: 2)
    }

    static func lantern(lit: Bool) -> PixelSprite {
        let stone = PixelColor(0x9098A8), stoneDark = PixelColor(0x585F70), stoneLight = PixelColor(0xC0C8D8)
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(10, 27, 21, 31, stoneDark); p.fillRect(11, 27, 20, 28, stone)
        p.fillRect(13, 19, 18, 27, stone); p.fillRect(13, 19, 14, 27, stoneLight)
        p.fillRect(9, 10, 22, 19, stone); p.fillRect(9, 10, 22, 11, stoneLight); p.fillRect(9, 18, 22, 19, stoneDark)
        p.fillPolygon([(16, 1), (26, 10), (6, 10)], stoneDark)
        p.fillPolygon([(16, 3), (23, 9), (9, 9)], stone)
        if lit {
            p.fillRect(12, 12, 19, 17, Colors.yellow)
            p.fillRect(14, 13, 17, 15, PixelColor(0xFFF8C0))
        } else {
            p.fillRect(12, 12, 19, 17, PixelColor(0x202838))
        }
        p.outline(ink)
        return p.sprite(scale: 2)
    }

    static func wall() -> PixelSprite {
        let face = PixelColor(0x8890A0), light = PixelColor(0xB8C0D0), dark = PixelColor(0x505868), mortar = PixelColor(0x384050)
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(0, 0, 31, 31, mortar)
        for (x, y) in [(1, 1), (17, 1), (1, 17), (17, 17)] {
            p.fillRect(x, y, x + 13, y + 13, face)
            p.fillRect(x, y, x + 13, y, light); p.fillRect(x, y, x, y + 13, light)
            p.fillRect(x, y + 13, x + 13, y + 13, dark); p.fillRect(x + 13, y, x + 13, y + 13, dark)
        }
        return p.sprite(scale: 2)
    }

    static func torii() -> PixelSprite {
        let red = PixelColor(0xE03028), redDark = PixelColor(0x901818), black = PixelColor(0x181820), stone = PixelColor(0x8890A0)
        var p = PixelPainter(width: 64, height: 96)
        for x in [10, 46] {
            p.fillRect(x, 14, x + 7, 88, red)
            p.fillRect(x + 6, 14, x + 7, 88, redDark)
            p.fillRect(x - 3, 88, x + 10, 95, stone)
            p.fillRect(x - 3, 88, x + 10, 89, stone.lightened(0.3))
        }
        p.fillPolygon([(0, 4), (63.5, 4), (60, 13), (3.5, 13)], red)
        p.fillRect(3, 11, 60, 13, redDark)
        p.fillPolygon([(0, 1), (63.5, 1), (63.5, 5), (0, 5)], black)
        p.fillRect(29, 13, 34, 24, red)
        p.fillRect(4, 24, 59, 30, red); p.fillRect(4, 29, 59, 30, redDark)
        return p.sprite(scale: 2)
    }

    // MARK: Items

    static func onigiri() -> PixelSprite {
        var p = PixelPainter(width: 32, height: 32)
        p.fillPolygon([(16, 3), (30, 27), (2, 27)], PixelColor(0xE0E4EC))
        p.fillEllipse(cx: 16, cy: 5, rx: 3, ry: 2.5, PixelColor(0xE0E4EC))
        p.fillPolygon([(16, 5), (27, 25), (5, 25)], .white)
        p.fillRect(10, 20, 21, 29, PixelColor(0x203828))
        p.fillRect(11, 21, 12, 27, PixelColor(0x38583C))
        p.fillRect(11, 14, 12, 16, ink); p.fillRect(19, 14, 20, 16, ink)
        p.fillRect(9, 17, 10, 17, PixelColor(0xF8A0A0)); p.fillRect(21, 17, 22, 17, PixelColor(0xF8A0A0))
        p.outline(ink)
        return p.sprite(scale: 2)
    }

    static func scroll(paper: PixelColor, ribbon: PixelColor, emblem: Bool) -> PixelSprite {
        var p = PixelPainter(width: 32, height: 32)
        p.fillRect(6, 8, 26, 24, paper)
        p.fillRect(6, 8, 26, 9, paper.lightened(0.3)); p.fillRect(6, 23, 26, 24, paper.darkened(0.25))
        p.fillEllipse(cx: 6, cy: 16, rx: 3.5, ry: 9, paper.darkened(0.3))
        p.fillEllipse(cx: 6, cy: 16, rx: 1.8, ry: 6, paper.darkened(0.55))
        p.fillEllipse(cx: 26, cy: 16, rx: 3.5, ry: 9, paper.darkened(0.3))
        p.fillEllipse(cx: 26, cy: 16, rx: 1.8, ry: 6, paper.darkened(0.55))
        p.fillRect(14, 8, 18, 24, ribbon); p.fillRect(14, 8, 14, 24, ribbon.lightened(0.3))
        if emblem {
            p.fillPolygon([(16, 11), (17.5, 14.5), (21, 16), (17.5, 17.5), (16, 21), (14.5, 17.5), (11, 16), (14.5, 14.5)], PixelColor(0xC0C8D8))
            p.fillRect(15, 15, 16, 16, ink)
        } else {
            p.fillRect(15, 12, 16, 20, .white); p.fillRect(14, 13, 14, 13, .white)
        }
        p.outline(ink)
        return p.sprite(scale: 2)
    }

    static func katana() -> PixelSprite {
        var p = PixelPainter(width: 32, height: 32)
        p.line(8, 24, 29, 3, PixelColor(0xE8F0F8), thickness: 3)
        p.line(9, 22, 30, 1, PixelColor(0xFFFFFF))
        p.line(10, 26, 30, 6, PixelColor(0x8090A8))
        p.fillPolygon([(6, 20), (11, 25), (9, 27), (4, 22)], Colors.gold)
        p.line(2, 30, 7, 25, Colors.red, thickness: 3)
        p.fillRect(2, 29, 3, 30, Colors.darkRed)
        p.outline(ink)
        return p.sprite(scale: 2)
    }

    static func shuriken(rotated: Bool) -> PixelSprite {
        var p = PixelPainter(width: 16, height: 16)
        let steel = PixelColor(0xC8D0E0)
        if rotated {
            p.fillPolygon([(2, 2), (8, 5), (14, 2), (11, 8), (14, 14), (8, 11), (2, 14), (5, 8)], steel)
        } else {
            p.fillPolygon([(8, 0), (10.5, 5.5), (16, 8), (10.5, 10.5), (8, 16), (5.5, 10.5), (0, 8), (5.5, 5.5)], steel)
        }
        p.fillRect(7, 7, 8, 8, ink)
        p.outline(PixelColor(0x384050))
        return p.sprite(scale: 2)
    }

    // MARK: HUD, controls, effects

    static let hud: [String: PixelSprite] = {
        var out: [String: PixelSprite] = [:]
        func icon(_ body: (inout PixelPainter) -> Void, outline: PixelColor? = ink) -> PixelSprite {
            var p = PixelPainter(width: 16, height: 16)
            body(&p)
            if let outline { p.outline(outline) }
            return p.sprite(scale: 2)
        }
        out["hud.heart"] = icon { p in
            p.fillEllipse(cx: 5, cy: 5.5, rx: 4.5, ry: 4.5, Colors.red)
            p.fillEllipse(cx: 11, cy: 5.5, rx: 4.5, ry: 4.5, Colors.red)
            p.fillPolygon([(0.5, 7), (15.5, 7), (8, 15.5)], Colors.red)
            p.fillRect(3, 3, 4, 4, PixelColor(0xFF9090))
        }
        out["hud.heartEmpty"] = out["hud.heart"]!.recolored { _ in PixelColor(0x585868) }
        out["hud.coin"] = icon { p in
            p.fillEllipse(cx: 8, cy: 8, rx: 6, ry: 7.5, Colors.darkGold)
            p.fillEllipse(cx: 7.5, cy: 7.5, rx: 4.5, ry: 6, Colors.gold)
            p.fillRect(5, 4, 6, 6, Colors.paleGold)
        }
        out["hud.lock"] = icon { p in
            p.fillEllipse(cx: 8, cy: 6, rx: 5, ry: 5, PixelColor(0xA0A8B8))
            p.fillEllipse(cx: 8, cy: 6, rx: 3, ry: 3, .clear)
            p.fillRect(3, 7, 12, 15, Colors.gold)
            p.fillRect(7, 10, 8, 12, Colors.darkGold)
        }
        out["hud.pause"] = icon({ p in
            p.fillRect(3, 2, 6, 13, .white)
            p.fillRect(9, 2, 12, 13, .white)
        }, outline: nil)
        out["hud.ninjaHead"] = icon { p in
            p.fillEllipse(cx: 8, cy: 8, rx: 7.5, ry: 7.5, NinjaColors.standard.gi)
            p.fillEllipse(cx: 8.5, cy: 9.5, rx: 5, ry: 2.5, NinjaColors.standard.skin)
            p.fillRect(5, 8, 6, 10, .white); p.fillRect(10, 8, 11, 10, .white)
            p.fillRect(6, 9, 6, 10, ink); p.fillRect(11, 9, 11, 10, ink)
            p.fillRect(1, 5, 14, 6, NinjaColors.standard.bandana)
        }
        out["ui.arrowLeft"] = icon({ p in
            p.fillPolygon([(1, 8), (8, 1), (8, 15)], .white)
            p.fillRect(7, 5, 15, 11, .white)
        }, outline: nil)
        out["ui.arrowRight"] = icon({ p in
            p.fillPolygon([(15, 8), (8, 1), (8, 15)], .white)
            p.fillRect(1, 5, 9, 11, .white)
        }, outline: nil)
        out["ui.arrowUp"] = icon({ p in
            p.fillPolygon([(8, 1), (1, 8), (15, 8)], .white)
            p.fillRect(5, 7, 11, 15, .white)
        }, outline: nil)
        out["ui.star"] = shuriken(rotated: false).recolored { _ in .white }
        out["fx.chip"] = icon { p in
            p.fillRect(3, 3, 12, 12, PixelColor(0xC85838))
            p.fillRect(3, 3, 12, 4, PixelColor(0xE88060))
        }
        out["fx.puff1"] = icon({ p in
            p.fillEllipse(cx: 8, cy: 9, rx: 6, ry: 5, .white)
            p.fillEllipse(cx: 4, cy: 6, rx: 3, ry: 3, .white)
            p.fillEllipse(cx: 11, cy: 5, rx: 3.5, ry: 3.5, .white)
        }, outline: PixelColor(0xC8D0E0))
        out["fx.puff2"] = icon({ p in
            for (x, y) in [(2.0, 2.0), (13.0, 3.0), (3.0, 13.0), (12.0, 12.0), (8.0, 1.0)] {
                p.fillEllipse(cx: x, cy: y, rx: 2, ry: 2, .white)
            }
        }, outline: nil)
        out["fx.spark"] = icon({ p in
            p.fillPolygon([(8, 0), (9.5, 6.5), (16, 8), (9.5, 9.5), (8, 16), (6.5, 9.5), (0, 8), (6.5, 6.5)], Colors.paleGold)
            p.fillRect(7, 7, 8, 8, .white)
        }, outline: nil)
        out["fx.star"] = icon({ p in
            p.fillPolygon([(8, 0), (10, 6), (16, 6), (11, 9.5), (13, 16), (8, 12), (3, 16), (5, 9.5), (0, 6), (6, 6)], Colors.yellow)
        }, outline: Colors.darkGold)
        return out
    }()
}
