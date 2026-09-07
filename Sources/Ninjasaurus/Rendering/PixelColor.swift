struct PixelColor: Hashable, Sendable {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8

    static let clear = PixelColor(r: 0, g: 0, b: 0, a: 0)
    static let white = PixelColor(0xFFFFFF)
    static let black = PixelColor(0x000000)

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(_ rgb: UInt32) {
        r = UInt8((rgb >> 16) & 0xFF)
        g = UInt8((rgb >> 8) & 0xFF)
        b = UInt8(rgb & 0xFF)
        a = 255
    }

    var isTransparent: Bool { a == 0 }
}

typealias Palette = [Character: PixelColor]

enum Colors {
    // NES-flavoured shared palette.
    static let outline = PixelColor(0x181820)
    static let shade = PixelColor(0x3C3C48)
    static let red = PixelColor(0xD82828)
    static let darkRed = PixelColor(0x901818)
    static let skin = PixelColor(0xFCBC8C)
    static let eyeWhite = PixelColor(0xFFFFFF)
    static let pupil = PixelColor(0x000000)
    static let gold = PixelColor(0xF8C838)
    static let darkGold = PixelColor(0xB88018)
    static let paleGold = PixelColor(0xFCE8A0)
    static let orange = PixelColor(0xF08028)
    static let yellow = PixelColor(0xF8E048)
    static let leaf = PixelColor(0x38A848)
    static let darkLeaf = PixelColor(0x186828)
    static let paleLeaf = PixelColor(0xA8E078)
    static let brown = PixelColor(0xA86828)
    static let darkBrown = PixelColor(0x683810)
    static let tan = PixelColor(0xD8A858)
    static let sand = PixelColor(0xF0E0A0)
    static let purple = PixelColor(0x9858C8)
    static let darkPurple = PixelColor(0x582888)
    static let stone = PixelColor(0x8890A0)
    static let darkStone = PixelColor(0x505868)
    static let paleStone = PixelColor(0xC0C8D8)
    static let caveBlue = PixelColor(0x304060)
    static let deepCave = PixelColor(0x182038)
    static let crystal = PixelColor(0x80E0F8)
    static let sky = PixelColor(0x5CBCFC)
    static let cloudShade = PixelColor(0xB8E0F8)
    static let lava = PixelColor(0xF85818)
    static let lavaBright = PixelColor(0xFCC030)
    static let magenta = PixelColor(0xFF00FF)
}
