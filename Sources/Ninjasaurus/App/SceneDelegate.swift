import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var gameViewController: GameViewController?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let controller = GameViewController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        gameViewController = controller
    }

    func sceneWillResignActive(_ scene: UIScene) {
        gameViewController?.applicationWillResignActive()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        gameViewController?.applicationDidBecomeActive()
    }
}
