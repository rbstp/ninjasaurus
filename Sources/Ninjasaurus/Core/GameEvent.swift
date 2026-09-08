enum GameEvent: Equatable, Sendable {
    case tileChanged(col: Int, row: Int)
    case coinCollected(at: Vec2)
    case blockBumped(col: Int, row: Int)
    case brickBroken(col: Int, row: Int)
    case itemEmerged(kind: PowerUpKind, col: Int, row: Int)
    case playerJumped
    case playerLanded
    case enemyStomped(at: Vec2)
    case enemyKilled(at: Vec2)
    case ballKicked
    case shurikenThrown
    case powerUpCollected(PowerUpKind)
    case oneUp
    case playerHurt
    case playerDied
    case checkpointReached(col: Int, row: Int)
    case goalReached
    case levelCleared
    case scorePopup(points: Int, at: Vec2)
    case bossHit(hitPointsLeft: Int)
    case bossLanded
    case bossRoared
    case bossDefeated
    case screenShake(frames: Int)
}

enum PowerUpKind: Equatable, Sendable, CaseIterable {
    case onigiri
    case shurikenScroll
    case goldenKatana
    case greenScroll
}
