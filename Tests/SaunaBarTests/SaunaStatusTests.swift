import XCTest
@testable import SaunaBar

final class SaunaStatusTests: XCTestCase {

    // MARK: - Session inactive

    func testFanRunningWhileOffIsVentilating() {
        let s = SaunaStatus(temp: 25, target: 65, sessionActive: false, fanActive: true)
        XCTAssertEqual(s, .ventilating)
    }

    func testWarmButOffIsCooling() {
        let s = SaunaStatus(temp: 40, target: 65, sessionActive: false, fanActive: false)
        XCTAssertEqual(s, .cooling)
    }

    func testCoolingBoundaryAt30() {
        XCTAssertEqual(SaunaStatus(temp: 30, target: 65, sessionActive: false, fanActive: false), .cooling)
        XCTAssertEqual(SaunaStatus(temp: 29, target: 65, sessionActive: false, fanActive: false), .idle)
    }

    func testColdAndOffIsIdle() {
        let s = SaunaStatus(temp: 20, target: 65, sessionActive: false, fanActive: false)
        XCTAssertEqual(s, .idle)
    }

    // MARK: - Session active

    func testAtOrAboveTargetIsReady() {
        XCTAssertEqual(SaunaStatus(temp: 65, target: 65, sessionActive: true, fanActive: false), .ready)
        XCTAssertEqual(SaunaStatus(temp: 70, target: 65, sessionActive: true, fanActive: false), .ready)
    }

    func testWithinFiveDegreesIsAlmostReady() {
        // max(30, target - 5) == 60
        XCTAssertEqual(SaunaStatus(temp: 60, target: 65, sessionActive: true, fanActive: false), .almostReady)
        XCTAssertEqual(SaunaStatus(temp: 64, target: 65, sessionActive: true, fanActive: false), .almostReady)
    }

    func testBelowAlmostReadyWindowIsWarming() {
        XCTAssertEqual(SaunaStatus(temp: 59, target: 65, sessionActive: true, fanActive: false), .warming)
        XCTAssertEqual(SaunaStatus(temp: 35, target: 65, sessionActive: true, fanActive: false), .warming)
    }

    func testColdButHeatingIsWarming() {
        let s = SaunaStatus(temp: 18, target: 65, sessionActive: true, fanActive: false)
        XCTAssertEqual(s, .warming)
    }

    func testLowTargetClampsAlmostReadyFloorTo30() {
        // target 33 -> max(30, 28) == 30, so temp 30 is almostReady, not warming
        XCTAssertEqual(SaunaStatus(temp: 30, target: 33, sessionActive: true, fanActive: false), .almostReady)
    }

    // MARK: - Presentation metadata stays consistent

    func testEveryStatusHasNonEmptyLabelAndIcon() {
        let all: [SaunaStatus] = [.unknown, .idle, .cooling, .ventilating, .warming, .almostReady, .ready]
        for status in all {
            XCTAssertFalse(status.label.isEmpty, "label empty for \(status)")
            XCTAssertFalse(status.icon.isEmpty, "icon empty for \(status)")
        }
    }
}
