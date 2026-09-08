import SpriteKit

final class TouchControls: SKNode {
    private enum Zone {
        case left
        case right
        case jump
        case action
    }

    private var zones: [UITouch: Zone] = [:]
    private let leftButton = SKShapeNode(rectOf: CGSize(width: 40, height: 40), cornerRadius: 6)
    private let rightButton = SKShapeNode(rectOf: CGSize(width: 40, height: 40), cornerRadius: 6)
    private let jumpButton = SKShapeNode(circleOfRadius: 24)
    private let actionButton = SKShapeNode(circleOfRadius: 18)
    private var dpadSplitX: CGFloat = 0

    private(set) var input = InputState.none

    init(textures: TextureStore) {
        super.init()
        zPosition = 110
        for (button, icon) in [(leftButton, "ui.arrowLeft"), (rightButton, "ui.arrowRight"), (jumpButton, "ui.arrowUp"), (actionButton, "ui.star")] {
            button.fillColor = SKColor(white: 1, alpha: 0.22)
            button.strokeColor = SKColor(white: 1, alpha: 0.5)
            button.lineWidth = 1
            let sprite = textures.sprite(icon, anchor: CGPoint(x: 0.5, y: 0.5))
            sprite.alpha = 0.85
            button.addChild(sprite)
            addChild(button)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("not used")
    }

    func layout(sceneSize: CGSize, insets: SafeInsets) {
        let bottom = -sceneSize.height / 2 + CGFloat(insets.bottom) + 10
        let left = -sceneSize.width / 2 + CGFloat(insets.left) + 12
        let right = sceneSize.width / 2 - CGFloat(insets.right) - 12
        leftButton.position = CGPoint(x: left + 20, y: bottom + 20)
        rightButton.position = CGPoint(x: left + 68, y: bottom + 20)
        dpadSplitX = left + 44
        jumpButton.position = CGPoint(x: right - 24, y: bottom + 26)
        actionButton.position = CGPoint(x: right - 84, y: bottom + 18)
    }

    func touchesBegan(_ touches: Set<UITouch>) {
        for touch in touches {
            zones[touch] = zone(for: touch.location(in: self))
        }
        refresh()
    }

    func touchesMoved(_ touches: Set<UITouch>) {
        for touch in touches where zones[touch] != nil {
            zones[touch] = zone(for: touch.location(in: self))
        }
        refresh()
    }

    func touchesEnded(_ touches: Set<UITouch>) {
        for touch in touches {
            zones[touch] = nil
        }
        refresh()
    }

    func releaseAll() {
        zones.removeAll()
        refresh()
    }

    private func zone(for point: CGPoint) -> Zone {
        if point.x < 0 {
            return point.x < dpadSplitX ? .left : .right
        }
        let dx = point.x - actionButton.position.x
        let dy = point.y - actionButton.position.y
        return dx * dx + dy * dy < 32 * 32 ? .action : .jump
    }

    private func refresh() {
        let active = Set(zones.values.map { zoneIndex($0) })
        input = InputState(left: active.contains(0), right: active.contains(1), jump: active.contains(2), action: active.contains(3))
        leftButton.fillColor = SKColor(white: 1, alpha: input.left ? 0.5 : 0.22)
        rightButton.fillColor = SKColor(white: 1, alpha: input.right ? 0.5 : 0.22)
        jumpButton.fillColor = SKColor(white: 1, alpha: input.jump ? 0.5 : 0.22)
        actionButton.fillColor = SKColor(white: 1, alpha: input.action ? 0.5 : 0.22)
    }

    private func zoneIndex(_ zone: Zone) -> Int {
        switch zone {
        case .left: return 0
        case .right: return 1
        case .jump: return 2
        case .action: return 3
        }
    }
}
