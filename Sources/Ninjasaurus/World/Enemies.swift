import Foundation

class Enemy: Entity {
    var isStompable = true
    var speed: Double = GameConstants.raptorSpeed
    var turnsAtLedges = false
    var killScore = GameConstants.stompScore
    var spawnIndex: Int?
    private var squishedUntil: Int?

    var hurtsOnTouch: Bool { isAlive }

    var isKillable: Bool { isAlive }

    var isWalker: Bool { isAlive && affectedByGravity }

    override func update(in world: GameWorld) {
        if let until = squishedUntil {
            if world.frame >= until { removed = true }
            return
        }
        guard isAlive else { return }
        walk(in: world)
    }

    func walk(in world: GameWorld) {
        if hitWall { facing = facing.flipped }
        if onGround {
            let footX = facing == .right ? rect.maxX + 1 : rect.minX - 1
            if TileCollider.hazardAhead(x: footX, footY: rect.minY, in: world.map) {
                facing = facing.flipped
            } else if turnsAtLedges && !TileCollider.hasFloor(x: footX, belowY: rect.minY, in: world.map) {
                facing = facing.flipped
            }
        }
        velocity.x = facing.sign * speed
        setAnim(.walk, frame: world.frame)
    }

    func stomped(by player: Player, in world: GameWorld) {
        squish(in: world)
    }

    func squish(in world: GameWorld) {
        isAlive = false
        velocity = .zero
        squishedUntil = world.frame + GameConstants.squishedFrames
        setAnim(.squished, frame: world.frame)
    }

    func knockOut(awayFrom x: Double, in world: GameWorld) {
        isAlive = false
        collidesWithTiles = false
        affectedByGravity = true
        onGround = false
        velocity = Vec2(x: x < rect.midX ? 40 : -40, y: GameConstants.enemyDeathPopVelocity)
        setAnim(.dead, frame: world.frame)
    }
}

final class Raptor: Enemy {
    init(id: Int, position: Vec2, frame: Int) {
        super.init(id: id, kind: .raptor, rect: AABB(bottomCenter: position, size: GameConstants.enemySize), frame: frame)
        speed = GameConstants.raptorSpeed
    }
}

final class Stego: Enemy {
    init(id: Int, position: Vec2, frame: Int) {
        super.init(id: id, kind: .stego, rect: AABB(bottomCenter: position, size: GameConstants.enemySize), frame: frame)
        speed = GameConstants.stegoSpeed
        turnsAtLedges = true
        isStompable = false
        killScore = 200
    }
}

final class Anky: Enemy {
    enum State: Equatable {
        case walking
        case ballIdle(framesLeft: Int)
        case ballMoving
    }

    private(set) var state = State.walking
    var chain = 0

    init(id: Int, position: Vec2, frame: Int) {
        super.init(id: id, kind: .anky, rect: AABB(bottomCenter: position, size: GameConstants.enemySize), frame: frame)
        speed = GameConstants.ankySpeed
        turnsAtLedges = true
    }

    var isMovingBall: Bool { state == .ballMoving }
    var isIdleBall: Bool {
        if case .ballIdle = state { return true }
        return false
    }

    override var hurtsOnTouch: Bool { isAlive && !isIdleBall }
    override var isWalker: Bool { isAlive && state == .walking }

    override func update(in world: GameWorld) {
        guard isAlive else {
            super.update(in: world)
            return
        }
        switch state {
        case .walking:
            walk(in: world)
        case .ballIdle(let framesLeft):
            velocity.x = 0
            if framesLeft <= 0 {
                state = .walking
                kind = .anky
                face(toward: world.player.rect.midX)
                setAnim(.walk, frame: world.frame)
            } else {
                state = .ballIdle(framesLeft: framesLeft - 1)
                setAnim(framesLeft < GameConstants.ballWiggleFrames ? .ballWiggle : .ball, frame: world.frame)
            }
        case .ballMoving:
            if hitWall { facing = facing.flipped }
            if onGround && TileCollider.hazardAhead(x: facing == .right ? rect.maxX + 1 : rect.minX - 1, footY: rect.minY, in: world.map) {
                facing = facing.flipped
            }
            velocity.x = facing.sign * GameConstants.ballSpeed
            setAnim(.ball, frame: world.frame)
        }
    }

    override func stomped(by player: Player, in world: GameWorld) {
        switch state {
        case .walking, .ballMoving:
            state = .ballIdle(framesLeft: GameConstants.ballIdleFrames)
            kind = .ankyBall
            velocity.x = 0
            setAnim(.ball, frame: world.frame)
        case .ballIdle:
            kick(awayFrom: player.rect.midX, in: world)
        }
    }

    func kick(awayFrom x: Double, in world: GameWorld) {
        facing = x < rect.midX ? .right : .left
        state = .ballMoving
        kind = .ankyBall
        chain = 0
        setAnim(.ball, frame: world.frame)
    }
}

final class Ptero: Enemy {
    private let anchor: Vec2
    private(set) var isGrounded = false

    init(id: Int, position: Vec2, frame: Int) {
        let anchor = Vec2(x: position.x, y: position.y + 3 * GameConstants.tileSize)
        self.anchor = anchor
        super.init(id: id, kind: .ptero, rect: AABB(bottomCenter: anchor, size: GameConstants.pteroSize), frame: frame)
        affectedByGravity = false
        collidesWithTiles = false
        speed = GameConstants.raptorSpeed
        setAnim(.fly, frame: frame)
    }

    override var isWalker: Bool { isAlive && isGrounded }

    override func update(in world: GameWorld) {
        guard isAlive, !isGrounded else {
            super.update(in: world)
            return
        }
        let t = Double(world.frame - spawnFrame) / Double(GameConstants.pteroPeriodFrames)
        rect.minY = anchor.y + GameConstants.pteroAmplitude * sin(t * 2 * Double.pi)
        if rect.midX > anchor.x + GameConstants.pteroDriftSpan / 2 { facing = .left }
        if rect.midX < anchor.x - GameConstants.pteroDriftSpan / 2 { facing = .right }
        velocity = Vec2(x: facing.sign * GameConstants.pteroDriftSpeed, y: 0)
        setAnim(.fly, frame: world.frame)
    }

    override func stomped(by player: Player, in world: GameWorld) {
        if isGrounded {
            squish(in: world)
            return
        }
        isGrounded = true
        kind = .pteroWalker
        affectedByGravity = true
        collidesWithTiles = true
        velocity = .zero
        setAnim(.walk, frame: world.frame)
    }
}
