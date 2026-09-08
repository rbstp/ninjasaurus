final class Item: Entity {
    let powerUp: PowerUpKind
    private var emergeFramesLeft: Int
    private let emergeTargetY: Double

    init(id: Int, powerUp: PowerUpKind, blockCol: Int, blockRow: Int, frame: Int) {
        self.powerUp = powerUp
        let blockRect = TileMap.rect(col: blockCol, row: blockRow)
        emergeFramesLeft = GameConstants.itemEmergeFrames
        emergeTargetY = blockRect.maxY
        let start = AABB(
            minX: blockRect.midX - GameConstants.itemSize.x / 2,
            minY: blockRect.minY + 1,
            width: GameConstants.itemSize.x,
            height: GameConstants.itemSize.y
        )
        super.init(id: id, kind: .item(powerUp), rect: start, frame: frame)
        isAlive = false
        affectedByGravity = false
        collidesWithTiles = false
        setAnim(.emerging, frame: frame)
    }

    var isEmerging: Bool { emergeFramesLeft > 0 }

    override func update(in world: GameWorld) {
        if emergeFramesLeft > 0 {
            emergeFramesLeft -= 1
            let rise = (emergeTargetY - (emergeTargetY - GameConstants.tileSize + 1)) / Double(GameConstants.itemEmergeFrames)
            rect.minY = min(emergeTargetY, rect.minY + rise)
            if emergeFramesLeft == 0 {
                rect.minY = emergeTargetY
                isAlive = true
                collidesWithTiles = true
                affectedByGravity = true
                facing = world.player.rect.midX < rect.midX ? .right : .left
                setAnim(.idle, frame: world.frame)
            }
            return
        }
        switch powerUp {
        case .onigiri, .greenScroll:
            if hitWall { facing = facing.flipped }
            velocity.x = facing.sign * GameConstants.itemWalkSpeed
        case .shurikenScroll:
            velocity.x = 0
        case .goldenKatana:
            if hitWall { facing = facing.flipped }
            velocity.x = facing.sign * GameConstants.katanaHopSpeed
            if onGround {
                velocity.y = GameConstants.katanaHopVelocity
                onGround = false
            }
        }
    }
}

final class Shuriken: Entity {
    private let expiresAt: Int

    init(id: Int, from player: Player, frame: Int) {
        let origin = Vec2(x: player.rect.midX + player.facing.sign * 8, y: player.rect.minY + player.rect.height * 0.55)
        var rect = AABB(bottomCenter: origin, size: GameConstants.shurikenSize)
        rect.minY -= GameConstants.shurikenSize.y / 2
        expiresAt = frame + 120
        super.init(id: id, kind: .shuriken, rect: rect, frame: frame)
        facing = player.facing
        velocity = Vec2(x: facing.sign * GameConstants.shurikenSpeed, y: 0)
        affectedByGravity = false
    }

    override func update(in world: GameWorld) {
        if hitWall || world.frame >= expiresAt {
            removed = true
        }
    }
}

final class Fireball: Entity {
    init(id: Int, from rex: Rex, frame: Int) {
        let origin = Vec2(x: rex.rect.midX + rex.facing.sign * 18, y: rex.rect.minY + 10)
        super.init(id: id, kind: .fireball, rect: AABB(bottomCenter: origin, size: GameConstants.fireballSize), frame: frame)
        facing = rex.facing
        velocity = Vec2(x: facing.sign * GameConstants.fireballSpeed, y: 0)
        affectedByGravity = false
    }

    override func update(in world: GameWorld) {
        if hitWall { removed = true }
    }
}
