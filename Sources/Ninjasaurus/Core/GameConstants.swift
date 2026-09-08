enum GameConstants {
    // MARK: World
    static let tileSize: Double = 16
    static let viewportHeight: Double = 176
    static let stepDuration: Double = 1.0 / 60.0
    static let maxStepsPerFrame = 4
    static let pitDeathY: Double = -16               // player top below this = fell in a pit

    // MARK: Player movement (px/s, px/s^2)
    static let walkSpeed: Double = 90
    static let runSpeed: Double = 140
    static let groundAcceleration: Double = 400
    static let skidDeceleration: Double = 700
    static let airAcceleration: Double = 300
    static let stopDeceleration: Double = 500
    static let jumpVelocity: Double = 270
    static let risingGravity: Double = 500           // while going up with jump held
    static let fallingGravity: Double = 950
    static let terminalVelocity: Double = 280
    static let stompBounce: Double = 160
    static let stompBounceHeld: Double = 240
    static let coyoteFrames = 6
    static let jumpBufferFrames = 8

    // MARK: Player state (frames)
    static let invulnerabilityFrames = 90
    static let katanaFrames = 600
    static let hurtFreezeFrames = 30
    static let deathFrames = 100
    static let levelClearWalkFrames = 70
    static let shurikenCooldownFrames = 12
    static let maxShurikens = 2
    static let shurikenSpeed: Double = 200
    static let idleFramesBeforeSwordPlay = 180
    static let swordPlayFrames = 80

    // MARK: Hitboxes
    static let smallPlayerSize = Vec2(x: 12, y: 15)
    static let bigPlayerSize = Vec2(x: 12, y: 30)
    static let enemySize = Vec2(x: 14, y: 14)
    static let pteroSize = Vec2(x: 14, y: 12)
    static let itemSize = Vec2(x: 14, y: 14)
    static let shurikenSize = Vec2(x: 8, y: 8)
    static let rexSize = Vec2(x: 28, y: 30)
    static let fireballSize = Vec2(x: 14, y: 8)

    // MARK: Enemies
    static let raptorSpeed: Double = 40
    static let ankySpeed: Double = 40
    static let stegoSpeed: Double = 30
    static let pteroDriftSpeed: Double = 20
    static let pteroAmplitude: Double = 32
    static let pteroPeriodFrames = 180
    static let pteroDriftSpan: Double = 6 * tileSize
    static let ballSpeed: Double = 200
    static let ballIdleFrames = 480
    static let ballWiggleFrames = 120
    static let squishedFrames = 30
    static let enemyDeathPopVelocity: Double = 200
    static let despawnDistanceScreens: Double = 1.5

    // MARK: Items
    static let itemEmergeFrames = 30
    static let itemWalkSpeed: Double = 40
    static let katanaHopSpeed: Double = 60
    static let katanaHopVelocity: Double = 200

    // MARK: Boss
    static let rexHitPoints = 3
    static let rexIdleFrames = 48
    static let rexWalkFrames = 150
    static let rexWalkSpeed: Double = 35
    static let rexLeapVX: Double = 90
    static let rexLeapVY: Double = 320
    static let rexStunFrames = 48
    static let rexRoarFrames = 30
    static let rexHurtFrames = 72
    static let rexHurtRetreatSpeed: Double = 60
    static let rexDefeatFlashFrames = 60
    static let fireballSpeed: Double = 70

    // MARK: Scoring / lives
    static let startingLives = 5
    static let coinsPerLife = 100
    static let coinScore = 200
    static let stompScore = 100
    static let powerUpScore = 1000
    static let levelClearScore = 5000
    static let bossHitScore = 1000
    static let ballChainScores = [200, 500, 1000]

    // MARK: Camera
    static let cameraLookahead: Double = 20
    static let cameraFollowRate: Double = 0.12
    static let cameraVerticalDeadZone: Double = 40
    static let cameraVerticalHardZone: Double = 72
}
