enum PlayerForm: Equatable, Sendable {
    case small
    case big
    case shuriken

    var hitbox: Vec2 { self == .small ? GameConstants.smallPlayerSize : GameConstants.bigPlayerSize }
}

final class Player: Entity {
    private(set) var form = PlayerForm.small
    var invulnerableFrames = 0
    var katanaFrames = 0
    var coyoteFrames = 0
    var jumpBufferFrames = 0
    var jumpHeld = false
    var throwCooldown = 0
    var throwPoseFrames = 0
    var isDead = false
    private(set) var isSkidding = false
    private var idleFrames = 0
    private(set) var swordPlayFramesLeft = 0
    var wantsToThrow = false

    init(id: Int, start: Vec2, frame: Int) {
        super.init(id: id, kind: .player, rect: AABB(bottomCenter: start, size: PlayerForm.small.hitbox), frame: frame)
        facing = .right
        despawnsOffscreen = false
    }

    var katanaActive: Bool { katanaFrames > 0 }
    var isBig: Bool { form != .small }

    override var gravity: Double {
        velocity.y > 0 && jumpHeld ? GameConstants.risingGravity : GameConstants.fallingGravity
    }

    func setForm(_ newForm: PlayerForm) {
        guard newForm != form else { return }
        form = newForm
        rect = rect.resized(to: newForm.hitbox)
    }

    func think(input: InputFrame, dt: Double, frame: Int) -> [GameEvent] {
        var events: [GameEvent] = []
        tickTimers()
        jumpHeld = input.held.jump

        // Horizontal
        let direction = input.held.horizontal
        let maxSpeed = input.held.action ? GameConstants.runSpeed : GameConstants.walkSpeed
        isSkidding = false
        if direction != 0 {
            facing = direction > 0 ? .right : .left
            let target = direction * maxSpeed
            if velocity.x * direction < 0 {
                velocity.x = Player.approach(velocity.x, 0, GameConstants.skidDeceleration * dt)
                isSkidding = onGround
            } else {
                let accel = onGround ? GameConstants.groundAcceleration : GameConstants.airAcceleration
                if abs(velocity.x) > maxSpeed {
                    velocity.x = Player.approach(velocity.x, target, GameConstants.stopDeceleration * dt)
                } else {
                    velocity.x = Player.approach(velocity.x, target, accel * dt)
                }
            }
        } else if onGround {
            velocity.x = Player.approach(velocity.x, 0, GameConstants.stopDeceleration * dt)
        }

        // Jump: coyote time and input buffering make it forgiving.
        if onGround {
            coyoteFrames = GameConstants.coyoteFrames
        } else if coyoteFrames > 0 {
            coyoteFrames -= 1
        }
        if input.pressed.jump {
            jumpBufferFrames = GameConstants.jumpBufferFrames
        } else if jumpBufferFrames > 0 {
            jumpBufferFrames -= 1
        }
        if jumpBufferFrames > 0 && (onGround || coyoteFrames > 0) {
            velocity.y = GameConstants.jumpVelocity
            onGround = false
            coyoteFrames = 0
            jumpBufferFrames = 0
            events.append(.playerJumped)
        }

        wantsToThrow = input.pressed.action && form == .shuriken && throwCooldown == 0

        let idle = onGround && direction == 0 && abs(velocity.x) < 4 && !input.held.jump && !input.held.action && throwPoseFrames == 0
        if swordPlayFramesLeft > 0 {
            swordPlayFramesLeft = idle ? swordPlayFramesLeft - 1 : 0
        } else if idle {
            idleFrames += 1
            if idleFrames >= GameConstants.idleFramesBeforeSwordPlay {
                idleFrames = 0
                swordPlayFramesLeft = GameConstants.swordPlayFrames
            }
        } else {
            idleFrames = 0
        }

        updateAnim(frame: frame)
        return events
    }

    func didThrow() {
        throwCooldown = GameConstants.shurikenCooldownFrames
        throwPoseFrames = 8
    }

    func updateAnim(frame: Int) {
        if isDead {
            setAnim(.dead, frame: frame)
        } else if !onGround {
            setAnim(.jump, frame: frame)
        } else if throwPoseFrames > 0 {
            setAnim(.throwing, frame: frame)
        } else if isSkidding {
            setAnim(.skid, frame: frame)
        } else if abs(velocity.x) > 4 {
            setAnim(.walk, frame: frame)
        } else if swordPlayFramesLeft > 0 {
            setAnim(.swordPlay, frame: frame)
        } else {
            setAnim(.idle, frame: frame)
        }
    }

    private func tickTimers() {
        if invulnerableFrames > 0 { invulnerableFrames -= 1 }
        if katanaFrames > 0 { katanaFrames -= 1 }
        if throwCooldown > 0 { throwCooldown -= 1 }
        if throwPoseFrames > 0 { throwPoseFrames -= 1 }
    }

    static func approach(_ value: Double, _ target: Double, _ maxDelta: Double) -> Double {
        if value < target { return min(value + maxDelta, target) }
        if value > target { return max(value - maxDelta, target) }
        return value
    }
}
