import Foundation

struct ProgressStore {
    private let defaults: UserDefaults
    private let unlockedKey = "unlockedLevelCount"
    private let bestScoreKey = "bestScore"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var unlockedLevelCount: Int {
        get { max(1, defaults.integer(forKey: unlockedKey)) }
        nonmutating set { defaults.set(max(1, newValue), forKey: unlockedKey) }
    }

    var bestScore: Int {
        get { defaults.integer(forKey: bestScoreKey) }
        nonmutating set { defaults.set(newValue, forKey: bestScoreKey) }
    }

    func unlock(levelIndex: Int) {
        unlockedLevelCount = max(unlockedLevelCount, levelIndex + 1)
    }

    func recordScore(_ score: Int) {
        bestScore = max(bestScore, score)
    }

    func isUnlocked(levelIndex: Int) -> Bool {
        levelIndex < unlockedLevelCount
    }
}
