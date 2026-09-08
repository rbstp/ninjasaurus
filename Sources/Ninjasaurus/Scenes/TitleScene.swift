import SpriteKit

final class TitleScene: BaseScene {
    private var title: PixelTextNode!
    private var shadow: PixelTextNode!
    private var subtitle: PixelTextNode!
    private var prompt: PixelTextNode!
    private var ninja: SKSpriteNode!
    private var enemy: SKSpriteNode?
    private var enemyIndex = 0
    private let enemyKinds = ["raptor", "anky", "stego", "ptero"]
    private var groundTiles: [SKSpriteNode] = []
    private var sky: SKSpriteNode!
    private var far: SKSpriteNode!
    private var transitioning = false

    override func didMove(to view: SKView) {
        context.audio.playMusic(Music.title)
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

        ninja = context.textures.sprite("ninja.big.idle@shuriken")
        ninja.setScale(1.5)
        ninja.zPosition = 5
        addChild(ninja)
        startHopping()
        spawnNextEnemy()
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
        ninja.position = CGPoint(x: centerX - 110, y: 32)
    }

    private func startHopping() {
        let up = SKAction.moveBy(x: 0, y: 36, duration: 0.32)
        up.timingMode = .easeOut
        let down = SKAction.moveBy(x: 0, y: -36, duration: 0.3)
        down.timingMode = .easeIn
        ninja.run(SKAction.repeatForever(SKAction.sequence([
            .wait(forDuration: 0.9),
            .setTexture(context.textures.texture("ninja.big.jump@shuriken")),
            up, down,
            .setTexture(context.textures.texture("ninja.big.idle@shuriken")),
        ])), withKey: "hop")
    }

    private func spawnNextEnemy() {
        let kind = enemyKinds[enemyIndex % enemyKinds.count]
        enemyIndex += 1
        let flying = kind == "ptero"
        let frames = flying ? ["ptero.fly1", "ptero.fly2"] : ["\(kind).walk1", "\(kind).walk2"]
        let node = context.textures.sprite(frames[0])
        node.setScale(1.5)
        node.xScale = -1.5
        node.zPosition = 4
        node.position = CGPoint(x: size.width + 30, y: flying ? 70 : 32)
        addChild(node)
        enemy = node
        node.run(SKAction.repeatForever(SKAction.animate(with: frames.map { context.textures.texture($0) }, timePerFrame: 0.16)), withKey: "walk")
        let stopX = ninja.position.x + 150
        let duration = TimeInterval((node.position.x - stopX) / 70)
        node.run(SKAction.sequence([
            .moveTo(x: stopX, duration: duration),
            .run { [weak self] in MainActor.assumeIsolated { self?.throwShuriken() } },
        ]))
    }

    private func throwShuriken() {
        guard let enemy else { return }
        ninja.removeAction(forKey: "hop")
        ninja.position.y = 32
        ninja.texture = context.textures.texture("ninja.big.throw@shuriken")
        ninja.run(SKAction.sequence([
            .wait(forDuration: 0.35),
            .setTexture(context.textures.texture("ninja.big.idle@shuriken")),
            .run { [weak self] in MainActor.assumeIsolated { self?.startHopping() } },
        ]))
        let shuriken = context.textures.sprite("shuriken1", anchor: CGPoint(x: 0.5, y: 0.5))
        shuriken.setScale(1.5)
        shuriken.zPosition = 6
        shuriken.position = CGPoint(x: ninja.position.x + 24, y: ninja.position.y + 30)
        addChild(shuriken)
        shuriken.run(SKAction.repeatForever(SKAction.animate(with: [context.textures.texture("shuriken1"), context.textures.texture("shuriken2")], timePerFrame: 0.05)))
        let target = CGPoint(x: enemy.position.x, y: enemy.position.y + 12)
        shuriken.run(SKAction.sequence([
            .move(to: target, duration: 0.3),
            .run { [weak self] in MainActor.assumeIsolated { self?.knockOut() } },
            .removeFromParent(),
        ]))
    }

    private func knockOut() {
        guard let enemy else { return }
        context.audio.play(.kick)
        enemy.removeAction(forKey: "walk")
        let puff = context.textures.sprite("fx.puff1", anchor: CGPoint(x: 0.5, y: 0.5))
        puff.setScale(1.5)
        puff.position = CGPoint(x: enemy.position.x, y: enemy.position.y + 12)
        puff.zPosition = 7
        addChild(puff)
        puff.run(SKAction.sequence([.animate(with: [context.textures.texture("fx.puff1"), context.textures.texture("fx.puff2")], timePerFrame: 0.1), .removeFromParent()]))
        let up = SKAction.group([.moveBy(x: 50, y: 70, duration: 0.3), .rotate(byAngle: .pi, duration: 0.3)])
        up.timingMode = .easeOut
        let down = SKAction.moveBy(x: 40, y: -220, duration: 0.5)
        down.timingMode = .easeIn
        enemy.run(SKAction.sequence([
            up, down, .removeFromParent(),
            .run { [weak self] in MainActor.assumeIsolated { self?.spawnNextEnemy() } },
        ]))
        self.enemy = nil
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
