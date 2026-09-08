enum EntityKind: Equatable, Sendable {
    case player
    case raptor
    case anky
    case ankyBall
    case ptero
    case pteroWalker
    case stego
    case rex
    case fireball
    case item(PowerUpKind)
    case shuriken
}

enum AnimState: Equatable, Sendable {
    case idle
    case walk
    case jump
    case skid
    case throwing
    case swordPlay
    case hurt
    case dead
    case squished
    case ball
    case ballWiggle
    case fly
    case leap
    case stun
    case roar
    case defeated
    case emerging
}

class Entity {
    let id: Int
    var kind: EntityKind
    var rect: AABB
    var prevRect: AABB
    var velocity = Vec2.zero
    var facing = Facing.left
    var onGround = false
    var hitWall = false
    var affectedByGravity = true
    var collidesWithTiles = true
    var isAlive = true
    var removed = false
    var despawnsOffscreen = true
    private(set) var animState = AnimState.idle
    private(set) var animStart = 0
    let spawnFrame: Int

    init(id: Int, kind: EntityKind, rect: AABB, frame: Int) {
        self.id = id
        self.kind = kind
        self.rect = rect
        prevRect = rect
        spawnFrame = frame
        animStart = frame
    }

    var gravity: Double { GameConstants.fallingGravity }

    func update(in world: GameWorld) {}

    func setAnim(_ state: AnimState, frame: Int) {
        guard state != animState else { return }
        animState = state
        animStart = frame
    }

    func animElapsed(frame: Int) -> Int {
        frame - animStart
    }

    func face(toward x: Double) {
        facing = x < rect.midX ? .left : .right
    }
}
