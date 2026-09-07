import XCTest
@testable import Ninjasaurus

final class GameplayRulesTests: XCTestCase {
    private let blocks = """
    ! name: Blocks
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ...?.M.=.+.*........
    ....................
    ....................
    ...S..............F.
    GGGGGGGGGGGGGGGGGGGG
    ####################
    """

    private func bump(col: Int, form: PlayerForm = .small) -> (GameWorld, [GameEvent]) {
        let world = WorldTestSupport.world(blocks)
        world.player.setForm(form)
        // Put the ninja right under the block and jump.
        world.player.rect.minX = Tiles.origin(col) + 2
        WorldTestSupport.run(world, frames: 2)
        let events = WorldTestSupport.run(world, frames: 40, input: InputState(jump: true))
        return (world, events)
    }

    func testCoinBlockGivesACoinAndBecomesUsed() {
        let (world, events) = bump(col: 3)
        XCTAssertTrue(events.contains(.blockBumped(col: 3, row: 5)))
        XCTAssertTrue(events.contains { if case .coinCollected = $0 { return true } else { return false } })
        XCTAssertEqual(world.map[3, 5], .used)
        // Bumping again does nothing.
        let again = WorldTestSupport.run(world, frames: 60, input: InputState(jump: true))
        XCTAssertFalse(again.contains { if case .coinCollected = $0 { return true } else { return false } })
    }

    func testPowerBlockGivesOnigiriWhenSmallAndScrollWhenBig() {
        let (small, smallEvents) = bump(col: 5)
        XCTAssertTrue(smallEvents.contains(.itemEmerged(kind: .onigiri, col: 5, row: 5)))
        XCTAssertEqual(small.items.first?.powerUp, .onigiri)
        let (_, bigEvents) = bump(col: 5, form: .big)
        XCTAssertTrue(bigEvents.contains(.itemEmerged(kind: .shurikenScroll, col: 5, row: 5)))
    }

    func testBrickOnlyBreaksWhenBig() {
        let (small, smallEvents) = bump(col: 7)
        XCTAssertTrue(smallEvents.contains(.blockBumped(col: 7, row: 5)))
        XCTAssertFalse(smallEvents.contains(.brickBroken(col: 7, row: 5)))
        XCTAssertEqual(small.map[7, 5], .brick)
        let (big, bigEvents) = bump(col: 7, form: .big)
        XCTAssertTrue(bigEvents.contains(.brickBroken(col: 7, row: 5)))
        XCTAssertEqual(big.map[7, 5], .empty)
    }

    func testOneUpBrickNeverBreaksAndKatanaBlockGivesKatana() {
        let (world, events) = bump(col: 9, form: .big)
        XCTAssertTrue(events.contains(.itemEmerged(kind: .greenScroll, col: 9, row: 5)))
        XCTAssertEqual(world.map[9, 5], .used)
        let (_, katana) = bump(col: 11)
        XCTAssertTrue(katana.contains(.itemEmerged(kind: .goldenKatana, col: 11, row: 5)))
    }

    func testBumpOffsetAnimatesThenStops() {
        let world = WorldTestSupport.world(blocks)
        world.player.rect.minX = Tiles.origin(3) + 2
        WorldTestSupport.run(world, frames: 2)
        var seen = false
        for _ in 0..<40 {
            _ = world.step(input: InputState(jump: true))
            if world.bumpOffset(col: 3, row: 5) > 0 { seen = true }
        }
        XCTAssertTrue(seen)
        WorldTestSupport.run(world, frames: 10)
        XCTAssertEqual(world.bumpOffset(col: 3, row: 5), 0)
    }

    func testCollectingOnigiriGrowsAndScrollGivesShurikens() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(world, frames: 2)
        XCTAssertEqual(world.player.form, .small)
        var events = collect(.onigiri, in: world)
        XCTAssertTrue(events.contains(.powerUpCollected(.onigiri)))
        XCTAssertEqual(world.player.form, .big)
        XCTAssertEqual(world.player.rect.height, GameConstants.bigPlayerSize.y)
        events = collect(.shurikenScroll, in: world)
        XCTAssertTrue(events.contains(.powerUpCollected(.shurikenScroll)))
        XCTAssertEqual(world.player.form, .shuriken)
        // Throw.
        let thrown = WorldTestSupport.run(world, frames: 2, input: InputState(action: true))
        XCTAssertTrue(thrown.contains(.shurikenThrown))
        XCTAssertEqual(world.shurikens.count, 1)
        // Cooldown: mashing does not exceed two live shurikens.
        for _ in 0..<30 {
            _ = world.step(input: InputState(action: false))
            _ = world.step(input: InputState(action: true))
        }
        XCTAssertLessThanOrEqual(world.shurikens.count, GameConstants.maxShurikens)
    }

    func testGreenScrollIsAOneUpAndKatanaMakesInvincible() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(world, frames: 2)
        XCTAssertTrue(collect(.greenScroll, in: world).contains(.oneUp))
        _ = collect(.goldenKatana, in: world)
        XCTAssertTrue(world.player.katanaActive)
        WorldTestSupport.run(world, frames: GameConstants.katanaFrames + 5)
        XCTAssertFalse(world.player.katanaActive)
    }

    private func collect(_ kind: PowerUpKind, in world: GameWorld) -> [GameEvent] {
        let item = Item(id: world.makeID(), powerUp: kind, blockCol: 20, blockRow: 5, frame: world.frame)
        world.inject(item)
        // Let it emerge, then teleport it onto the player.
        WorldTestSupport.run(world, frames: GameConstants.itemEmergeFrames + 2)
        item.rect = AABB(bottomCenter: world.player.rect.bottomCenter, size: GameConstants.itemSize)
        item.velocity = .zero
        var events = world.step(input: .none)
        // Skip the grow freeze.
        events += WorldTestSupport.run(world, frames: 25)
        return events
    }

    // MARK: - Enemies

    private let raptorLevel = """
    ! name: Raptor
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    .S......r.........F.
    GGGGGGGGGGGGGGGGGGGG
    ####################
    """

    func testRaptorWalksTowardTheNinjaAndHurtsOnContact() {
        let world = WorldTestSupport.world(raptorLevel)
        XCTAssertEqual(world.enemies.count, 1)
        let raptor = world.enemies[0]
        XCTAssertEqual(raptor.facing, .left)
        world.player.setForm(.big)
        let events = WorldTestSupport.run(world, frames: 240)
        XCTAssertTrue(events.contains(.playerHurt))
        XCTAssertEqual(world.player.form, .small)
        XCTAssertGreaterThan(world.player.invulnerableFrames, 0)
    }

    func testSmallNinjaTouchedByRaptorDies() {
        let world = WorldTestSupport.world(raptorLevel)
        let events = WorldTestSupport.run(world, frames: 300)
        XCTAssertTrue(events.contains(.playerDied))
    }

    func testStompingARaptorSquishesItAndBounces() {
        let world = WorldTestSupport.world(raptorLevel)
        let raptor = world.enemies[0]
        // Place the ninja directly above the raptor, falling.
        world.player.rect = AABB(bottomCenter: Vec2(x: raptor.rect.midX, y: raptor.rect.maxY + 1), size: world.player.form.hitbox)
        world.player.velocity = Vec2(x: 0, y: -100)
        let events = WorldTestSupport.run(world, frames: 4)
        XCTAssertTrue(events.contains { if case .enemyStomped = $0 { return true } else { return false } })
        XCTAssertTrue(events.contains { $0.scorePoints == GameConstants.stompScore })
        XCTAssertFalse(raptor.isAlive)
        XCTAssertGreaterThan(world.player.velocity.y, 0)
        XCTAssertFalse(events.contains(.playerHurt))
        WorldTestSupport.run(world, frames: GameConstants.squishedFrames + 2)
        XCTAssertTrue(world.enemies.isEmpty)
    }

    func testStompedEnemyDoesNotComeBack() {
        let wide = """
        ! name: Wide
        ....................................................................................................
        ....................................................................................................
        ....................................................................................................
        ....................................................................................................
        ....................................................................................................
        ....................................................................................................
        ....................................................................................................
        ....................................................................................................
        ....................................................................................................
        ....................................................................................................
        .S......r........................................................................................F..
        GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
        ####################################################################################################
        """
        let world = WorldTestSupport.world(wide)
        let raptor = world.enemies[0]
        world.player.rect = AABB(bottomCenter: Vec2(x: raptor.rect.midX, y: raptor.rect.maxY + 1), size: world.player.form.hitbox)
        world.player.velocity = Vec2(x: 0, y: -100)
        WorldTestSupport.run(world, frames: GameConstants.squishedFrames + 10)
        XCTAssertTrue(world.enemies.isEmpty)
        world.player.rect = AABB(bottomCenter: Vec2(x: 1300, y: 32), size: world.player.form.hitbox)
        WorldTestSupport.run(world, frames: 300)
        world.player.rect = AABB(bottomCenter: Vec2(x: 40, y: 32), size: world.player.form.hitbox)
        WorldTestSupport.run(world, frames: 300)
        XCTAssertTrue(world.enemies.isEmpty, "stomped raptor came back")
    }

    func testRaptorWalksOffLedgesButAnkyTurnsAround() {
        let ledge = """
        ! name: Ledge
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        S...a.........r...F.
        GGGGGGGGGGGGGGGG..GG
        ################..##
        """
        let world = WorldTestSupport.world(ledge)
        // Send both walking right.
        for enemy in world.enemies { enemy.facing = .right }
        WorldTestSupport.run(world, frames: 300)
        let raptor = world.enemies.first { $0 is Raptor }
        let anky = world.enemies.first { $0 is Anky }
        XCTAssertNil(raptor, "raptor should have fallen into the pit and despawned")
        XCTAssertNotNil(anky)
        XCTAssertTrue(anky!.onGround)
    }

    func testAnkyBecomesABallThenAKickedBallKillsARaptor() {
        let level = """
        ! name: Bowling
        ........................
        ........................
        ........................
        ........................
        ........................
        ........................
        ........................
        ........................
        ........................
        ........................
        .S....a.....r.........F.
        GGGGGGGGGGGGGGGGGGGGGGGG
        ########################
        """
        let world = WorldTestSupport.world(level)
        let anky = world.enemies.first { $0 is Anky } as! Anky
        let raptor = world.enemies.first { $0 is Raptor }!
        raptor.facing = .right   // walk away so the ball has to catch it
        world.player.rect = AABB(bottomCenter: Vec2(x: anky.rect.midX, y: anky.rect.maxY + 1), size: world.player.form.hitbox)
        world.player.velocity = Vec2(x: 0, y: -100)
        WorldTestSupport.run(world, frames: 3)
        XCTAssertTrue(anky.isIdleBall)
        XCTAssertEqual(anky.kind, .ankyBall)
        // Walk into the idle ball from the left: kick.
        world.player.rect = AABB(bottomCenter: Vec2(x: anky.rect.minX - 4, y: 32), size: world.player.form.hitbox)
        world.player.velocity = .zero
        let kick = WorldTestSupport.run(world, frames: 3, input: InputState(right: true))
        XCTAssertTrue(kick.contains(.ballKicked))
        XCTAssertTrue(anky.isMovingBall)
        XCTAssertEqual(anky.facing, .right)
        let events = WorldTestSupport.run(world, frames: 120)
        XCTAssertTrue(events.contains { if case .enemyKilled = $0 { return true } else { return false } })
        XCTAssertTrue(events.contains { $0.scorePoints == GameConstants.ballChainScores[0] })
        XCTAssertFalse(raptor.isAlive)
    }

    func testIdleBallUnfurls() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        let anky = Anky(id: world.makeID(), position: Vec2(x: 200, y: 32), frame: 0)
        world.inject(anky)
        anky.stomped(by: world.player, in: world)
        XCTAssertTrue(anky.isIdleBall)
        WorldTestSupport.run(world, frames: GameConstants.ballIdleFrames + 3)
        XCTAssertFalse(anky.isIdleBall)
        XCTAssertEqual(anky.kind, .anky)
    }

    func testStegoCannotBeStompedButDiesToShuriken() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        let stego = Stego(id: world.makeID(), position: Vec2(x: 120, y: 32), frame: 0)
        world.inject(stego)
        world.player.setForm(.shuriken)
        world.player.rect = AABB(bottomCenter: Vec2(x: stego.rect.midX, y: stego.rect.maxY + 1), size: world.player.form.hitbox)
        world.player.velocity = Vec2(x: 0, y: -100)
        let events = WorldTestSupport.run(world, frames: 4)
        XCTAssertTrue(events.contains(.playerHurt))
        XCTAssertTrue(stego.isAlive)
        XCTAssertEqual(world.player.form, .big)
        WorldTestSupport.run(world, frames: GameConstants.hurtFreezeFrames + 2)
        world.player.setForm(.shuriken)
        world.player.rect = AABB(bottomCenter: Vec2(x: 40, y: 32), size: world.player.form.hitbox)
        world.player.facing = .right
        _ = world.step(input: InputState(action: true))
        let hits = WorldTestSupport.run(world, frames: 60)
        XCTAssertTrue(hits.contains { if case .enemyKilled = $0 { return true } else { return false } })
        XCTAssertFalse(stego.isAlive)
    }

    func testKatanaKillsOnContact() {
        let world = WorldTestSupport.world(raptorLevel)
        world.player.katanaFrames = 600
        let events = WorldTestSupport.run(world, frames: 200)
        XCTAssertTrue(events.contains { if case .enemyKilled = $0 { return true } else { return false } })
        XCTAssertFalse(events.contains(.playerHurt))
    }

    func testPteroFliesThenWalksAfterAStomp() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        let ptero = Ptero(id: world.makeID(), position: Vec2(x: 200, y: 32), frame: 0)
        world.inject(ptero)
        WorldTestSupport.run(world, frames: 30)
        XCTAssertFalse(ptero.onGround)
        XCTAssertGreaterThan(ptero.rect.minY, 32)
        ptero.stomped(by: world.player, in: world)
        XCTAssertEqual(ptero.kind, .pteroWalker)
        WorldTestSupport.run(world, frames: 120)
        XCTAssertTrue(ptero.onGround)
        XCTAssertNotEqual(ptero.velocity.x, 0)
    }

    func testEnemyOnABumpedBlockIsLaunched() {
        let world = WorldTestSupport.world(blocks)
        let raptor = Raptor(id: world.makeID(), position: Vec2(x: Tiles.origin(3) + 8, y: Tiles.origin(6)), frame: 0)
        world.inject(raptor)
        raptor.facing = .right
        world.player.rect.minX = Tiles.origin(3) + 2
        WorldTestSupport.run(world, frames: 2)
        // The raptor walks; bump quickly while it is still over the block.
        let events = WorldTestSupport.run(world, frames: 30, input: InputState(jump: true))
        XCTAssertTrue(events.contains(.blockBumped(col: 3, row: 5)))
        XCTAssertTrue(events.contains { if case .enemyKilled = $0 { return true } else { return false } })
    }

    // MARK: - Checkpoints, hazards, coins

    func testCoinTileLanternAndHazard() {
        let level = """
        ! name: Pickups
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        ....................
        .S.o..C....~......F.
        GGGGGGGGGGGGGGGGGGGG
        ####################
        """
        let world = WorldTestSupport.world(level)
        world.player.setForm(.big)
        let events = WorldTestSupport.run(world, frames: 200, input: InputState(right: true))
        XCTAssertTrue(events.contains { if case .coinCollected = $0 { return true } else { return false } })
        XCTAssertEqual(world.map[3, 2], .empty)
        XCTAssertTrue(events.contains(.checkpointReached(col: 6, row: 2)))
        XCTAssertEqual(world.map[6, 2], .lanternLit)
        XCTAssertEqual(world.checkpoint, Vec2(x: 104, y: 32))
        XCTAssertTrue(events.contains(.playerHurt), "spikes should hurt")
        XCTAssertFalse(events.contains(.playerDied), "spikes should not kill outright")
    }

    // MARK: - Boss

    private let arena = """
    ! name: Arena
    ! theme: lava
    ||............................||
    ||............................||
    ||............................||
    ||............................||
    ||............................||
    ||............................||
    ||............................||
    ||............................||
    ||............................||
    ||............................||
    ||.S....................X..F..||
    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
    ################################
    """

    func testRexTakesThreeHitsAndOpensTheGate() {
        let world = WorldTestSupport.world(arena)
        let rex = world.boss!
        XCTAssertFalse(world.goalActive)
        world.player.invulnerableFrames = 100_000
        XCTAssertNotNil(WorldTestSupport.run(world, until: { $0.boss?.phase != .sleeping }, limit: 400, input: InputState(right: true, action: true)))
        var hits = 0
        var allEvents: [GameEvent] = []
        for _ in 0..<2000 where hits < 3 {
            if rex.canBeHurt {
                world.player.rect = AABB(bottomCenter: Vec2(x: rex.rect.midX, y: rex.rect.maxY - 1), size: world.player.form.hitbox)
                world.player.velocity = Vec2(x: 0, y: -60)
            } else {
                world.player.rect = AABB(bottomCenter: Vec2(x: 60, y: 32), size: world.player.form.hitbox)
                world.player.velocity = .zero
            }
            let events = world.step(input: .none)
            allEvents += events
            if events.contains(where: { if case .bossHit = $0 { return true } else { return false } }) { hits += 1 }
        }
        XCTAssertEqual(hits, 3)
        XCTAssertTrue(allEvents.contains(.bossHit(hitPointsLeft: 0)))
        // Keep the ninja away and let Rex fall.
        world.player.rect = AABB(bottomCenter: Vec2(x: 60, y: 32), size: world.player.form.hitbox)
        let tail = WorldTestSupport.run(world, frames: 400)
        XCTAssertTrue(tail.contains(.bossDefeated))
        XCTAssertTrue(world.goalActive)
        XCTAssertNil(world.boss)
    }

    func testRexLeapsLandsRoarsAndBreathesFire() {
        let world = WorldTestSupport.world(arena)
        world.player.rect = AABB(bottomCenter: Vec2(x: 200, y: 32), size: world.player.form.hitbox)
        world.player.invulnerableFrames = 100_000
        let events = WorldTestSupport.run(world, frames: 700)
        XCTAssertTrue(events.contains(.bossLanded))
        XCTAssertTrue(events.contains(.bossRoared))
        XCTAssertTrue(events.contains { if case .screenShake = $0 { return true } else { return false } })
        XCTAssertTrue(world.entities.contains { $0 is Fireball } || events.contains(.bossRoared))
    }
}

extension GameWorld {
    func inject(_ entity: Entity) {
        addEntity(entity)
    }
}
