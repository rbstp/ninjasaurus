final class GameWorld {
    enum Phase: Equatable {
        case playing
        case frozen(Int)
        case dying(Int)
        case dead
        case clearing(Int)
        case cleared
    }

    private struct SpawnRecord {
        let spawn: EnemySpawn
        var entityID: Int?
        var killed = false
    }

    let level: LevelDefinition
    private(set) var map: TileMap
    let player: Player
    private(set) var entities: [Entity] = []
    private(set) var boss: Rex?
    private(set) var camera: CameraState
    var viewSize: Vec2 {
        didSet { camera = Camera.initial(playerRect: player.rect, viewSize: viewSize, levelSize: level.pixelSize) }
    }
    private(set) var frame = 0
    private(set) var phase = Phase.playing
    private(set) var blocks = BlockSystem()
    private(set) var goalActive: Bool
    private(set) var checkpoint: Vec2?
    private var rng: SeededRandom
    private var pendingEvents: [GameEvent] = []
    private var previousInput = InputState.none
    private var nextEntityID = 1
    private var spawnRecords: [SpawnRecord]

    init(level: LevelDefinition, startAt checkpoint: Vec2? = nil, viewSize: Vec2 = Vec2(x: 416, y: 208), seed: UInt64 = 1) {
        self.level = level
        map = level.map
        self.viewSize = viewSize
        self.checkpoint = checkpoint
        rng = SeededRandom(seed: seed)
        goalActive = !level.hasBoss
        player = Player(id: 0, start: checkpoint ?? level.playerStart, frame: 0)
        spawnRecords = level.spawns.map { SpawnRecord(spawn: $0) }
        camera = Camera.initial(playerRect: player.rect, viewSize: viewSize, levelSize: level.pixelSize)
        if let bossStart = level.bossSpawn {
            let rex = Rex(id: makeID(), position: bossStart, frame: 0)
            rex.face(toward: player.rect.midX)
            boss = rex
            entities.append(rex)
        }
        spawnEnemies(initial: true)
    }

    var isPlaying: Bool { phase == .playing }
    var levelSize: Vec2 { level.pixelSize }
    var cameraRect: AABB { camera.rect(viewSize: viewSize) }

    func makeID() -> Int {
        defer { nextEntityID += 1 }
        return nextEntityID
    }

    func emit(_ event: GameEvent) {
        pendingEvents.append(event)
    }

    func addEntity(_ entity: Entity) {
        entities.append(entity)
    }

    func activateGoal() {
        goalActive = true
    }

    // MARK: - Step

    func step(input rawInput: InputState) -> [GameEvent] {
        pendingEvents.removeAll(keepingCapacity: true)
        frame += 1
        let dt = GameConstants.stepDuration
        let input = InputFrame(held: rawInput, previous: previousInput)
        previousInput = rawInput

        switch phase {
        case .playing:
            simulate(input: input, dt: dt)
        case .frozen(let n):
            phase = n <= 0 ? .playing : .frozen(n - 1)
            if n <= 0 { player.updateAnim(frame: frame) }
        case .dying(let n):
            if player.affectedByGravity {
                applyPhysics(player, dt: dt)
            }
            phase = n <= 0 ? .dead : .dying(n - 1)
        case .dead:
            break
        case .clearing(let n):
            let walk = InputFrame(held: InputState(right: true), previous: InputState(right: true))
            _ = player.think(input: walk, dt: dt, frame: frame)
            applyPhysics(player, dt: dt)
            if n <= 0 {
                phase = .cleared
                emit(.levelCleared)
            } else {
                phase = .clearing(n - 1)
            }
        case .cleared:
            break
        }

        camera = Camera.update(
            camera, playerRect: player.rect, facing: player.facing, onGround: player.onGround,
            viewSize: viewSize, levelSize: level.pixelSize
        )
        return pendingEvents
    }

    private func simulate(input: InputFrame, dt: Double) {
        blocks.tick(frame: frame)

        // Player
        for event in player.think(input: input, dt: dt, frame: frame) {
            emit(event)
        }
        if player.wantsToThrow {
            throwShuriken()
        }
        let wasOnGround = player.onGround
        applyPhysics(player, dt: dt)
        if player.onGround && !wasOnGround {
            emit(.playerLanded)
        }
        player.updateAnim(frame: frame)
        if player.rect.maxY < GameConstants.pitDeathY {
            startDeath(fell: true)
            return
        }

        // Everyone else
        spawnEnemies(initial: false)
        for entity in entities where !entity.removed {
            entity.update(in: self)
            applyPhysics(entity, dt: dt)
        }

        resolveInteractions()
        if phase == .playing {
            resolveTileTriggers()
        }
        despawn()
    }

    // MARK: - Physics

    private func applyPhysics(_ entity: Entity, dt: Double) {
        if entity.affectedByGravity {
            entity.velocity.y = max(entity.velocity.y - entity.gravity * dt, -GameConstants.terminalVelocity)
        }
        let dx = entity.velocity.x * dt
        let dy = entity.velocity.y * dt
        entity.prevRect = entity.rect
        guard entity.collidesWithTiles else {
            entity.rect = entity.rect.offset(by: Vec2(x: dx, y: dy))
            entity.hitWall = false
            entity.onGround = false
            return
        }
        let moved = TileCollider.moveX(entity.rect, by: dx, in: map)
        entity.rect = moved.rect
        entity.hitWall = moved.hitWall
        if moved.hitWall && entity !== player {
            entity.velocity.x = 0
        } else if moved.hitWall {
            entity.velocity.x = 0
        }
        let vertical = TileCollider.moveY(entity.rect, by: dy, previous: entity.prevRect, in: map)
        entity.rect = vertical.rect
        entity.onGround = vertical.landed
        if vertical.landed {
            entity.velocity.y = 0
        }
        if vertical.hitCeiling {
            entity.velocity.y = 0
            if entity === player {
                bonk(columns: vertical.ceilingColumns, row: vertical.ceilingRow)
            }
        }
    }

    // MARK: - Blocks

    private func bonk(columns: [Int], row: Int) {
        let bumpable = columns.filter { map[$0, row].isBumpable }
        guard let col = bumpable.min(by: { abs(Tiles.origin($0) + 8 - player.rect.midX) < abs(Tiles.origin($1) + 8 - player.rect.midX) }) else {
            return
        }
        let outcome = blocks.bump(col: col, row: row, map: &map, form: player.form, frame: frame)
        emit(.blockBumped(col: col, row: row))
        let blockRect = TileMap.rect(col: col, row: row)
        switch outcome {
        case .none:
            break
        case .coin:
            emit(.tileChanged(col: col, row: row))
            emit(.coinCollected(at: Vec2(x: blockRect.midX, y: blockRect.maxY)))
        case .spawnItem(let kind):
            emit(.tileChanged(col: col, row: row))
            entities.append(Item(id: makeID(), powerUp: kind, blockCol: col, blockRow: row, frame: frame))
            emit(.itemEmerged(kind: kind, col: col, row: row))
        case .broke:
            emit(.tileChanged(col: col, row: row))
            emit(.brickBroken(col: col, row: row))
        }
        // Anything standing on the block gets launched, Mario style.
        let top = blockRect.maxY
        for case let enemy as Enemy in entities where enemy.isKillable {
            let standing = abs(enemy.rect.minY - top) < 1.5
            let overlapsColumn = enemy.rect.maxX > blockRect.minX && enemy.rect.minX < blockRect.maxX
            if standing && overlapsColumn {
                kill(enemy, awayFrom: blockRect.midX, points: enemy.killScore)
            }
        }
    }

    // MARK: - Interactions

    private func resolveInteractions() {
        let live = entities.filter { !$0.removed }
        for entity in live {
            guard phase == .playing else { return }
            switch entity {
            case let rex as Rex:
                if rex.rect.intersects(player.rect) {
                    if rex.canBeHurt && (player.katanaActive || rex.isHeadBonk(by: player)) {
                        rex.takeHit(in: self)
                        player.velocity.y = GameConstants.jumpVelocity
                    } else if rex.hurtsOnTouch {
                        hurtPlayer()
                    }
                }
            case let enemy as Enemy:
                if enemy.isAlive && enemy.rect.intersects(player.rect) {
                    playerTouched(enemy)
                }
            case let item as Item:
                if item.isAlive && item.rect.intersects(player.rect) {
                    collect(item)
                }
            case let fireball as Fireball:
                if fireball.rect.intersects(player.rect) {
                    hurtPlayer()
                }
            case let shuriken as Shuriken:
                for case let target as Enemy in live where target.isAlive && target.rect.intersects(shuriken.rect) {
                    if let rex = target as? Rex {
                        if rex.takeHit(in: self) { shuriken.removed = true }
                    } else if target.isKillable {
                        kill(target, awayFrom: shuriken.rect.midX, points: target.killScore * 2)
                        shuriken.removed = true
                    }
                    if shuriken.removed { break }
                }
            default:
                break
            }
        }

        // Rolling balls flatten everyone; walkers turn around when they meet.
        let enemies = live.compactMap { $0 as? Enemy }.filter { $0.isAlive }
        for (i, a) in enemies.enumerated() {
            for b in enemies[(i + 1)...] where a.rect.intersects(b.rect) {
                if let ball = a as? Anky, ball.isMovingBall, b.isKillable {
                    chainKill(ball: ball, victim: b)
                } else if let ball = b as? Anky, ball.isMovingBall, a.isKillable {
                    chainKill(ball: ball, victim: a)
                } else if a.isWalker && b.isWalker {
                    a.facing = a.facing.flipped
                    b.facing = b.facing.flipped
                    let push = a.rect.midX < b.rect.midX ? -1.0 : 1.0
                    a.rect.minX += push
                    b.rect.minX -= push
                }
            }
        }
    }

    private func playerTouched(_ enemy: Enemy) {
        if player.katanaActive && enemy.isKillable {
            kill(enemy, awayFrom: player.rect.midX, points: enemy.killScore * 2)
            return
        }
        let falling = player.velocity.y < 0 && player.rect.minY >= enemy.rect.midY
        if let anky = enemy as? Anky {
            if anky.isIdleBall {
                anky.kick(awayFrom: player.rect.midX, in: self)
                emit(.ballKicked)
                if falling { bounce() }
                return
            }
            if anky.isMovingBall && falling {
                anky.stomped(by: player, in: self)
                bounce()
                emit(.enemyStomped(at: anky.rect.center))
                return
            }
        }
        if enemy.isStompable && falling {
            enemy.stomped(by: player, in: self)
            bounce()
            emit(.enemyStomped(at: enemy.rect.center))
            emit(.scorePopup(points: GameConstants.stompScore, at: Vec2(x: enemy.rect.midX, y: enemy.rect.maxY)))
            return
        }
        if enemy.hurtsOnTouch {
            hurtPlayer()
        }
    }

    private func bounce() {
        player.velocity.y = player.jumpHeld ? GameConstants.stompBounceHeld : GameConstants.stompBounce
        player.onGround = false
    }

    private func chainKill(ball: Anky, victim: Enemy) {
        let scores = GameConstants.ballChainScores
        let points = scores[min(ball.chain, scores.count - 1)]
        ball.chain += 1
        kill(victim, awayFrom: ball.rect.midX, points: points)
    }

    private func kill(_ enemy: Enemy, awayFrom x: Double, points: Int) {
        enemy.knockOut(awayFrom: x, in: self)
        if let index = enemy.spawnIndex {
            spawnRecords[index].killed = true
        }
        emit(.enemyKilled(at: enemy.rect.center))
        emit(.scorePopup(points: points, at: Vec2(x: enemy.rect.midX, y: enemy.rect.maxY)))
    }

    private func collect(_ item: Item) {
        item.removed = true
        emit(.powerUpCollected(item.powerUp))
        switch item.powerUp {
        case .onigiri:
            if player.form == .small {
                player.setForm(.big)
                phase = .frozen(20)
            }
            emit(.scorePopup(points: GameConstants.powerUpScore, at: item.rect.center))
        case .shurikenScroll:
            if player.form == .small {
                player.setForm(.big)
                phase = .frozen(20)
            } else if player.form == .big {
                player.setForm(.shuriken)
                phase = .frozen(20)
            }
            emit(.scorePopup(points: GameConstants.powerUpScore, at: item.rect.center))
        case .goldenKatana:
            player.katanaFrames = GameConstants.katanaFrames
            emit(.scorePopup(points: GameConstants.powerUpScore, at: item.rect.center))
        case .greenScroll:
            emit(.oneUp)
        }
    }

    func hurtPlayer() {
        guard phase == .playing, !player.isDead, player.invulnerableFrames == 0, !player.katanaActive else { return }
        if player.form == .small {
            startDeath(fell: false)
            return
        }
        player.setForm(player.form == .shuriken ? .big : .small)
        player.invulnerableFrames = GameConstants.invulnerabilityFrames
        player.setAnim(.hurt, frame: frame)
        phase = .frozen(GameConstants.hurtFreezeFrames)
        emit(.playerHurt)
    }

    private func startDeath(fell: Bool) {
        player.isDead = true
        player.isAlive = false
        player.collidesWithTiles = false
        player.setAnim(.dead, frame: frame)
        if fell {
            player.affectedByGravity = false
            player.velocity = .zero
        } else {
            player.velocity = Vec2(x: 0, y: 250)
        }
        phase = .dying(GameConstants.deathFrames)
        emit(.playerDied)
    }

    private func throwShuriken() {
        let flying = entities.filter { $0 is Shuriken && !$0.removed }.count
        guard flying < GameConstants.maxShurikens else { return }
        entities.append(Shuriken(id: makeID(), from: player, frame: frame))
        player.didThrow()
        emit(.shurikenThrown)
    }

    func spawnFireball(from rex: Rex) {
        entities.append(Fireball(id: makeID(), from: rex, frame: frame))
    }

    // MARK: - Tiles the player touches

    private func resolveTileTriggers() {
        let rect = player.rect
        let cols = Tiles.index(rect.minX + 1)...Tiles.index(rect.maxX - 1)
        let rows = Tiles.index(rect.minY + 1)...Tiles.index(rect.maxY - 1)
        for row in rows {
            for col in cols {
                let coord = TileCoord(col: col, row: row)
                switch map[coord] {
                case .coin:
                    map[coord] = .empty
                    emit(.tileChanged(col: col, row: row))
                    emit(.coinCollected(at: TileMap.rect(col: col, row: row).center))
                case .hazard:
                    // A smaller box so brushing the edge of spikes is forgiven.
                    let hazardBox = TileMap.rect(col: col, row: row).offset(by: Vec2(x: 3, y: 0))
                    if AABB(minX: hazardBox.minX, minY: hazardBox.minY, width: 10, height: 12).intersects(rect) {
                        let before = player.invulnerableFrames
                        hurtPlayer()
                        if player.invulnerableFrames > before || player.isDead {
                            player.velocity.y = GameConstants.jumpVelocity * 0.8
                            player.onGround = false
                        }
                    }
                case .lantern:
                    map[coord] = .lanternLit
                    checkpoint = Vec2(x: TileMap.rect(col: col, row: row).midX, y: TileMap.rect(col: col, row: row).minY)
                    emit(.tileChanged(col: col, row: row))
                    emit(.checkpointReached(col: col, row: row))
                default:
                    break
                }
            }
        }
        if goalActive && phase == .playing && rect.intersects(level.goal) {
            phase = .clearing(GameConstants.levelClearWalkFrames)
            player.invulnerableFrames = 0
            emit(.goalReached)
            emit(.scorePopup(points: GameConstants.levelClearScore, at: Vec2(x: level.goal.midX, y: level.goal.maxY)))
        }
    }

    // MARK: - Spawning

    private func spawnEnemies(initial: Bool) {
        let view = cameraRect
        for index in spawnRecords.indices {
            let record = spawnRecords[index]
            guard record.entityID == nil, !record.killed else { continue }
            let x = record.spawn.position.x
            let visible = x > view.minX - 8 && x < view.maxX + 8
            let inBand = x > view.minX - 40 && x < view.maxX + 40
            guard initial ? inBand : (inBand && !visible) else { continue }
            let enemy = makeEnemy(record.spawn)
            enemy.spawnIndex = index
            enemy.face(toward: player.rect.midX)
            spawnRecords[index].entityID = enemy.id
            entities.append(enemy)
        }
    }

    private func makeEnemy(_ spawn: EnemySpawn) -> Enemy {
        let id = makeID()
        switch spawn.kind {
        case .raptor: return Raptor(id: id, position: spawn.position, frame: frame)
        case .anky: return Anky(id: id, position: spawn.position, frame: frame)
        case .ptero: return Ptero(id: id, position: spawn.position, frame: frame)
        case .stego: return Stego(id: id, position: spawn.position, frame: frame)
        }
    }

    private func despawn() {
        let view = cameraRect
        let farAway = viewSize.x * GameConstants.despawnDistanceScreens
        for entity in entities where !entity.removed {
            if entity.rect.maxY < -48 {
                entity.removed = true
                continue
            }
            guard entity.despawnsOffscreen else { continue }
            let distance = abs(entity.rect.midX - view.midX)
            if distance > farAway {
                entity.removed = true
            }
        }
        for entity in entities where entity.removed {
            if let enemy = entity as? Enemy, let index = enemy.spawnIndex, spawnRecords[index].entityID == enemy.id {
                spawnRecords[index].entityID = nil
                if !enemy.isAlive { spawnRecords[index].killed = true }
            }
        }
        entities.removeAll { $0.removed }
        if let rex = boss, rex.removed { boss = nil }
    }

    // MARK: - Debug / tests

    var enemies: [Enemy] { entities.compactMap { $0 as? Enemy } }
    var items: [Item] { entities.compactMap { $0 as? Item } }
    var shurikens: [Shuriken] { entities.compactMap { $0 as? Shuriken } }

    func bumpOffset(col: Int, row: Int) -> Double {
        blocks.offset(col: col, row: row, frame: frame)
    }
}
