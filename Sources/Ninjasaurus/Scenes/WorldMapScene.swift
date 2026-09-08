import SpriteKit

final class WorldMapScene: BaseScene {
    private struct MapNode {
        let index: Int
        let node: SKNode
        let unlocked: Bool
    }

    private var mapNodes: [MapNode] = []
    private var marker: SKSpriteNode!
    private var statusText: PixelTextNode!
    private var bestText: PixelTextNode!
    private var musicText: PixelTextNode!
    private var titleText: PixelTextNode!
    private var transitioning = false
    private let ground = SKNode()
    private var nodeSpots: [SKShapeNode] = []

    override func didMove(to view: SKView) {
        context.audio.playMusic(Music.title)
        let layers = BackgroundPainter.layers(for: .grass)
        let sky = SKSpriteNode(texture: layers.sky, size: size)
        sky.anchorPoint = .zero
        sky.zPosition = -100
        sky.name = "sky"
        addChild(sky)
        let far = SKSpriteNode(texture: layers.far, size: CGSize(width: layers.tileWidth, height: GameConstants.viewportHeight))
        far.anchorPoint = .zero
        far.zPosition = -90
        far.name = "far"
        addChild(far)
        addChild(ground)

        titleText = PixelTextNode("WORLD 1", textures: context.textures, color: .white, scale: 2, alignment: .center)
        addChild(titleText)
        statusText = PixelTextNode("", textures: context.textures, color: .white, alignment: .center)
        addChild(statusText)
        bestText = PixelTextNode("", textures: context.textures, color: SKColor(red: 1, green: 0.9, blue: 0.4, alpha: 1), alignment: .center)
        addChild(bestText)
        musicText = PixelTextNode(context.musicLabel, textures: context.textures, color: .white, alignment: .right)
        addChild(musicText)

        let unlocked = context.progress.unlockedLevelCount
        let icons = ["tile.grass.groundTop", "tile.cave.groundTop", "tile.cloud", "tile.hazard.lava1"]
        for index in 0..<LevelCatalog.count {
            let container = SKNode()
            let isUnlocked = index < unlocked
            let spot = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 5)
            spot.fillColor = isUnlocked ? SKColor(red: 0.85, green: 0.16, blue: 0.16, alpha: 1) : SKColor(white: 0.35, alpha: 1)
            spot.strokeColor = .white
            spot.lineWidth = 1
            container.addChild(spot)
            nodeSpots.append(spot)
            let icon = context.textures.sprite(isUnlocked ? icons[index] : "hud.lock", anchor: CGPoint(x: 0.5, y: 0.5))
            if !isUnlocked { icon.setScale(2) }
            container.addChild(icon)
            let label = PixelTextNode(LevelCatalog.ids[index], textures: context.textures, color: .white, alignment: .center)
            label.position = CGPoint(x: 0, y: -28)
            container.addChild(label)
            container.name = "level\(index)"
            addChild(container)
            mapNodes.append(MapNode(index: index, node: container, unlocked: isUnlocked))
        }
        marker = context.textures.sprite("ninja.small.idle", anchor: CGPoint(x: 0.5, y: 0))
        marker.zPosition = 10
        addChild(marker)
        marker.run(SKAction.repeatForever(SKAction.sequence([.moveBy(x: 0, y: 6, duration: 0.25), .moveBy(x: 0, y: -6, duration: 0.25)])))

        statusText.text = "LIVES x\(context.session.lives)   SCROLLS x\(context.session.coins)"
        bestText.text = "BEST \(String(format: "%06d", context.progress.bestScore))"
        layoutForSize()
    }

    override func layoutForSize() {
        guard marker != nil else { return }
        (childNode(withName: "sky") as? SKSpriteNode)?.size = size
        (childNode(withName: "far") as? SKSpriteNode)?.position = CGPoint(x: (size.width - 512) / 2, y: 0)
        titleText.position = CGPoint(x: size.width / 2, y: size.height - CGFloat(safeInsets.top) - 28)
        statusText.position = CGPoint(x: size.width / 2, y: size.height - CGFloat(safeInsets.top) - 44)
        bestText.position = CGPoint(x: size.width / 2, y: CGFloat(safeInsets.bottom) + 14)
        musicText.position = CGPoint(x: size.width - CGFloat(safeInsets.right) - 10, y: CGFloat(safeInsets.bottom) + 14)
        let usable = size.width - CGFloat(safeInsets.left + safeInsets.right) - 60
        let startX = CGFloat(safeInsets.left) + 30 + usable * 0.05
        let step = usable * 0.9 / CGFloat(max(1, LevelCatalog.count - 1))
        let y = size.height * 0.45
        for entry in mapNodes {
            entry.node.position = CGPoint(x: startX + step * CGFloat(entry.index), y: y)
        }
        ground.removeAllChildren()
        for index in 0..<(LevelCatalog.count - 1) {
            let from = mapNodes[index].node.position.x + 18
            let to = mapNodes[index + 1].node.position.x - 18
            var x = from
            while x < to {
                let dot = SKShapeNode(circleOfRadius: 2)
                dot.fillColor = SKColor(white: 1, alpha: 0.8)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: x, y: y)
                ground.addChild(dot)
                x += 10
            }
        }
        let current = min(context.session.levelIndex, mapNodes.count - 1)
        marker.position = CGPoint(x: mapNodes[current].node.position.x, y: y + 18)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !transitioning, let touch = touches.first else { return }
        let point = touch.location(in: self)
        let musicFrame = CGRect(x: musicText.position.x - musicText.width - 12, y: musicText.position.y - 12, width: musicText.width + 24, height: 32)
        if musicFrame.contains(point) {
            context.audio.play(.uiTap)
            context.toggleMusic()
            musicText.text = context.musicLabel
            return
        }
        for entry in mapNodes {
            let frame = CGRect(x: entry.node.position.x - 24, y: entry.node.position.y - 36, width: 48, height: 60)
            guard frame.contains(point) else { continue }
            guard entry.unlocked else {
                context.audio.play(.blockBump)
                return
            }
            context.audio.play(.uiTap)
            transitioning = true
            context.session.startLevel(at: entry.index)
            present(GameScene(context: context, levelIndex: entry.index))
            return
        }
    }
}
