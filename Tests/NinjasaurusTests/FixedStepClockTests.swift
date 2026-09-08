import XCTest
@testable import Ninjasaurus

final class FixedStepClockTests: XCTestCase {
    func testFirstFrameRunsNoSteps() {
        var clock = FixedStepClock()
        XCTAssertEqual(clock.advance(to: 10), 0)
    }

    func testOneFrameIsOneStep() {
        var clock = FixedStepClock()
        _ = clock.advance(to: 0)
        XCTAssertEqual(clock.advance(to: 1.0 / 60.0), 1)
        XCTAssertEqual(clock.advance(to: 2.0 / 60.0), 1)
    }

    func testFractionalTimeAccumulates() {
        var clock = FixedStepClock()
        _ = clock.advance(to: 0)
        XCTAssertEqual(clock.advance(to: 0.05), 3)
        XCTAssertEqual(clock.accumulator, 0, accuracy: 1e-6)
        // 0.5 of a step left over, then 0.5 more completes one step.
        XCTAssertEqual(clock.advance(to: 0.05 + 0.5 / 60.0), 0)
        XCTAssertEqual(clock.advance(to: 0.05 + 1.0 / 60.0), 1)
    }

    func testHitchIsCapped() {
        var clock = FixedStepClock()
        _ = clock.advance(to: 0)
        XCTAssertEqual(clock.advance(to: 2.0), 4)
        XCTAssertEqual(clock.accumulator, 0)
        XCTAssertEqual(clock.advance(to: 2.0 + 1.0 / 60.0), 1)
    }

    func testResetForgetsTime() {
        var clock = FixedStepClock()
        _ = clock.advance(to: 0)
        _ = clock.advance(to: 0.5 / 60.0)
        clock.reset()
        XCTAssertEqual(clock.advance(to: 5), 0)
        XCTAssertEqual(clock.advance(to: 5 + 1.0 / 60.0), 1)
    }

    func testTimeGoingBackwardsIsIgnored() {
        var clock = FixedStepClock()
        _ = clock.advance(to: 1)
        XCTAssertEqual(clock.advance(to: 0.5), 0)
    }
}
