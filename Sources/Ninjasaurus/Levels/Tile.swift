enum Theme: String, Sendable, CaseIterable {
    case grass
    case cave
    case sky
    case lava
}

enum TileKind: UInt8, Sendable, CaseIterable {
    case empty
    case groundTop      // G: grass top (cave stone top / cloud block in other themes)
    case fill           // #: dirt / rock under the top
    case brick          // =
    case questionCoin   // ?
    case questionPower  // M
    case questionKatana // *
    case brickOneUp     // +
    case used
    case logCap         // L
    case logBody        // l
    case cloud          // ^: one-way platform
    case coin           // o
    case hazard         // ~: spikes or lava, hurts
    case lantern        // C: checkpoint
    case lanternLit
    case wall           // |: big stone blocks (boss arena)

    var isSolid: Bool {
        switch self {
        case .empty, .cloud, .coin, .hazard, .lantern, .lanternLit: return false
        default: return true
        }
    }

    var isOneWay: Bool { self == .cloud }

    var isBumpable: Bool {
        switch self {
        case .brick, .questionCoin, .questionPower, .questionKatana, .brickOneUp: return true
        default: return false
        }
    }

    var isBreakable: Bool { self == .brick }
    var isHazard: Bool { self == .hazard }
    var isCoin: Bool { self == .coin }

    static let legend: [Character: TileKind] = [
        ".": .empty, "G": .groundTop, "#": .fill, "=": .brick, "?": .questionCoin, "M": .questionPower,
        "*": .questionKatana, "+": .brickOneUp, "L": .logCap, "l": .logBody, "^": .cloud, "o": .coin,
        "~": .hazard, "C": .lantern, "|": .wall,
    ]
}

struct TileCoord: Hashable, Sendable {
    var col: Int
    var row: Int
}

struct TileMap: Equatable, Sendable {
    let width: Int
    let height: Int
    private var tiles: [TileKind]

    init(width: Int, height: Int, fill: TileKind = .empty) {
        self.width = width
        self.height = height
        tiles = Array(repeating: fill, count: width * height)
    }

    subscript(col: Int, row: Int) -> TileKind {
        get {
            if col < 0 || col >= width { return .wall }
            if row < 0 || row >= height { return .empty }
            return tiles[row * width + col]
        }
        set {
            guard col >= 0, col < width, row >= 0, row < height else { return }
            tiles[row * width + col] = newValue
        }
    }

    subscript(coord: TileCoord) -> TileKind {
        get { self[coord.col, coord.row] }
        set { self[coord.col, coord.row] = newValue }
    }

    var pixelWidth: Double { Double(width) * GameConstants.tileSize }
    var pixelHeight: Double { Double(height) * GameConstants.tileSize }

    func contains(col: Int, row: Int) -> Bool {
        col >= 0 && col < width && row >= 0 && row < height
    }

    static func rect(col: Int, row: Int) -> AABB {
        AABB(minX: Tiles.origin(col), minY: Tiles.origin(row), width: GameConstants.tileSize, height: GameConstants.tileSize)
    }
}
