import Foundation

struct SaunaConfig: Codable, Equatable {
    var host: String
    var port: UInt16 = 502
    var name: String = "Sauna"
    var refreshInterval: Int = 15

    static var configURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/saunabar")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }

    static func load() -> SaunaConfig? {
        guard let data = try? Data(contentsOf: configURL) else { return nil }
        return try? JSONDecoder().decode(SaunaConfig.self, from: data)
    }

    func save() throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: Self.configURL, options: .atomic)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: configURL)
    }
}
