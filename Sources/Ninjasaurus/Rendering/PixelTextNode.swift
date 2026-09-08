import SpriteKit

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
