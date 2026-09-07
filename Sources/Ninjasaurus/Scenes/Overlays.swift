import SpriteKit

final class OverlayNode: SKNode {
    enum Action: Equatable {
        case resume
        case quit
        case none
    }

    private var buttons: [(node: SKShapeNode, action: Action)] = []
    let dim: SKSpriteNode
    private let title: PixelTextNode
    private let subtitle: PixelTextNode?

    init(textures: TextureStore, sceneSize: CGSize, title titleText: String, subtitle subtitleText: String? = nil,
         buttons buttonSpecs: [(String, Action)] = [], dimAlpha: CGFloat = 0.55, titleColor: SKColor = .white) {
        dim = SKSpriteNode(color: SKColor(white: 0, alpha: dimAlpha), size: CGSize(width: sceneSize.width * 2, height: sceneSize.height * 2))
        title = PixelTextNode(titleText, textures: textures, color: titleColor, scale: 2, alignment: .center)
        subtitle = subtitleText.map { PixelTextNode($0, textures: textures, color: .white, scale: 1, alignment: .center) }
        super.init()
        zPosition = 200
        addChild(dim)
        addChild(title)
        if let subtitle { addChild(subtitle) }
        for (label, action) in buttonSpecs {
            let button = SKShapeNode(rectOf: CGSize(width: 96, height: 28), cornerRadius: 6)
            button.fillColor = SKColor(red: 0.85, green: 0.16, blue: 0.16, alpha: 1)
            button.strokeColor = .white
            button.lineWidth = 1
            let text = PixelTextNode(label, textures: textures, color: .white, scale: 1, alignment: .center)
            text.position = CGPoint(x: 0, y: -3.5)
            button.addChild(text)
            addChild(button)
            buttons.append((button, action))
        }
        layout()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("not used")
    }

    private func layout() {
        title.position = CGPoint(x: 0, y: buttons.isEmpty ? 4 : 30)
        subtitle?.position = CGPoint(x: 0, y: title.position.y - 16)
        let spacing: CGFloat = 112
        let startX = -spacing * CGFloat(buttons.count - 1) / 2
        for (index, button) in buttons.enumerated() {
            button.node.position = CGPoint(x: startX + spacing * CGFloat(index), y: -24)
        }
    }

    func action(at point: CGPoint) -> Action {
        for button in buttons {
            let frame = button.node.frame.insetBy(dx: -10, dy: -10)
            if frame.contains(point) { return button.action }
        }
        return .none
    }
}
