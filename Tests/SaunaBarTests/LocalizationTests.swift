import XCTest
@testable import SaunaBar

final class LocalizationTests: XCTestCase {

    override func tearDown() {
        // Leave the shared localizer in a known state for other suites.
        Localizer.shared.language = .english
        super.tearDown()
    }

    func testEveryKeyIsTranslatedInBothLanguages() {
        for key in LKey.allCases {
            XCTAssertNotNil(Localizer.pl[key], "missing Polish translation for \(key)")
            XCTAssertNotNil(Localizer.en[key], "missing English translation for \(key)")
        }
    }

    func testNoTranslationIsEmpty() {
        for key in LKey.allCases {
            XCTAssertFalse(Localizer.pl[key]?.isEmpty ?? true, "empty Polish value for \(key)")
            XCTAssertFalse(Localizer.en[key]?.isEmpty ?? true, "empty English value for \(key)")
        }
    }

    func testTablesHaveIdenticalKeySets() {
        XCTAssertEqual(Set(Localizer.pl.keys), Set(Localizer.en.keys))
        XCTAssertEqual(Localizer.pl.count, LKey.allCases.count)
    }

    func testLanguageSwitchChangesOutput() {
        let loc = Localizer.shared
        loc.language = .polish
        XCTAssertEqual(loc.t(.settings), "Ustawienia")
        loc.language = .english
        XCTAssertEqual(loc.t(.settings), "Settings")
    }

    func testIntegerInterpolation() {
        let loc = Localizer.shared
        loc.language = .english
        XCTAssertEqual(loc.t(.tempReached, 80), "Temperature reached 80°C")
        loc.language = .polish
        XCTAssertEqual(loc.t(.tempReached, 80), "Temperatura osiągnęła 80°C")
    }

    func testStringInterpolation() {
        let loc = Localizer.shared
        loc.language = .english
        XCTAssertEqual(loc.t(.refreshedAt, "23:46"), "Refreshed at 23:46")
        XCTAssertTrue(loc.t(.scanningSubnet, "192.168.0").contains("192.168.0"))
    }

    func testEveryLanguageHasDisplayName() {
        for lang in AppLanguage.allCases {
            XCTAssertFalse(lang.displayName.isEmpty)
        }
    }
}
