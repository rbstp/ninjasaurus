enum EnemyKind: Sendable, Equatable, CaseIterable {
    case raptor
    case anky
    case ptero
    case stego
}

struct EnemySpawn: Equatable, Sendable {
    var kind: EnemyKind
    var col: Int
    var row: Int

    var position: Vec2 {
        Vec2(x: Tiles.origin(col) + GameConstants.tileSize / 2, y: Tiles.origin(row))
    }
}

struct LevelDefinition: Equatable, Sendable {
    var name: String
    var theme: Theme
    var map: TileMap
    var playerStart: Vec2
    var spawns: [EnemySpawn]
    var goal: AABB
    var bossSpawn: Vec2?

    var pixelSize: Vec2 { Vec2(x: map.pixelWidth, y: map.pixelHeight) }
    var hasBoss: Bool { bossSpawn != nil }
}
