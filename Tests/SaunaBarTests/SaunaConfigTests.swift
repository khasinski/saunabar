import XCTest
@testable import SaunaBar

final class SaunaConfigTests: XCTestCase {

    func testDefaults() {
        let config = SaunaConfig(host: "192.168.0.50")
        XCTAssertEqual(config.port, 502)
        XCTAssertEqual(config.name, "Sauna")
        XCTAssertEqual(config.refreshInterval, 15)
    }

    func testCodableRoundTrip() throws {
        let original = SaunaConfig(host: "10.0.0.7", port: 1502, name: "Banya", refreshInterval: 30)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SaunaConfig.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testEquatable() {
        let a = SaunaConfig(host: "192.168.0.50")
        let b = SaunaConfig(host: "192.168.0.50")
        let c = SaunaConfig(host: "192.168.0.51")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
