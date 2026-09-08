import XCTest
@testable import Ninjasaurus

final class TileColliderTests: XCTestCase {
    private func makeMap() -> TileMap {
        var map = TileMap(width: 10, height: 6)
        for col in 0..<10 { map[col, 0] = .groundTop }
        map[5, 1] = .fill
        map[5, 2] = .fill
        map[1, 4] = .brick
        map[2, 4] = .questionCoin
        map[8, 2] = .cloud
        return map
    }

    func testWalkingIntoAWallSnapsToItsEdge() {
        let map = makeMap()
        let rect = AABB(minX: 70, minY: 16, width: 12, height: 15)
        let result = TileCollider.moveX(rect, by: 2, in: map)
        XCTAssertTrue(result.hitWall)
        XCTAssertEqual(result.rect.maxX, 80, accuracy: 1e-9)

        let left = AABB(minX: 96, minY: 16, width: 12, height: 15)
        let back = TileCollider.moveX(left, by: -2, in: map)
        XCTAssertTrue(back.hitWall)
        XCTAssertEqual(back.rect.minX, 96, accuracy: 1e-9)
    }

    func testFreeMovementIsUnchanged() {
        let map = makeMap()
        let rect = AABB(minX: 20, minY: 16, width: 12, height: 15)
        let result = TileCollider.moveX(rect, by: 2.3, in: map)
        XCTAssertFalse(result.hitWall)
        XCTAssertEqual(result.rect.minX, 22.3, accuracy: 1e-9)
    }

    func testFallingLandsExactlyOnTheFloor() {
        let map = makeMap()
        let rect = AABB(minX: 20, minY: 17, width: 12, height: 15)
        let result = TileCollider.moveY(rect, by: -3, previous: rect, in: map)
        XCTAssertTrue(result.landed)
        XCTAssertEqual(result.rect.minY, 16, accuracy: 1e-9)
    }

    func testRestingOnTheFloorKeepsLandingEveryStep() {
        let map = makeMap()
        let rect = AABB(minX: 20, minY: 16, width: 12, height: 15)
        let result = TileCollider.moveY(rect, by: -0.26, previous: rect, in: map)
        XCTAssertTrue(result.landed)
        XCTAssertEqual(result.rect.minY, 16, accuracy: 1e-9)
    }

    func testCloudIsSolidFromAboveOnly() {
        let map = makeMap()
        let above = AABB(minX: 130, minY: 48.2, width: 12, height: 15)
        let landing = TileCollider.moveY(above, by: -1, previous: above, in: map)
        XCTAssertTrue(landing.landed)
        XCTAssertEqual(landing.rect.minY, 48, accuracy: 1e-9)

        let below = AABB(minX: 130, minY: 30, width: 12, height: 15)
        let rising = TileCollider.moveY(below, by: 4, previous: below, in: map)
        XCTAssertFalse(rising.hitCeiling)
        XCTAssertEqual(rising.rect.minY, 34, accuracy: 1e-9)

        // Passing upward through the cloud, then falling from inside it: no landing.
        let inside = AABB(minX: 130, minY: 40, width: 12, height: 15)
        let falling = TileCollider.moveY(inside, by: -1, previous: inside, in: map)
        XCTAssertFalse(falling.landed)

        let sideways = TileCollider.moveX(inside, by: 2, in: map)
        XCTAssertFalse(sideways.hitWall)
    }

    func testHeadBonkReportsSolidColumns() {
        let map = makeMap()
        // Player spans cols 1 and 2 under the bricks at row 4 (y 64-80).
        let rect = AABB(minX: 26, minY: 48, width: 12, height: 15)
        let result = TileCollider.moveY(rect, by: 2, previous: rect, in: map)
        XCTAssertTrue(result.hitCeiling)
        XCTAssertEqual(result.ceilingRow, 4)
        XCTAssertEqual(result.ceilingColumns, [1, 2])
        XCTAssertEqual(result.rect.maxY, 64, accuracy: 1e-9)
    }

    func testMapEdgesAreWalls() {
        let map = makeMap()
        let rect = AABB(minX: 0.5, minY: 16, width: 12, height: 15)
        let result = TileCollider.moveX(rect, by: -2, in: map)
        XCTAssertTrue(result.hitWall)
        XCTAssertEqual(result.rect.minX, 0, accuracy: 1e-9)
    }

    func testHasFloor() {
        let map = makeMap()
        XCTAssertTrue(TileCollider.hasFloor(x: 8, belowY: 16, in: map))
        XCTAssertFalse(TileCollider.hasFloor(x: 8, belowY: 40, in: map))
        XCTAssertTrue(TileCollider.hasFloor(x: 136, belowY: 48, in: map))
    }
}
