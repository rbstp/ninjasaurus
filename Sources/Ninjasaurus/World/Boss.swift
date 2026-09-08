final class Rex: Enemy {
    enum Phase: Equatable {
        case sleeping
        case idle(Int)
        case walking(Int)
        case leaping
        case stunned(Int)
        case roaring(Int)
        case hurt(Int)
        case defeated(Int)
        case falling
    }

    private(set) var hitPoints = GameConstants.rexHitPoints
    private(set) var phase = Phase.sleeping
    private var cycle = 0
    private var fireballsThisRoar = 1

    init(id: Int, position: Vec2, frame: Int) {
        super.init(id: id, kind: .rex, rect: AABB(bottomCenter: position, size: GameConstants.rexSize), frame: frame)
        isStompable = false
        despawnsOffscreen = false
        killScore = GameConstants.bossHitScore
    }

    var isDefeated: Bool {
        switch phase {
        case .defeated, .falling: return true
        default: return false
        }
    }

    var canBeHurt: Bool {
        switch phase {
        case .sleeping, .hurt, .defeated, .falling: return false
        default: return true
        }
    }

    override var hurtsOnTouch: Bool { canBeHurt }
    override var isKillable: Bool { false }
    override var isWalker: Bool { false }

    func isHeadBonk(by player: Player) -> Bool {
        player.velocity.y < 0 && player.rect.minY >= rect.maxY - 10
    }

    override func update(in world: GameWorld) {
        let player = world.player
        switch phase {
        case .sleeping:
            velocity.x = 0
            face(toward: player.rect.midX)
            if abs(player.rect.midX - rect.midX) < world.viewSize.x * 0.6 {
                phase = .idle(GameConstants.rexIdleFrames)
            }
            setAnim(.idle, frame: world.frame)
        case .idle(let n):
            velocity.x = 0
            face(toward: player.rect.midX)
            setAnim(.idle, frame: world.frame)
            phase = n <= 0 ? .walking(GameConstants.rexWalkFrames) : .idle(n - 1)
        case .walking(let n):
            face(toward: player.rect.midX)
            velocity.x = facing.sign * GameConstants.rexWalkSpeed
            setAnim(.walk, frame: world.frame)
            if n <= 0 {
                velocity = Vec2(x: facing.sign * GameConstants.rexLeapVX, y: GameConstants.rexLeapVY)
                onGround = false
                phase = .leaping
            } else {
                phase = .walking(n - 1)
            }
        case .leaping:
            setAnim(.leap, frame: world.frame)
            if onGround {
                velocity.x = 0
                phase = .stunned(GameConstants.rexStunFrames)
                world.emit(.bossLanded)
                world.emit(.screenShake(frames: 12))
            }
        case .stunned(let n):
            velocity.x = 0
            setAnim(.stun, frame: world.frame)
            if n <= 0 {
                face(toward: player.rect.midX)
                fireballsThisRoar = cycle % 3 == 2 ? 2 : 1
                cycle += 1
                phase = .roaring(GameConstants.rexRoarFrames)
                world.emit(.bossRoared)
            } else {
                phase = .stunned(n - 1)
            }
        case .roaring(let n):
            velocity.x = 0
            setAnim(.roar, frame: world.frame)
            if n == GameConstants.rexRoarFrames - 8 || (fireballsThisRoar == 2 && n == 4) {
                world.spawnFireball(from: self)
            }
            phase = n <= 0 ? .walking(GameConstants.rexWalkFrames) : .roaring(n - 1)
        case .hurt(let n):
            velocity.x = -facing.sign * GameConstants.rexHurtRetreatSpeed
            if hitWall { velocity.x = 0 }
            setAnim(.hurt, frame: world.frame)
            if n <= 0 {
                if hitPoints <= 0 {
                    phase = .defeated(GameConstants.rexDefeatFlashFrames)
                    isAlive = false
                } else {
                    phase = .walking(GameConstants.rexWalkFrames)
                }
            } else {
                phase = .hurt(n - 1)
            }
        case .defeated(let n):
            velocity = .zero
            setAnim(.defeated, frame: world.frame)
            if n <= 0 {
                collidesWithTiles = false
                phase = .falling
                world.activateGoal()
                world.emit(.bossDefeated)
            } else {
                phase = .defeated(n - 1)
            }
        case .falling:
            setAnim(.defeated, frame: world.frame)
            if rect.maxY < -64 { removed = true }
        }
    }

    @discardableResult
    func takeHit(in world: GameWorld) -> Bool {
        guard canBeHurt else { return false }
        hitPoints -= 1
        velocity.x = 0
        phase = .hurt(GameConstants.rexHurtFrames)
        setAnim(.hurt, frame: world.frame)
        world.emit(.bossHit(hitPointsLeft: hitPoints))
        world.emit(.scorePopup(points: GameConstants.bossHitScore, at: Vec2(x: rect.midX, y: rect.maxY)))
        return true
    }
}
