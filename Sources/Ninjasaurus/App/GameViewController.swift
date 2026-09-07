import SpriteKit
import UIKit

final class GameViewController: UIViewController {
    private let context = GameContext()
    private var skView: SKView { view as! SKView }

    override func loadView() {
        view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.36, green: 0.74, blue: 0.99, alpha: 1)
        skView.ignoresSiblingOrder = true
        skView.isMultipleTouchEnabled = true
        skView.preferredFramesPerSecond = 60
        skView.showsFPS = false
        skView.showsNodeCount = false
        let scene = initialScene()
        scene.size = sceneSize()
        scene.safeInsets = sceneSafeInsets()
        skView.presentScene(scene)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let scene = skView.scene as? BaseScene else { return }
        scene.size = sceneSize()
        scene.safeInsets = sceneSafeInsets()
    }

    private func initialScene() -> BaseScene {
        let defaults = UserDefaults.standard
        guard let level = defaults.object(forKey: "level") as? String, let index = Int(level), index >= 0, index < LevelCatalog.count else {
            return TitleScene(context: context)
        }
        context.session.startLevel(at: index)
        if let x = defaults.object(forKey: "startX") as? String, let startX = Double(x) {
            context.session.checkpoint = Vec2(x: startX, y: 32)
        }
        return GameScene(context: context, levelIndex: index)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var shouldAutorotate: Bool { true }

    func applicationWillResignActive() {
        (skView.scene as? BaseScene)?.applicationWillResignActive()
    }

    func applicationDidBecomeActive() {
        (skView.scene as? BaseScene)?.applicationDidBecomeActive()
    }

    // MARK: - Scene metrics

    private var pointsPerUnit: CGFloat {
        let height = max(view.bounds.height, 1)
        return height / CGFloat(GameConstants.viewportHeight)
    }

    private func sceneSize() -> CGSize {
        let bounds = view.bounds
        guard bounds.height > 0 else {
            return CGSize(width: GameConstants.viewportHeight * 2, height: GameConstants.viewportHeight)
        }
        let width = (bounds.width / bounds.height * CGFloat(GameConstants.viewportHeight)).rounded()
        return CGSize(width: width, height: CGFloat(GameConstants.viewportHeight))
    }

    private func sceneSafeInsets() -> SafeInsets {
        let insets = view.safeAreaInsets
        let scale = pointsPerUnit
        return SafeInsets(
            top: Double(insets.top / scale),
            left: Double(insets.left / scale),
            bottom: Double(insets.bottom / scale),
            right: Double(insets.right / scale)
        )
    }
}
