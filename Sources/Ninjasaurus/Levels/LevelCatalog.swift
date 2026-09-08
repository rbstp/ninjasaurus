import Foundation

enum LevelLoadError: Error {
    case missingFile(String)
}

enum LevelCatalog {
    static let ids = ["1-1", "1-2", "1-3", "1-4"]

    static var count: Int { ids.count }

    static func load(index: Int, bundle: Bundle = .main) throws -> LevelDefinition {
        try load(id: ids[index], bundle: bundle)
    }

    static func load(id: String, bundle: Bundle = .main) throws -> LevelDefinition {
        guard let url = bundle.url(forResource: id, withExtension: "txt", subdirectory: "Levels")
            ?? bundle.url(forResource: id, withExtension: "txt") else {
            throw LevelLoadError.missingFile(id)
        }
        let text = try String(contentsOf: url, encoding: .utf8)
        return try LevelParser.parse(text)
    }
}
