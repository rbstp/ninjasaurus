import XCTest
@testable import Ninjasaurus

final class PlayerPhysicsTests: XCTestCase {
    private func jumpApex(holdFrames: Int) -> Double {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(world, frames: 5)
        let floor = world.player.rect.minY
        var apex = floor
        for frame in 0..<90 {
            let held = frame < holdFrames
            _ = world.step(input: InputState(jump: held))
            apex = max(apex, world.player.rect.minY)
        }
        return apex - floor
    }

    func testStartsOnTheGround() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(world, frames: 3)
        XCTAssertTrue(world.player.onGround)
        XCTAssertEqual(world.player.rect.minY, 32, accuracy: 1e-9)
    }

    func testHeldJumpIsHigherThanTappedJump() {
        let held = jumpApex(holdFrames: 60)
        let tapped = jumpApex(holdFrames: 2)
        XCTAssertGreaterThan(held, 3.5 * GameConstants.tileSize)
        XCTAssertLessThan(held, 5 * GameConstants.tileSize)
        XCTAssertLessThan(tapped, 3 * GameConstants.tileSize)
        XCTAssertGreaterThan(tapped, 1.5 * GameConstants.tileSize)
    }

    func testJumpEmitsEventAndOnlyOnce() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(world, frames: 3)
        let events = WorldTestSupport.run(world, frames: 20, input: InputState(jump: true))
        XCTAssertEqual(events.filter { $0 == .playerJumped }.count, 1)
    }

    func testRunningIsFasterThanWalking() {
        let walker = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(walker, frames: 120, input: InputState(right: true))
        let runner = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(runner, frames: 120, input: InputState(right: true, action: true))
        XCTAssertEqual(walker.player.velocity.x, GameConstants.walkSpeed, accuracy: 1e-6)
        XCTAssertEqual(runner.player.velocity.x, GameConstants.runSpeed, accuracy: 1e-6)
        XCTAssertGreaterThan(runner.player.rect.minX, walker.player.rect.minX)
        XCTAssertEqual(runner.player.facing, .right)
    }

    func testTerminalVelocity() {
        let tall = """
        ! name: Drop
        S.F.
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        ....
        GGGG
        """
        let world = WorldTestSupport.world(tall)
        WorldTestSupport.run(world, frames: 40)
        XCTAssertEqual(world.player.velocity.y, -GameConstants.terminalVelocity, accuracy: 1e-6)
    }

    func testCoyoteTimeAllowsALateJump() {
        // Ledge: floor under cols 0-9 only, pit after.
        let ledge = """
        ! name: Ledge
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ........S...............F.
        GGGGGGGGGG..............GG
        ##########..............##
        """
        let world = WorldTestSupport.world(ledge)
        // Walk right until we leave the ledge.
        let left = WorldTestSupport.run(world, until: { !$0.player.onGround }, limit: 600, input: InputState(right: true))
        XCTAssertNotNil(left)
        // Wait a few frames in the air, then press jump within the coyote window.
        WorldTestSupport.run(world, frames: GameConstants.coyoteFrames - 2, input: InputState(right: true))
        let events = world.step(input: InputState(right: true, jump: true))
        XCTAssertTrue(events.contains(.playerJumped))
        XCTAssertGreaterThan(world.player.velocity.y, 0)
    }

    func testNoCoyoteJumpAfterTheWindow() {
        let ledge = """
        ! name: Ledge
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ..........................
        ........S...............F.
        GGGGGGGGGG..............GG
        ##########..............##
        """
        let world = WorldTestSupport.world(ledge)
        _ = WorldTestSupport.run(world, until: { !$0.player.onGround }, limit: 600, input: InputState(right: true))
        WorldTestSupport.run(world, frames: GameConstants.coyoteFrames + 2, input: InputState(right: true))
        let events = world.step(input: InputState(right: true, jump: true))
        XCTAssertFalse(events.contains(.playerJumped))
    }

    func testJumpBufferedBeforeLandingFiresOnLanding() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(world, frames: 3)
        _ = world.step(input: InputState(jump: true))
        // Release, wait until we are about to land.
        _ = WorldTestSupport.run(world, until: { $0.player.velocity.y < 0 && $0.player.rect.minY < 32 + 6 }, limit: 200)
        XCTAssertFalse(world.player.onGround)
        // Tap jump early (still in the air), then release.
        _ = world.step(input: InputState(jump: true))
        let events = WorldTestSupport.run(world, frames: GameConstants.jumpBufferFrames)
        XCTAssertTrue(events.contains(.playerJumped), "buffered jump did not fire on landing")
    }

    func testWalkingClearsAFourTilePit() {
        let pit = """
        ! name: Pit
        ..............................
        ..............................
        ..............................
        ..............................
        ..............................
        ..............................
        ..............................
        ..............................
        ..............................
        ..............................
        .S.........................F..
        GGGGGGGGGG....GGGGGGGGGGGGGGGG
        ##########....################
        """
        let world = WorldTestSupport.world(pit)
        // Walk and jump just before the edge.
        var jumped = false
        for _ in 0..<400 {
            let nearEdge = world.player.rect.maxX > 10 * 16 - 3
            let jump = nearEdge && !jumped
            if jump { jumped = true }
            _ = world.step(input: InputState(right: true, jump: jump || (jumped && world.player.velocity.y > 0)))
            if world.player.rect.minX > 15 * 16 { break }
        }
        XCTAssertTrue(world.isPlaying, "fell in the pit")
        XCTAssertGreaterThan(world.player.rect.minX, 14 * 16)
    }

    func testFallingInAPitKills() {
        let pit = """
        ! name: Pit
        ..........
        ..........
        ..........
        ..........
        ..........
        ..........
        ..........
        ..........
        ..........
        ..........
        .S......F.
        GG......GG
        ##......##
        """
        let world = WorldTestSupport.world(pit)
        let events = WorldTestSupport.run(world, frames: 240, input: InputState(right: true))
        XCTAssertTrue(events.contains(.playerDied))
        XCTAssertTrue(world.player.isDead)
        XCTAssertEqual(world.phase, .dead)
    }

    func testReachingTheGateClearsTheLevel() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        let events = WorldTestSupport.run(world, frames: 900, input: InputState(right: true, action: true))
        XCTAssertTrue(events.contains(.goalReached))
        XCTAssertTrue(events.contains(.levelCleared))
        XCTAssertEqual(world.phase, .cleared)
        XCTAssertTrue(events.contains { $0.scorePoints == GameConstants.levelClearScore })
    }

    func testIdleNinjaPlaysWithHisSwordThenStops() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        WorldTestSupport.run(world, frames: GameConstants.idleFramesBeforeSwordPlay - 5)
        XCTAssertEqual(world.player.animState, .idle)
        WorldTestSupport.run(world, frames: 10)
        XCTAssertEqual(world.player.animState, .swordPlay)
        WorldTestSupport.run(world, frames: GameConstants.swordPlayFrames)
        XCTAssertEqual(world.player.animState, .idle)
        WorldTestSupport.run(world, frames: GameConstants.idleFramesBeforeSwordPlay + 5)
        XCTAssertEqual(world.player.animState, .swordPlay)
        _ = world.step(input: InputState(right: true))
        XCTAssertNotEqual(world.player.animState, .swordPlay)
    }

    func testCameraFollowsAndClamps() {
        let world = WorldTestSupport.world(WorldTestSupport.flat)
        XCTAssertEqual(world.camera.x, 208, accuracy: 1e-9)   // clamped to the left edge (view 416 wide)
        XCTAssertEqual(world.camera.y, 104, accuracy: 1e-9)
        WorldTestSupport.run(world, frames: 700, input: InputState(right: true, action: true))
        XCTAssertLessThanOrEqual(world.camera.x, 640 - 208 + 1e-9)
        XCTAssertGreaterThan(world.camera.x, 300)
    }
}
