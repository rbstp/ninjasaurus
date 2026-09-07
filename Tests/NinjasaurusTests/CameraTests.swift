import XCTest
@testable import Ninjasaurus

final class CameraTests: XCTestCase {
    private let view = Vec2(x: 416, y: 208)

    func testClampKeepsTheViewInsideTheLevel() {
        XCTAssertEqual(Camera.clamp(10, extent: 416, limit: 2000), 208)
        XCTAssertEqual(Camera.clamp(1990, extent: 416, limit: 2000), 1792)
        XCTAssertEqual(Camera.clamp(1000, extent: 416, limit: 2000), 1000)
        // Level smaller than the view: centre.
        XCTAssertEqual(Camera.clamp(50, extent: 416, limit: 300), 150)
    }

    func testLookaheadFollowsFacing() {
        let level = Vec2(x: 3000, y: 208)
        let player = AABB(minX: 1000, minY: 32, width: 12, height: 15)
        var cam = CameraState(x: 1006, y: 104)
        for _ in 0..<200 {
            cam = Camera.update(cam, playerRect: player, facing: .right, onGround: true, viewSize: view, levelSize: level)
        }
        XCTAssertEqual(cam.x, 1006 + GameConstants.cameraLookahead, accuracy: 0.5)
        for _ in 0..<200 {
            cam = Camera.update(cam, playerRect: player, facing: .left, onGround: true, viewSize: view, levelSize: level)
        }
        XCTAssertEqual(cam.x, 1006 - GameConstants.cameraLookahead, accuracy: 0.5)
    }

    func testShortLevelHasFixedVertical() {
        let level = Vec2(x: 3000, y: 208)
        let player = AABB(minX: 1000, minY: 150, width: 12, height: 15)
        let cam = Camera.update(CameraState(x: 1000, y: 104), playerRect: player, facing: .right, onGround: false, viewSize: view, levelSize: level)
        XCTAssertEqual(cam.y, 104)
    }

    func testTallLevelDeadZoneAndHardZone() {
        let level = Vec2(x: 3000, y: 320)
        var cam = CameraState(x: 1000, y: 160)
        // Small jump inside the dead zone while airborne: no movement.
        let hop = AABB(minX: 1000, minY: 180, width: 12, height: 15)
        cam = Camera.update(cam, playerRect: hop, facing: .right, onGround: false, viewSize: view, levelSize: level)
        XCTAssertEqual(cam.y, 160)
        // Far above the hard zone: snapped so the player stays within it.
        let high = AABB(minX: 1000, minY: 300, width: 12, height: 15)
        cam = Camera.update(cam, playerRect: high, facing: .right, onGround: false, viewSize: view, levelSize: level)
        XCTAssertEqual(cam.y, 320 - 104, accuracy: 1e-9) // clamped at the top of the level
        // Rounded output is integral.
        let rounded = CameraState(x: 10.4, y: 7.6).rounded
        XCTAssertEqual(rounded, CameraState(x: 10, y: 8))
    }
}
