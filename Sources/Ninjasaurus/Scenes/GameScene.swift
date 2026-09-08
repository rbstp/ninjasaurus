import SpriteKit

final class GameScene: BaseScene {
    private enum Outcome {
        case none
        case levelClear(framesLeft: Int)
        case worldClear(framesLeft: Int)
        case gameOver(framesLeft: Int)
        case respawn(framesLeft: Int)
    }

    private let levelIndex: Int
    private let level: LevelDefinition
    private var world: GameWorld
    private var clock = FixedStepClock()

    private let worldNode = SKNode()
    private let cameraNode = SKCameraNode()
    private var tileLayer: TileLayer!
    private var entitySync: EntityNodeSync!
    private var effects: Effects!
    private var hud: HUDNode!
    private var controls: TouchControls!
    private let gamepad = GamepadInput()
    private var goalNode: SKSpriteNode!
    private var background: BackgroundPainter.Layers!
    private var skyNode: SKSpriteNode!
    private var farNodes: [SKSpriteNode] = []
    private var nearNodes: [SKSpriteNode] = []
    private var banner: PixelTextNode?

    private var overlay: OverlayNode?
    private var isPausedByUser = false
    private var outcome = Outcome.none
    private var shakeFrames = 0
    private var rng = SeededRandom(seed: 7)
    private var transitioning = false

    init(context: GameContext, levelIndex: Int) {
        self.levelIndex = levelIndex
        do {
            level = try LevelCatalog.load(index: levelIndex)
        } catch {
            fatalError("level \(levelIndex) failed to load: \(error)")
        }
        world = GameWorld(level: level, startAt: context.session.checkpoint)
        super.init(context: context)
    }

    override func didMove(to view: SKView) {
        context.audio.playMusic(Music.song(for: level.theme))
        backgroundColor = .black
        addChild(worldNode)
        camera = cameraNode
        addChild(cameraNode)

        background = BackgroundPainter.layers(for: level.theme)
        skyNode = SKSpriteNode(texture: background.sky)
        skyNode.zPosition = -100
        cameraNode.addChild(skyNode)
        for _ in 0..<3 {
            let far = SKSpriteNode(texture: background.far, size: CGSize(width: background.tileWidth, height: GameConstants.viewportHeight))
            far.anchorPoint = .zero
            far.zPosition = -90
            cameraNode.addChild(far)
            farNodes.append(far)
            let near = SKSpriteNode(texture: background.near, size: CGSize(width: background.tileWidth, height: GameConstants.viewportHeight))
            near.anchorPoint = .zero
            near.zPosition = -80
            cameraNode.addChild(near)
            nearNodes.append(near)
        }

        tileLayer = TileLayer(textures: context.textures, parent: worldNode, theme: level.theme)
        entitySync = EntityNodeSync(textures: context.textures, parent: worldNode)
        effects = Effects(textures: context.textures, parent: worldNode)
        goalNode = context.textures.sprite(world.goalActive ? "prop.torii" : "prop.toriiDark", anchor: .zero)
        goalNode.position = CGPoint(x: level.goal.minX, y: level.goal.minY)
        goalNode.zPosition = -1
        worldNode.addChild(goalNode)

        hud = HUDNode(textures: context.textures)
        cameraNode.addChild(hud)
        controls = TouchControls(textures: context.textures)
        cameraNode.addChild(controls)

        layoutForSize()
        showBanner("\(LevelCatalog.ids[levelIndex])  \(level.name.uppercased())")
        refreshHUD()
        syncCamera()
        tileLayer.sync(world: world)
        entitySync.sync(world: world)
    }

    override func layoutForSize() {
        guard hud != nil else { return }
        world.viewSize = Vec2(x: size.width, y: size.height)
        skyNode.size = CGSize(width: size.width, height: size.height)
        hud.layout(sceneSize: size, insets: safeInsets)
        controls.layout(sceneSize: size, insets: safeInsets)
        banner?.position = CGPoint(x: 0, y: size.height / 2 - CGFloat(safeInsets.top) - 34)
        if let overlay {
            overlay.dim.size = CGSize(width: size.width * 2, height: size.height * 2)
        }
    }

    // MARK: - Loop

    override func update(_ currentTime: TimeInterval) {
        guard !transitioning else { return }
        if isPausedByUser {
            clock.reset()
            return
        }
        let steps = clock.advance(to: currentTime)
        let input = controls.input.merged(with: gamepad.input)
        for _ in 0..<steps {
            let events = world.step(input: input)
            handle(events)
            advanceOutcome()
            if shakeFrames > 0 { shakeFrames -= 1 }
        }
        if steps > 0 {
            tileLayer.sync(world: world)
            entitySync.sync(world: world)
            refreshHUD()
            syncCamera()
        }
    }

    private func refreshHUD() {
        var bossHitPoints: Int?
        if let rex = world.boss, rex.phase != .sleeping {
            bossHitPoints = rex.hitPoints
        }
        hud.update(lives: context.session.lives, coins: context.session.coins, score: context.session.score, bossHitPoints: bossHitPoints)
    }

    private func syncCamera() {
        let cam = world.camera.rounded
        var shake = CGPoint.zero
        if shakeFrames > 0 {
            shake = CGPoint(x: rng.nextDouble(in: -2...2).rounded(), y: rng.nextDouble(in: -2...2).rounded())
        }
        cameraNode.position = CGPoint(x: cam.x + shake.x, y: cam.y + shake.y)
        let bottom = -size.height / 2
        for (nodes, factor) in [(farNodes, background.farFactor), (nearNodes, background.nearFactor)] {
            let width = background.tileWidth
            let offset = -(CGFloat(cam.x) * factor).truncatingRemainder(dividingBy: width)
            for (index, node) in nodes.enumerated() {
                node.position = CGPoint(x: offset + CGFloat(index - 1) * width - size.width / 2 + size.width / 2 - width / 2, y: bottom)
            }
        }
    }

    // MARK: - Events

    private func handle(_ events: [GameEvent]) {
        let audio = context.audio
        let session = context.session
        for event in events {
            switch event {
            case .tileChanged(let col, let row):
                tileLayer.tileChanged(col: col, row: row, world: world)
            case .coinCollected(let at):
                effects.coinPop(at: at)
                if session.addCoin() {
                    audio.play(.oneUp)
                    effects.label("1UP", at: at, color: .green)
                } else {
                    audio.play(.coin)
                }
            case .blockBumped:
                audio.play(.blockBump)
            case .brickBroken(let col, let row):
                audio.play(.brickBreak)
                effects.brickBreak(col: col, row: row)
                session.addScore(50)
            case .itemEmerged:
                audio.play(.checkpoint)
            case .playerJumped:
                audio.play(.jump)
            case .playerLanded:
                break
            case .enemyStomped(let at):
                audio.play(.stomp)
                effects.puff(at: at)
            case .enemyKilled(let at):
                audio.play(.kick)
                effects.puff(at: at)
            case .ballKicked:
                audio.play(.kick)
            case .shurikenThrown:
                audio.play(.shuriken)
            case .powerUpCollected:
                audio.play(.powerUp)
            case .oneUp:
                session.addLife()
                audio.play(.oneUp)
                effects.label("1UP", at: Vec2(x: world.player.rect.midX, y: world.player.rect.maxY), color: .green)
            case .playerHurt:
                audio.play(.hurt)
            case .playerDied:
                audio.pauseMusic()
                audio.play(.die)
            case .checkpointReached:
                audio.play(.checkpoint)
                session.checkpoint = world.checkpoint
                effects.label("CHECKPOINT", at: Vec2(x: world.player.rect.midX, y: world.player.rect.maxY + 8))
            case .goalReached:
                audio.play(.levelClear)
                effects.sparkle(at: Vec2(x: level.goal.midX, y: level.goal.maxY - 8))
            case .levelCleared:
                levelCleared()
            case .scorePopup(let points, let at):
                session.addScore(points)
                effects.scorePopup(points: points, at: at)
            case .bossHit:
                audio.play(.bossHit)
                shakeFrames = 6
            case .bossLanded:
                audio.play(.stomp)
            case .bossRoared:
                audio.play(.bossRoar)
            case .bossDefeated:
                audio.play(.bossFall)
                goalNode.texture = context.textures.texture("prop.torii")
                effects.sparkle(at: Vec2(x: level.goal.midX, y: level.goal.maxY - 8))
            case .screenShake(let frames):
                shakeFrames = max(shakeFrames, frames)
            }
        }
    }

    private func advanceOutcome() {
        switch outcome {
        case .none:
            if world.phase == .dead {
                if context.session.loseLife() {
                    outcome = .respawn(framesLeft: 30)
                } else {
                    context.audio.stopMusic()
                    context.audio.play(.uiTap)
                    showOverlay(title: "GAME OVER", subtitle: nil, buttons: [], titleColor: .systemRed)
                    outcome = .gameOver(framesLeft: 150)
                }
            }
        case .respawn(let n):
            if n <= 0 {
                respawn()
            } else {
                outcome = .respawn(framesLeft: n - 1)
            }
        case .levelClear(let n):
            if n <= 0 { goToMap() } else { outcome = .levelClear(framesLeft: n - 1) }
        case .worldClear(let n):
            if n % 30 == 0 && n > 60 {
                effects.fireworks(at: CGPoint(x: rng.nextDouble(in: -120...120), y: rng.nextDouble(in: 0...60)), in: cameraNode, seed: UInt64(n))
            }
            if n <= 0 { goToTitle() } else { outcome = .worldClear(framesLeft: n - 1) }
        case .gameOver(let n):
            if n <= 0 {
                context.progress.recordScore(context.session.score)
                context.session.resetForNewRun()
                goToMap()
            } else {
                outcome = .gameOver(framesLeft: n - 1)
            }
        }
    }

    private func levelCleared() {
        context.audio.stopMusic()
        context.progress.unlock(levelIndex: levelIndex + 1)
        context.progress.recordScore(context.session.score)
        context.session.checkpoint = nil
        if level.hasBoss {
            context.audio.play(.worldClear)
            showOverlay(title: "YOU SAVED THE DOJO!", subtitle: "REX RAN AWAY. NINJA WINS!", buttons: [], titleColor: .systemYellow)
            outcome = .worldClear(framesLeft: 360)
        } else {
            showOverlay(title: "LEVEL CLEAR!", subtitle: "GREAT JOB NINJA", buttons: [], dimAlpha: 0.35)
            outcome = .levelClear(framesLeft: 150)
        }
    }

    private func respawn() {
        outcome = .none
        context.audio.resumeMusic()
        world = GameWorld(level: level, startAt: context.session.checkpoint, viewSize: Vec2(x: size.width, y: size.height))
        tileLayer.reset()
        entitySync.removeAll()
        goalNode.texture = context.textures.texture(world.goalActive ? "prop.torii" : "prop.toriiDark")
        clock.reset()
        controls.releaseAll()
        tileLayer.sync(world: world)
        entitySync.sync(world: world)
        refreshHUD()
        syncCamera()
    }

    // MARK: - Overlays, pause, navigation

    private func showBanner(_ text: String) {
        let banner = PixelTextNode(text, textures: context.textures, color: .white, scale: 1, alignment: .center)
        banner.zPosition = 120
        banner.position = CGPoint(x: 0, y: size.height / 2 - CGFloat(safeInsets.top) - 34)
        cameraNode.addChild(banner)
        banner.run(SKAction.sequence([.wait(forDuration: 2.5), .fadeOut(withDuration: 0.5), .removeFromParent()]))
        self.banner = banner
    }

    private func showOverlay(title: String, subtitle: String?, buttons: [(String, OverlayNode.Action)], dimAlpha: CGFloat = 0.55, titleColor: SKColor = .white) {
        overlay?.removeFromParent()
        let node = OverlayNode(textures: context.textures, sceneSize: size, title: title, subtitle: subtitle, buttons: buttons, dimAlpha: dimAlpha, titleColor: titleColor)
        cameraNode.addChild(node)
        overlay = node
        controls.releaseAll()
    }

    private func hideOverlay() {
        overlay?.removeFromParent()
        overlay = nil
    }

    private func pauseGame() {
        guard !isPausedByUser, case .none = outcome else { return }
        isPausedByUser = true
        context.audio.pauseMusic()
        showOverlay(title: "PAUSED", subtitle: nil, buttons: [("RESUME", .resume), (context.musicLabel, .toggleMusic), ("MAP", .quit)])
    }

    private func resumeGame() {
        isPausedByUser = false
        context.audio.resumeMusic()
        hideOverlay()
        clock.reset()
    }

    private func goToMap() {
        guard !transitioning else { return }
        transitioning = true
        context.session.checkpoint = nil
        present(WorldMapScene(context: context))
    }

    private func goToTitle() {
        guard !transitioning else { return }
        transitioning = true
        context.session.checkpoint = nil
        present(TitleScene(context: context))
    }

    override func applicationWillResignActive() {
        pauseGame()
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let overlay {
            for touch in touches {
                switch overlay.action(at: touch.location(in: overlay)) {
                case .resume:
                    context.audio.play(.uiTap)
                    resumeGame()
                    return
                case .quit:
                    context.audio.play(.uiTap)
                    context.session.resetForNewRun()
                    goToMap()
                    return
                case .toggleMusic:
                    context.audio.play(.uiTap)
                    context.toggleMusic()
                    overlay.setLabel(context.musicLabel, for: .toggleMusic)
                    return
                case .none:
                    break
                }
            }
            return
        }
        var remaining = touches
        for touch in touches where hud.pauseRect.contains(touch.location(in: hud)) {
            remaining.remove(touch)
            context.audio.play(.uiTap)
            pauseGame()
        }
        controls.touchesBegan(remaining)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        controls.touchesMoved(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        controls.touchesEnded(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        controls.touchesEnded(touches)
    }
}
