struct NinjaColors: Sendable {
    var outline = PixelColor(0x101018)
    var gi = PixelColor(0x28345A)
    var giLight = PixelColor(0x405088)
    var boot = PixelColor(0x181C30)
    var skin = PixelColor(0xF8C8A0)
    var bandana = PixelColor(0x3078F0)
    var bandanaLight = PixelColor(0x80B8FF)
    var eye = PixelColor.white
    var pupil = PixelColor(0x101018)
    var belt = Colors.gold
    var beltDark = Colors.darkGold
    var steel = PixelColor(0xE8F0F8)
    var steelDark = PixelColor(0x8090A8)

    static let standard = NinjaColors()
    static let shuriken = NinjaColors(gi: PixelColor(0xE8ECF4), giLight: PixelColor(0xFFFFFF), boot: PixelColor(0x9098A8), belt: PixelColor(0x28345A), beltDark: PixelColor(0x181C30))
    static let gold1 = NinjaColors(gi: Colors.gold, giLight: Colors.paleGold, boot: Colors.darkGold, bandana: PixelColor(0xFFFFFF), bandanaLight: PixelColor(0xFFFFFF))
    static let gold2 = NinjaColors(gi: Colors.orange, giLight: Colors.yellow, boot: Colors.darkGold, bandana: PixelColor(0xFFFFFF), bandanaLight: PixelColor(0xFFFFFF))
    static let gold3 = NinjaColors(gi: PixelColor(0xFFFFFF), giLight: PixelColor(0xFFFFFF), boot: Colors.paleGold, bandana: Colors.gold, bandanaLight: Colors.paleGold)
}

enum NinjaPose: String, CaseIterable {
    case idle, walk1, walk2, jump, dead, throwing = "throw", sword1, sword2, sword3, sword4
}

/// The hero, drawn facing right at 2 pixels per unit.
extension SpriteArt {
    static let ninja: [String: PixelSprite] = {
        var out: [String: PixelSprite] = [:]
        let variants: [(String, NinjaColors)] = [("", .standard), ("@shuriken", .shuriken), ("@gold1", .gold1), ("@gold2", .gold2), ("@gold3", .gold3)]
        for pose in NinjaPose.allCases {
            for (suffix, colors) in variants {
                out["ninja.small.\(pose.rawValue)\(suffix)"] = smallNinja(colors, pose)
                out["ninja.big.\(pose.rawValue)\(suffix)"] = bigNinja(colors, pose)
            }
        }
        return out
    }()

    private static func band(_ p: inout PixelPainter, y0: Int, y1: Int, _ c: NinjaColors) {
        for y in y0...y1 {
            for x in 0..<p.width where !p[x, y].isTransparent {
                p[x, y] = y == y0 ? c.bandanaLight : c.bandana
            }
        }
    }

    private static func eyes(_ p: inout PixelPainter, x: Int, y: Int, h: Int, _ c: NinjaColors, dead: Bool) {
        for ex in [x, x + 6] {
            p.fillRect(ex, y, ex + 2, y + h, c.eye)
            if dead {
                p.line(ex, y, ex + 2, y + h, c.pupil)
                p.line(ex + 2, y, ex, y + h, c.pupil)
            } else {
                p.fillRect(ex + 1, y + 1, ex + 2, y + 2, c.pupil)
            }
        }
    }

    private static func swordUp(_ p: inout PixelPainter, x: Int, top: Int, hand: Int, _ c: NinjaColors) {
        p.fillRect(x, top, x + 1, hand - 3, c.steel)
        p.fillRect(x + 2, top + 1, x + 2, hand - 3, c.steelDark)
        p.fillRect(x - 1, hand - 2, x + 3, hand - 2, c.beltDark)
        p.fillRect(x, hand + 3, x + 2, hand + 5, c.beltDark)
    }

    private static func swordRight(_ p: inout PixelPainter, x: Int, y: Int, length: Int, _ c: NinjaColors) {
        p.fillRect(x - 2, y - 1, x - 2, y + 3, c.beltDark)
        p.fillRect(x, y, x + length, y + 1, c.steel)
        p.fillRect(x, y + 2, x + length - 1, y + 2, c.steelDark)
    }

    static func smallNinja(_ c: NinjaColors, _ pose: NinjaPose) -> PixelSprite {
        var p = PixelPainter(width: 32, height: 32)
        let ox = (pose == .sword2 || pose == .sword3) ? -5 : 0
        func r(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ col: PixelColor) { p.fillRect(x0 + ox, y0, x1 + ox, y1, col) }

        switch pose {
        case .walk1:
            r(6, 25, 10, 29, c.gi); r(19, 25, 23, 29, c.gi)
            r(5, 29, 11, 31, c.boot); r(18, 29, 24, 31, c.boot)
        case .walk2:
            r(12, 25, 19, 29, c.gi); r(11, 29, 20, 31, c.boot)
        case .jump:
            r(8, 24, 12, 27, c.gi); r(19, 24, 23, 27, c.gi)
            r(7, 27, 13, 29, c.boot); r(18, 27, 24, 29, c.boot)
        default:
            r(10, 25, 14, 29, c.gi); r(18, 25, 22, 29, c.gi)
            r(9, 29, 15, 31, c.boot); r(17, 29, 23, 31, c.boot)
        }

        r(9, 17, 23, 25, c.gi); r(13, 18, 17, 24, c.giLight)
        r(9, 22, 23, 23, c.belt); r(14, 22, 17, 23, c.beltDark)

        switch pose {
        case .jump, .dead:
            r(5, 11, 7, 18, c.gi); r(5, 9, 7, 10, c.skin)
            r(25, 11, 27, 18, c.gi); r(25, 9, 27, 10, c.skin)
        case .sword1:
            r(6, 18, 8, 23, c.gi); r(6, 24, 8, 25, c.skin)
            r(24, 9, 26, 17, c.gi); r(24, 7, 26, 8, c.skin)
            swordUp(&p, x: 24 + ox, top: 0, hand: 7, c)
        case .sword2:
            r(6, 18, 8, 23, c.gi); r(6, 24, 8, 25, c.skin)
            r(23, 18, 27, 20, c.gi); r(28, 18, 29, 20, c.skin)
            swordRight(&p, x: 31 + ox, y: 18, length: 5, c)
        case .sword3:
            r(6, 18, 8, 23, c.gi); r(6, 24, 8, 25, c.skin)
            r(23, 21, 26, 24, c.gi); r(27, 23, 28, 25, c.skin)
            p.line(29 + ox, 26, 36 + ox, 31, c.steel, thickness: 2)
            p.line(28 + ox, 24, 30 + ox, 24, c.beltDark)
        case .sword4:
            r(6, 18, 8, 23, c.gi); r(6, 24, 8, 25, c.skin)
            r(24, 18, 26, 23, c.gi); r(24, 24, 26, 25, c.skin)
            r(25, 26, 26, 31, c.steel); r(27, 27, 27, 31, c.steelDark); r(24, 25, 27, 25, c.beltDark)
        default:
            r(6, 18, 8, 23, c.gi); r(6, 24, 8, 25, c.skin)
            r(24, 18, 26, 23, c.gi); r(24, 24, 26, 25, c.skin)
        }

        p.shadedEllipse(cx: 16 + Double(ox), cy: 10, rx: 9.5, ry: 8.5, c.gi)
        p.fillEllipse(cx: 17 + Double(ox), cy: 12, rx: 6.5, ry: 3.5, c.skin)
        eyes(&p, x: 12 + ox, y: 10, h: 3, c, dead: pose == .dead)
        band(&p, y0: 6, y1: 8, c)
        p.fillPolygon([(7 + Double(ox), 6), (1 + Double(ox), 3), (0 + Double(ox), 6), (3 + Double(ox), 9), (8 + Double(ox), 9)], c.bandana)
        p.fillPolygon([(7 + Double(ox), 8), (2 + Double(ox), 12), (5 + Double(ox), 13), (9 + Double(ox), 10)], c.bandana)

        p.outline(c.outline)
        p.bevel(outline: c.outline)
        return p.sprite(scale: 2)
    }

    static func bigNinja(_ c: NinjaColors, _ pose: NinjaPose) -> PixelSprite {
        var p = PixelPainter(width: 32, height: 64)
        let ox = (pose == .sword2 || pose == .sword3 || pose == .throwing) ? -4 : 0
        func r(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ col: PixelColor) { p.fillRect(x0 + ox, y0, x1 + ox, y1, col) }

        switch pose {
        case .walk1:
            r(5, 39, 11, 58, c.gi); r(20, 39, 26, 58, c.gi)
            r(4, 58, 12, 63, c.boot); r(19, 58, 27, 63, c.boot)
        case .walk2:
            r(11, 39, 21, 59, c.gi); r(10, 59, 22, 63, c.boot)
        case .jump:
            r(7, 39, 13, 51, c.gi); r(19, 39, 25, 51, c.gi)
            r(6, 51, 14, 55, c.boot); r(18, 51, 26, 55, c.boot)
        default:
            r(9, 39, 15, 59, c.gi); r(17, 39, 23, 59, c.gi)
            r(8, 59, 16, 63, c.boot); r(16, 59, 24, 63, c.boot)
        }

        r(7, 20, 25, 23, c.gi)
        r(9, 20, 23, 40, c.gi); r(13, 21, 17, 38, c.giLight)
        r(9, 33, 23, 35, c.belt); r(14, 33, 17, 35, c.beltDark)

        switch pose {
        case .jump:
            r(4, 9, 7, 24, c.gi); r(4, 6, 7, 8, c.skin)
            r(25, 9, 28, 24, c.gi); r(25, 6, 28, 8, c.skin)
        case .throwing:
            r(5, 22, 8, 36, c.gi); r(5, 37, 8, 39, c.skin)
            r(24, 24, 31, 27, c.gi); r(32, 24, 35, 27, c.skin)
        case .sword1:
            r(5, 22, 8, 36, c.gi); r(5, 37, 8, 39, c.skin)
            r(24, 10, 27, 24, c.gi); r(24, 7, 27, 9, c.skin)
            swordUp(&p, x: 25 + ox, top: 0, hand: 7, c)
        case .sword2:
            r(5, 22, 8, 36, c.gi); r(5, 37, 8, 39, c.skin)
            r(24, 24, 29, 27, c.gi); r(30, 24, 32, 27, c.skin)
            swordRight(&p, x: 35 + ox, y: 24, length: 6, c)
        case .sword3:
            r(5, 22, 8, 36, c.gi); r(5, 37, 8, 39, c.skin)
            r(24, 28, 28, 32, c.gi); r(29, 31, 31, 33, c.skin)
            p.line(32 + ox, 34, 40 + ox, 44, c.steel, thickness: 2)
            p.line(30 + ox, 33, 33 + ox, 32, c.beltDark)
        case .sword4:
            r(5, 22, 8, 36, c.gi); r(5, 37, 8, 39, c.skin)
            r(24, 22, 27, 36, c.gi); r(24, 37, 27, 39, c.skin)
            r(25, 40, 26, 58, c.steel); r(27, 41, 27, 58, c.steelDark); r(24, 39, 28, 39, c.beltDark)
        default:
            r(5, 22, 8, 36, c.gi); r(5, 37, 8, 39, c.skin)
            r(24, 22, 27, 36, c.gi); r(24, 37, 27, 39, c.skin)
        }

        p.shadedEllipse(cx: 16 + Double(ox), cy: 11, rx: 9.5, ry: 9, c.gi)
        p.fillEllipse(cx: 17 + Double(ox), cy: 13, rx: 6.5, ry: 4, c.skin)
        eyes(&p, x: 12 + ox, y: 11, h: 3, c, dead: pose == .dead)
        band(&p, y0: 6, y1: 8, c)
        p.fillPolygon([(7 + Double(ox), 6), (1 + Double(ox), 2), (0 + Double(ox), 6), (3 + Double(ox), 10), (8 + Double(ox), 9)], c.bandana)
        p.fillPolygon([(7 + Double(ox), 8), (1 + Double(ox), 13), (4 + Double(ox), 15), (9 + Double(ox), 11)], c.bandana)

        p.outline(c.outline)
        p.bevel(outline: c.outline)
        return p.sprite(scale: 2)
    }
}
