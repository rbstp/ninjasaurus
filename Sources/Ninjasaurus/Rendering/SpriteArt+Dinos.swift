/// Dinosaurs, drawn facing right at 2 pixels per unit.
extension SpriteArt {
    private static let ink = PixelColor(0x101018)
    private static let eyeWhite = PixelColor.white
    private static let claw = Colors.sand

    static let dinos: [String: PixelSprite] = {
        var out: [String: PixelSprite] = [:]
        out["raptor.walk1"] = raptor(.walk1)
        out["raptor.walk2"] = raptor(.walk2)
        out["raptor.squished"] = raptor(.squished)
        out["anky.walk1"] = anky(legs: 0)
        out["anky.walk2"] = anky(legs: 1)
        out["anky.ball1"] = ankyBall(shift: 0)
        out["anky.ball2"] = ankyBall(shift: 3)
        out["ptero.fly1"] = ptero(.fly1)
        out["ptero.fly2"] = ptero(.fly2)
        out["ptero.walk1"] = ptero(.walk1)
        out["ptero.walk2"] = ptero(.walk2)
        out["stego.walk1"] = stego(legs: 0)
        out["stego.walk2"] = stego(legs: 1)
        for pose in RexPose.allCases {
            let sprite = rex(pose)
            out["rex.\(pose.rawValue)"] = sprite
            out["rex.\(pose.rawValue)@flash"] = sprite.flashedWhite()
        }
        out["fireball.1"] = fireball(0)
        out["fireball.2"] = fireball(1)
        return out
    }()

    static let dinoScale = 1.6

    private static func finish(_ p: inout PixelPainter) -> PixelSprite {
        p.outline(ink)
        p.bevel(outline: ink)
        return p.sprite(scale: dinoScale)
    }

    private static func eye(_ p: inout PixelPainter, _ x: Int, _ y: Int, _ size: Int = 2, iris: PixelColor = .white) {
        p.fillRect(x, y, x + size, y + size, iris)
        p.fillRect(x + size - 1, y + 1, x + size, y + size, ink)
    }

    // MARK: Raptor

    enum RaptorPose { case walk1, walk2, squished }

    static func raptor(_ pose: RaptorPose) -> PixelSprite {
        let green = PixelColor(0x48B858), belly = PixelColor(0xB8E890), tongue = Colors.red
        var p = PixelPainter(width: 32, height: 32)
        if pose == .squished {
            p.fillPolygon([(8, 27), (0, 24), (1, 28), (9, 30)], green)
            p.shadedEllipse(cx: 15, cy: 27, rx: 11, ry: 4, green)
            p.shadedEllipse(cx: 26, cy: 26, rx: 5.5, ry: 3.5, green)
            eye(&p, 27, 24, 1)
            p.fillRect(9, 30, 13, 31, claw); p.fillRect(17, 30, 21, 31, claw)
            return finish(&p)
        }
        p.fillPolygon([(9, 15), (0, 6), (1, 11), (10, 21)], green)
        p.shadedEllipse(cx: 14, cy: 19, rx: 8.5, ry: 6.5, green)
        p.fillEllipse(cx: 15, cy: 21.5, rx: 5, ry: 3, belly)
        p.fillPolygon([(18, 16), (22, 8), (26, 10), (22, 18)], green)
        p.shadedEllipse(cx: 24, cy: 10, rx: 6.5, ry: 5.5, green)
        p.fillPolygon([(27, 8), (31.5, 10.5), (31.5, 14), (26, 15)], green)
        p.fillRect(27, 13, 31, 13, ink)
        p.fillRect(28, 12, 28, 12, eyeWhite); p.fillRect(30, 12, 30, 12, eyeWhite)
        p.fillRect(29, 14, 30, 14, tongue)
        eye(&p, 24, 7)
        p.fillRect(19, 20, 22, 22, green); p.fillRect(22, 22, 23, 23, claw)
        switch pose {
        case .walk1:
            p.fillRect(9, 24, 12, 29, green); p.fillRect(17, 24, 20, 29, green)
            p.fillRect(8, 29, 13, 31, claw); p.fillRect(16, 29, 21, 31, claw)
        default:
            p.fillRect(12, 24, 14, 29, green); p.fillRect(16, 24, 18, 29, green)
            p.fillRect(11, 29, 15, 31, claw); p.fillRect(15, 29, 19, 31, claw)
        }
        return finish(&p)
    }

    // MARK: Anky

    static func anky(legs: Int) -> PixelSprite {
        let shell = PixelColor(0xD8A858), shellDark = PixelColor(0x9C6C28), body = PixelColor(0xA86828), spike = Colors.sand
        var p = PixelPainter(width: 32, height: 32)
        p.fillPolygon([(8, 22), (0, 18), (1, 24), (9, 27)], body)
        p.fillRect(7, 21, 25, 27, body)
        p.shadedEllipse(cx: 27, cy: 22, rx: 4.5, ry: 3.5, body)
        eye(&p, 27, 20, 1)
        p.shadedEllipse(cx: 15, cy: 16, rx: 11, ry: 8, shell)
        for (x, y) in [(10, 17), (16, 14), (21, 18), (12, 12), (19, 11)] {
            p.fillEllipse(cx: Double(x), cy: Double(y), rx: 1.6, ry: 1.3, shellDark)
        }
        for x in [6.0, 11.0, 16.0, 21.0] {
            let top = 9.0 + (x - 14) * (x - 14) / 30
            p.fillPolygon([(x - 2.2, top + 4), (x, top - 2), (x + 2.2, top + 4)], spike)
        }
        let dx = legs == 0 ? 0 : 2
        p.fillRect(8 + dx, 26, 11 + dx, 30, body); p.fillRect(19 - dx, 26, 22 - dx, 30, body)
        p.fillRect(7 + dx, 30, 12 + dx, 31, claw); p.fillRect(18 - dx, 30, 23 - dx, 31, claw)
        return finish(&p)
    }

    static func ankyBall(shift: Int) -> PixelSprite {
        let shell = PixelColor(0xD8A858), shellDark = PixelColor(0x9C6C28), spike = Colors.sand
        var p = PixelPainter(width: 32, height: 32)
        p.shadedEllipse(cx: 16, cy: 20, rx: 11, ry: 9.5, shell)
        for (x, y) in [(11, 21), (17, 17), (22, 22), (13, 15), (20, 13), (16, 25)] {
            p.fillEllipse(cx: Double(x), cy: Double(y), rx: 1.6, ry: 1.3, shellDark)
        }
        for x in [5.0, 10.0, 15.0, 20.0, 25.0] {
            let sx = x + Double(shift)
            guard sx < 29 else { continue }
            let top = 11.5 + (sx - 16) * (sx - 16) / 14
            p.fillPolygon([(sx - 2, top + 4), (sx, top - 2), (sx + 2, top + 4)], spike)
        }
        return finish(&p)
    }

    // MARK: Ptero

    enum PteroPose { case fly1, fly2, walk1, walk2 }

    static func ptero(_ pose: PteroPose) -> PixelSprite {
        let purple = PixelColor(0xA060D0), belly = PixelColor(0xD8B0F0), beak = Colors.orange
        var p = PixelPainter(width: 32, height: 32)
        switch pose {
        case .fly1:
            p.fillPolygon([(12, 17), (1, 3), (4, 1), (15, 13)], purple)
            p.fillPolygon([(18, 17), (28, 3), (31, 5), (20, 13)], purple)
        case .fly2:
            p.fillPolygon([(12, 16), (1, 27), (4, 29), (15, 19)], purple)
            p.fillPolygon([(18, 16), (28, 26), (31, 24), (20, 19)], purple)
        default:
            p.fillPolygon([(10, 18), (2, 13), (3, 19), (13, 22)], purple)
        }
        let cy = pose == .fly1 || pose == .fly2 ? 18.0 : 21.0
        p.shadedEllipse(cx: 16, cy: cy, rx: 6.5, ry: 4.5, purple)
        p.fillEllipse(cx: 16, cy: cy + 1.5, rx: 3.5, ry: 2, belly)
        p.fillPolygon([(19, cy - 6), (14, cy - 10), (21, cy - 4)], purple)
        p.shadedEllipse(cx: 22, cy: cy - 5, rx: 4.5, ry: 3.5, purple)
        p.fillPolygon([(25, cy - 6), (31.5, cy - 4), (25, cy - 2)], beak)
        eye(&p, 22, Int(cy) - 7, 1)
        if pose == .walk1 || pose == .walk2 {
            let dx = pose == .walk1 ? 0 : 2
            p.fillRect(12 + dx, 25, 13 + dx, 30, purple); p.fillRect(18 - dx, 25, 19 - dx, 30, purple)
            p.fillRect(11 + dx, 30, 14 + dx, 31, claw); p.fillRect(17 - dx, 30, 20 - dx, 31, claw)
        } else {
            p.fillRect(13, 22, 14, 25, purple); p.fillRect(18, 22, 19, 25, purple)
        }
        return finish(&p)
    }

    // MARK: Stego

    static func stego(legs: Int) -> PixelSprite {
        let orange = PixelColor(0xF09030), belly = PixelColor(0xF8D8A0), plate = PixelColor(0xE03030), plateInner = Colors.yellow
        var p = PixelPainter(width: 32, height: 32)
        p.fillPolygon([(7, 18), (0, 13), (1, 18), (8, 23)], orange)
        p.fillPolygon([(2, 13), (3, 9), (4, 13)], claw); p.fillPolygon([(4, 12), (6, 8), (7, 13)], claw)
        for x in [6.0, 11.0, 16.0, 21.0] {
            p.fillPolygon([(x - 3, 15), (x, 6), (x + 3, 15)], plate)
            p.fillPolygon([(x - 1.4, 14), (x, 9.5), (x + 1.4, 14)], plateInner)
        }
        p.shadedEllipse(cx: 15, cy: 20, rx: 10, ry: 6.5, orange)
        p.fillEllipse(cx: 15, cy: 23, rx: 6, ry: 3, belly)
        p.shadedEllipse(cx: 26, cy: 21, rx: 4.5, ry: 3.5, orange)
        eye(&p, 26, 19, 1)
        let dx = legs == 0 ? 0 : 2
        p.fillRect(8 + dx, 25, 11 + dx, 30, orange); p.fillRect(19 - dx, 25, 22 - dx, 30, orange)
        p.fillRect(7 + dx, 30, 12 + dx, 31, claw); p.fillRect(18 - dx, 30, 23 - dx, 31, claw)
        return finish(&p)
    }

    // MARK: Rex

    enum RexPose: String, CaseIterable { case idle, walk1, walk2, leap, stun, roar }

    static func rex(_ pose: RexPose) -> PixelSprite {
        let hide = PixelColor(0x5C7C40), hideDark = PixelColor(0x3C5430), belly = PixelColor(0xC4BC98), ridge = PixelColor(0x2C4024)
        let mouth = PixelColor(0x6C1420), tooth = PixelColor(0xF4F0E0), eyeYellow = PixelColor(0xF8D040), fire = Colors.orange
        var p = PixelPainter(width: 64, height: 64)
        let open = pose == .roar ? 5.0 : 0

        p.fillPolygon([(18, 30), (0, 24), (0, 29), (20, 44)], hide)
        p.fillPolygon([(4, 28), (0, 26), (0, 28), (6, 32)], hideDark)
        p.shadedEllipse(cx: 22, cy: 39, rx: 11, ry: 10, hide)
        p.shadedEllipse(cx: 34, cy: 33, rx: 12, ry: 9.5, hide)
        p.fillEllipse(cx: 31, cy: 38, rx: 9, ry: 5, belly)
        for x in stride(from: 8.0, through: 38.0, by: 5) {
            let y = 30 - (x - 8) * 0.28
            p.fillPolygon([(x - 1.5, y + 2), (x, y - 2.5), (x + 1.5, y + 2)], ridge)
        }
        p.fillPolygon([(40, 24), (46, 14), (56, 20), (46, 36)], hide)
        p.shadedEllipse(cx: 50, cy: 15, rx: 12.5, ry: 8, hide)
        p.fillPolygon([(52, 8), (63.5, 12), (63.5, 19), (48, 21)], hide)
        p.fillPolygon([(42, 10), (50, 6), (56, 9), (52, 12), (44, 13)], hideDark)
        p.fillPolygon([(46, 20), (63.5, 19), (63.5, 24 + open), (46, 25 + open)], mouth)
        p.fillPolygon([(46, 24 + open), (63.5, 24 + open), (62, 30 + open), (48, 30 + open), (44, 27 + open)], hide)
        for x in [49.0, 53.0, 57.0, 61.0] {
            p.fillPolygon([(x, 19), (x + 3, 19), (x + 1.5, 23)], tooth)
            p.fillPolygon([(x + 0.5, 25 + open), (x + 3.5, 25 + open), (x + 2, 21.5 + open)], tooth)
        }
        if pose == .roar {
            p.fillEllipse(cx: 61, cy: 23, rx: 3, ry: 2.5, fire)
        }
        if pose == .stun {
            p.fillRect(48, 12, 53, 16, eyeYellow)
            p.line(48, 12, 53, 16, ink); p.line(53, 12, 48, 16, ink)
            for (x, y) in [(34.0, 4.0), (48.0, 1.0), (60.0, 3.0)] {
                p.fillPolygon([(x, y - 3), (x + 1, y - 1), (x + 3, y), (x + 1, y + 1), (x, y + 3), (x - 1, y + 1), (x - 3, y), (x - 1, y - 1)], eyeYellow)
            }
        } else {
            p.fillRect(48, 12, 53, 15, eyeYellow); p.fillRect(51, 12, 52, 15, ink)
            p.fillRect(46, 11, 54, 11, ridge)
        }
        p.fillRect(40, 36, 43, 41, hide); p.fillRect(43, 40, 45, 41, claw); p.fillRect(43, 38, 45, 38, claw)
        switch pose {
        case .walk1:
            p.fillEllipse(cx: 18, cy: 46, rx: 7, ry: 7, hideDark); p.fillRect(12, 50, 18, 60, hideDark)
            p.fillEllipse(cx: 28, cy: 46, rx: 7, ry: 7, hide); p.fillRect(28, 50, 34, 60, hide)
            p.fillRect(9, 60, 22, 63, hideDark); p.fillRect(26, 60, 39, 63, hide)
            for x in [10, 15, 20] { p.fillRect(x, 62, x + 1, 63, claw) }
            for x in [27, 32, 37] { p.fillRect(x, 62, x + 1, 63, claw) }
        case .walk2:
            p.fillEllipse(cx: 24, cy: 46, rx: 7, ry: 7, hideDark); p.fillRect(21, 50, 27, 60, hideDark)
            p.fillEllipse(cx: 26, cy: 46, rx: 7, ry: 7, hide); p.fillRect(24, 50, 30, 60, hide)
            p.fillRect(19, 60, 35, 63, hide)
            for x in [20, 26, 32] { p.fillRect(x, 62, x + 1, 63, claw) }
        case .leap:
            p.fillEllipse(cx: 20, cy: 47, rx: 7, ry: 7, hideDark); p.fillPolygon([(14, 50), (22, 52), (28, 58), (20, 60)], hideDark)
            p.fillEllipse(cx: 28, cy: 46, rx: 7, ry: 7, hide); p.fillPolygon([(24, 50), (32, 51), (38, 57), (30, 59)], hide)
            p.fillRect(18, 58, 30, 61, hideDark); p.fillRect(28, 57, 40, 60, hide)
        default:
            p.fillEllipse(cx: 20, cy: 46, rx: 7, ry: 7, hideDark); p.fillRect(15, 50, 21, 60, hideDark)
            p.fillEllipse(cx: 28, cy: 46, rx: 7, ry: 7, hide); p.fillRect(26, 50, 32, 60, hide)
            p.fillRect(12, 60, 25, 63, hideDark); p.fillRect(24, 60, 37, 63, hide)
            for x in [13, 18, 23] { p.fillRect(x, 62, x + 1, 63, claw) }
            for x in [25, 30, 35] { p.fillRect(x, 62, x + 1, 63, claw) }
        }
        return finish(&p)
    }

    static func fireball(_ frame: Int) -> PixelSprite {
        var p = PixelPainter(width: 32, height: 16)
        let f = Double(frame)
        p.fillPolygon([(14, 8), (0, 3 + f), (5, 8), (0, 13 - f)], Colors.red)
        p.fillPolygon([(16, 8), (4, 5 + f), (8, 8), (4, 11 - f)], Colors.orange)
        p.shadedEllipse(cx: 19 + f, cy: 8, rx: 11, ry: 6.5, Colors.orange)
        p.fillEllipse(cx: 21 + f, cy: 8, rx: 7, ry: 4.5, Colors.lavaBright)
        p.fillEllipse(cx: 23 + f, cy: 8, rx: 3.5, ry: 2.5, PixelColor(0xFFF8D0))
        p.outline(PixelColor(0x802010))
        return p.sprite(scale: 2)
    }
}
