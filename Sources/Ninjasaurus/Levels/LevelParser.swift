enum LevelParseError: Error, Equatable {
    case emptyLevel
    case raggedRow(line: Int)
    case unknownCharacter(Character, line: Int)
    case unknownTheme(String)
    case missingStart
    case multipleStarts
    case missingGoal
    case multipleGoals
}

enum LevelParser {
    private static let enemyMarkers: [Character: EnemyKind] = ["r": .raptor, "a": .anky, "p": .ptero, "s": .stego]

    static func parse(_ text: String) throws -> LevelDefinition {
        var name = "Untitled"
        var theme = Theme.grass
        var rows: [(line: Int, text: String)] = []

        for (index, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if line.hasPrefix("!") {
                let body = line.dropFirst().trimmingCharacters(in: .whitespaces)
                guard let colon = body.firstIndex(of: ":") else { continue }
                let key = body[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
                let value = body[body.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                switch key {
                case "name": name = value
                case "theme":
                    guard let parsed = Theme(rawValue: value.lowercased()) else { throw LevelParseError.unknownTheme(value) }
                    theme = parsed
                default: break
                }
                continue
            }
            rows.append((line: index + 1, text: line))
        }

        guard let first = rows.first else { throw LevelParseError.emptyLevel }
        let width = first.text.count
        let height = rows.count
        var map = TileMap(width: width, height: height)
        var start: Vec2?
        var goal: AABB?
        var boss: Vec2?
        var spawns: [EnemySpawn] = []

        for (rowIndex, row) in rows.enumerated() {
            guard row.text.count == width else { throw LevelParseError.raggedRow(line: row.line) }
            let mapRow = height - 1 - rowIndex
            for (col, char) in row.text.enumerated() {
                if let kind = TileKind.legend[char] {
                    map[col, mapRow] = kind
                    continue
                }
                let bottomCenter = Vec2(x: Tiles.origin(col) + GameConstants.tileSize / 2, y: Tiles.origin(mapRow))
                switch char {
                case "S":
                    guard start == nil else { throw LevelParseError.multipleStarts }
                    start = bottomCenter
                case "F":
                    guard goal == nil else { throw LevelParseError.multipleGoals }
                    goal = AABB(minX: Tiles.origin(col), minY: Tiles.origin(mapRow), width: 2 * GameConstants.tileSize, height: 3 * GameConstants.tileSize)
                case "X":
                    boss = bottomCenter
                default:
                    guard let kind = enemyMarkers[char] else { throw LevelParseError.unknownCharacter(char, line: row.line) }
                    spawns.append(EnemySpawn(kind: kind, col: col, row: mapRow))
                }
            }
        }

        guard let playerStart = start else { throw LevelParseError.missingStart }
        guard let goalRect = goal else { throw LevelParseError.missingGoal }
        spawns.sort { $0.col < $1.col }
        return LevelDefinition(name: name, theme: theme, map: map, playerStart: playerStart, spawns: spawns, goal: goalRect, bossSpawn: boss)
    }
}
