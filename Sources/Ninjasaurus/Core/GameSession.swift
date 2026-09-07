@MainActor
final class GameSession {
    private(set) var lives = GameConstants.startingLives
    private(set) var coins = 0
    private(set) var score = 0
    var levelIndex = 0
    var checkpoint: Vec2?

    func resetForNewRun() {
        lives = GameConstants.startingLives
        coins = 0
        score = 0
        checkpoint = nil
    }

    func startLevel(at index: Int) {
        levelIndex = index
        checkpoint = nil
    }

    @discardableResult
    func addCoin() -> Bool {
        coins += 1
        score += GameConstants.coinScore
        if coins >= GameConstants.coinsPerLife {
            coins -= GameConstants.coinsPerLife
            lives += 1
            return true
        }
        return false
    }

    func addScore(_ points: Int) {
        score += points
    }

    func addLife() {
        lives += 1
    }

    func loseLife() -> Bool {
        lives = max(0, lives - 1)
        return lives > 0
    }
}
