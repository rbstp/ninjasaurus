import XCTest
@testable import Ninjasaurus

final class ScoreLivesProgressTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        let name = "NinjasaurusTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @MainActor
    func testHundredCoinsGiveALifeAndWrap() {
        let session = GameSession()
        for _ in 0..<99 {
            XCTAssertFalse(session.addCoin())
        }
        XCTAssertTrue(session.addCoin())
        XCTAssertEqual(session.coins, 0)
        XCTAssertEqual(session.lives, GameConstants.startingLives + 1)
        XCTAssertEqual(session.score, 100 * GameConstants.coinScore)
    }

    @MainActor
    func testLosingLastLifeReportsGameOver() {
        let session = GameSession()
        for _ in 0..<(GameConstants.startingLives - 1) {
            XCTAssertTrue(session.loseLife())
        }
        XCTAssertFalse(session.loseLife())
        XCTAssertEqual(session.lives, 0)
        session.resetForNewRun()
        XCTAssertEqual(session.lives, GameConstants.startingLives)
        XCTAssertEqual(session.coins, 0)
    }

    func testProgressStartsWithOneLevelAndUnlocksForward() {
        let store = ProgressStore(defaults: freshDefaults())
        XCTAssertEqual(store.unlockedLevelCount, 1)
        XCTAssertTrue(store.isUnlocked(levelIndex: 0))
        XCTAssertFalse(store.isUnlocked(levelIndex: 1))
        store.unlock(levelIndex: 2)
        XCTAssertEqual(store.unlockedLevelCount, 3)
        // Unlocking an earlier level never regresses.
        store.unlock(levelIndex: 0)
        XCTAssertEqual(store.unlockedLevelCount, 3)
    }

    func testBestScoreOnlyGrows() {
        let store = ProgressStore(defaults: freshDefaults())
        store.recordScore(500)
        store.recordScore(200)
        XCTAssertEqual(store.bestScore, 500)
    }
}
