import SpriteKit

struct SafeInsets: Equatable, Sendable {
    var top: Double = 0
    var left: Double = 0
    var bottom: Double = 0
    var right: Double = 0
}

@MainActor
final class GameContext {
    let session = GameSession()
    let progress = ProgressStore()
    let textures = TextureStore()
    let audio = AudioPlayer()

    init() {
        audio.isMusicEnabled = progress.musicEnabled
    }

    func toggleMusic() {
        progress.musicEnabled.toggle()
        audio.isMusicEnabled = progress.musicEnabled
    }

    var musicLabel: String { progress.musicEnabled ? "MUSIC ON" : "MUSIC OFF" }
}

class BaseScene: SKScene {
    let context: GameContext

    var safeInsets = SafeInsets() {
        didSet { if safeInsets != oldValue { layoutForSize() } }
    }

    init(context: GameContext) {
        self.context = context
        super.init(size: CGSize(width: GameConstants.viewportHeight * 2, height: GameConstants.viewportHeight))
        scaleMode = .aspectFill
        anchorPoint = CGPoint(x: 0, y: 0)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("not used")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if size != oldSize {
            layoutForSize()
        }
    }

    func layoutForSize() {}

    func applicationWillResignActive() {
        context.audio.pauseMusic()
    }

    func applicationDidBecomeActive() {
        context.audio.resumeMusic()
    }

    func present(_ scene: BaseScene, transition: SKTransition = .fade(withDuration: 0.4)) {
        scene.size = size
        scene.safeInsets = safeInsets
        view?.presentScene(scene, transition: transition)
    }

    var safeTopLeft: CGPoint {
        CGPoint(x: safeInsets.left, y: size.height - safeInsets.top)
    }

    var safeTopRight: CGPoint {
        CGPoint(x: size.width - safeInsets.right, y: size.height - safeInsets.top)
    }

    var safeBottomLeft: CGPoint {
        CGPoint(x: safeInsets.left, y: safeInsets.bottom)
    }

    var safeBottomRight: CGPoint {
        CGPoint(x: size.width - safeInsets.right, y: safeInsets.bottom)
    }
}
