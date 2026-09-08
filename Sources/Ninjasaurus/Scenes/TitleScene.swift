import SpriteKit

final class TitleScene: BaseScene {
    private var title: PixelTextNode!
    private var shadow: PixelTextNode!
    private var subtitle: PixelTextNode!
    private var prompt: PixelTextNode!
    private var ninja: SKSpriteNode!
    private var raptor: SKSpriteNode!
    private var groundTiles: [SKSpriteNode] = []
    private var sky: SKSpriteNode!
    private var far: SKSpriteNode!
    private var transitioning = false

    override func didMove(to view: SKView) {
        let layers = BackgroundPainter.layers(for: .grass)
        sky = SKSpriteNode(texture: layers.sky, size: size)
        sky.anchorPoint = .zero
        sky.zPosition = -100
        addChild(sky)
        far = SKSpriteNode(texture: layers.near, size: CGSize(width: layers.tileWidth, height: GameConstants.viewportHeight))
        far.anchorPoint = .zero
        far.zPosition = -90
        addChild(far)

        shadow = PixelTextNode("NINJASAURUS", textures: context.textures, color: SKColor(red: 0.45, green: 0.08, blue: 0.08, alpha: 1), scale: 3, alignment: .center)
        addChild(shadow)
        title = PixelTextNode("NINJASAURUS", textures: context.textures, color: SKColor(red: 0.95, green: 0.2, blue: 0.2, alpha: 1), scale: 3, alignment: .center)
        addChild(title)
        subtitle = PixelTextNode("NINJA VS DINOSAURS", textures: context.textures, color: .white, alignment: .center)
        addChild(subtitle)
        prompt = PixelTextNode("TAP TO START", textures: context.textures, color: .white, alignment: .center)
        prompt.run(SKAction.repeatForever(SKAction.sequence([.fadeOut(withDuration: 0.5), .fadeIn(withDuration: 0.5)])))
        addChild(prompt)

        ninja = context.textures.sprite("ninja.big.idle")
        ninja.setScale(1.5)
        ninja.zPosition = 5
        addChild(ninja)
        ninja.run(SKAction.repeatForever(SKAction.sequence([
            .wait(forDuration: 1.2),
            .setTexture(context.textures.texture("ninja.big.jump")),
            .moveBy(x: 0, y: 40, duration: 0.35),
            .moveBy(x: 0, y: -40, duration: 0.3),
            .setTexture(context.textures.texture("ninja.big.idle")),
        ])))
        raptor = context.textures.sprite("raptor.walk1")
        raptor.setScale(1.5)
        raptor.zPosition = 4
        raptor.xScale = -1.5
        addChild(raptor)
        raptor.run(SKAction.repeatForever(SKAction.animate(with: [context.textures.texture("raptor.walk1"), context.textures.texture("raptor.walk2")], timePerFrame: 0.18)))
        layoutForSize()
    }

    override func layoutForSize() {
        guard title != nil else { return }
        sky.size = size
        far.position = CGPoint(x: (size.width - 512) / 2, y: 0)
        let centerX = size.width / 2
        shadow.position = CGPoint(x: centerX + 2, y: size.height * 0.74 - 2)
        title.position = CGPoint(x: centerX, y: size.height * 0.74)
        subtitle.position = CGPoint(x: centerX, y: size.height * 0.74 - 16)
        prompt.position = CGPoint(x: centerX, y: size.height * 0.5)
        groundTiles.forEach { $0.removeFromParent() }
        groundTiles.removeAll()
        var x: CGFloat = 0
        while x < size.width {
            for (row, name) in ["tile.grass.fill", "tile.grass.groundTop"].enumerated() {
                let tile = context.textures.sprite(name, anchor: .zero)
                tile.position = CGPoint(x: x, y: CGFloat(row) * 16)
                addChild(tile)
                groundTiles.append(tile)
            }
            x += 16
        }
        ninja.position = CGPoint(x: centerX - 90, y: 32)
        raptor.position = CGPoint(x: centerX + 90, y: 32)
        raptor.removeAction(forKey: "walk")
        raptor.run(SKAction.repeatForever(SKAction.sequence([
            .moveBy(x: -40, y: 0, duration: 2),
            .scaleX(to: 1.5, duration: 0),
            .moveBy(x: 40, y: 0, duration: 2),
            .scaleX(to: -1.5, duration: 0),
        ])), withKey: "walk")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !transitioning else { return }
        transitioning = true
        context.audio.play(.uiTap)
        context.session.resetForNewRun()
        context.session.levelIndex = context.progress.unlockedLevelCount - 1
        present(WorldMapScene(context: context))
    }
}
