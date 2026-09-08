import SpriteKit

enum PixelFont {
    static let glyphWidth = 6
    static let glyphHeight = 8
    static let advance = 7
    private static let outlineColor = PixelColor(0x202030)

    private static let ink: Palette = ["#": .white]

    static let glyphs: [Character: [String]] = [
        "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
        "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
        "C": [".####", "#....", "#....", "#....", "#....", "#....", ".####"],
        "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
        "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
        "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
        "G": [".####", "#....", "#....", "#.###", "#...#", "#...#", ".####"],
        "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
        "I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
        "J": ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
        "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
        "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
        "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
        "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
        "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
        "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
        "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
        "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
        "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
        "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
        "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
        "V": ["#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
        "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
        "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
        "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
        "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
        "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
        "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
        "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
        "3": ["#####", "...#.", "..#..", "...#.", "....#", "#...#", ".###."],
        "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
        "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
        "6": ["..###", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
        "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
        "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
        "9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", "###.."],
        "!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
        "?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
        ":": [".....", "..#..", "..#..", ".....", "..#..", "..#..", "....."],
        ".": [".....", ".....", ".....", ".....", ".....", ".....", "..#.."],
        ",": [".....", ".....", ".....", ".....", ".....", "..#..", ".#..."],
        "-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
        "x": [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
        "/": ["....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."],
        "'": ["..#..", "..#..", ".....", ".....", ".....", ".....", "....."],
        ">": ["#....", ".#...", "..#..", "...#.", "..#..", ".#...", "#...."],
        "<": ["...#.", "..#..", ".#...", "#....", ".#...", "..#..", "...#."],
        "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
    ]

    static func spriteName(for character: Character) -> String? {
        let upper = character == "x" ? character : Character(character.uppercased())
        guard glyphs[upper] != nil else { return nil }
        return "font.\(upper.unicodeScalars.first!.value)"
    }

    static let sprites: [String: PixelSprite] = {
        var out: [String: PixelSprite] = [:]
        for (char, rows) in glyphs {
            let small = PixelSprite(palette: ink, rows: rows)
            var painter = PixelPainter(width: small.width, height: small.height)
            for y in 0..<small.height {
                for x in 0..<small.width {
                    painter[x, y] = small.pixel(x: x, y: y)
                }
            }
            let big = painter.scaled2x()
            var framed = PixelPainter(width: glyphWidth * 2, height: glyphHeight * 2)
            for y in 0..<big.height {
                for x in 0..<big.width {
                    framed[x + 1, y + 1] = big[x, y]
                }
            }
            framed.outlineOutward(outlineColor)
            out[spriteName(for: char)!] = framed.sprite(scale: 2)
        }
        return out
    }()
}

final class PixelTextNode: SKNode {
    enum Alignment {
        case left
        case center
        case right
    }

    private let textures: TextureStore
    private var glyphNodes: [SKSpriteNode] = []

    var text: String {
        didSet { if text != oldValue { rebuild() } }
    }

    var color: SKColor {
        didSet { glyphNodes.forEach { $0.color = color } }
    }

    var textScale: CGFloat {
        didSet { rebuild() }
    }

    var alignment: Alignment {
        didSet { rebuild() }
    }

    init(_ text: String, textures: TextureStore, color: SKColor = .white, scale: CGFloat = 1, alignment: Alignment = .left) {
        self.textures = textures
        self.text = text
        self.color = color
        self.textScale = scale
        self.alignment = alignment
        super.init()
        rebuild()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("not used")
    }

    var width: CGFloat {
        CGFloat(max(0, text.count * PixelFont.advance - 1)) * textScale
    }

    var height: CGFloat {
        CGFloat(PixelFont.glyphHeight) * textScale
    }

    private func rebuild() {
        glyphNodes.forEach { $0.removeFromParent() }
        glyphNodes.removeAll()
        let total = width
        let startX: CGFloat
        switch alignment {
        case .left: startX = 0
        case .center: startX = -total / 2
        case .right: startX = -total
        }
        var x = startX
        let step = CGFloat(PixelFont.advance) * textScale
        for character in text {
            defer { x += step }
            guard character != " ", let name = PixelFont.spriteName(for: character) else { continue }
            let node = SKSpriteNode(texture: textures.texture(name))
            node.size = CGSize(width: CGFloat(PixelFont.glyphWidth) * textScale, height: CGFloat(PixelFont.glyphHeight) * textScale)
            node.anchorPoint = CGPoint(x: 0, y: 0)
            node.position = CGPoint(x: x, y: 0)
            node.color = color
            node.colorBlendFactor = 1
            addChild(node)
            glyphNodes.append(node)
        }
    }
}
