import XCTest
@testable import SaunaBar

final class SaunaAlarmTests: XCTestCase {

    func testAllSixAlarmsAreDefined() {
        XCTAssertEqual(SaunaAlarm.allCases.count, 6)
    }

    func testEveryAlarmHasNonEmptyLabel() {
        for alarm in SaunaAlarm.allCases {
            XCTAssertFalse(alarm.label.isEmpty, "empty label for \(alarm)")
        }
    }

    func testAlarmLabelsAreLocalized() {
        Localizer.shared.language = .polish
        XCTAssertEqual(SaunaAlarm.thermalCutoff.label, "Termik")
        Localizer.shared.language = .english
        XCTAssertEqual(SaunaAlarm.thermalCutoff.label, "Thermal cutoff")
        Localizer.shared.language = .english
    }

    func testAlarmIdentityMatchesSelf() {
        for alarm in SaunaAlarm.allCases {
            XCTAssertEqual(alarm.id, alarm)
        }
    }
}
