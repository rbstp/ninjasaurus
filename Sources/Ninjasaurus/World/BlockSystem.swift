struct BlockSystem: Sendable {
    enum Outcome: Equatable, Sendable {
        case none
        case coin
        case spawnItem(PowerUpKind)
        case broke
    }

    static let bumpOffsets: [Double] = [2, 4, 6, 7, 6, 4, 2, 0]

    private(set) var bumps: [TileCoord: Int] = [:]

    mutating func bump(col: Int, row: Int, map: inout TileMap, form: PlayerForm, frame: Int, roll: Double = 1) -> Outcome {
        let kind = map[col, row]
        guard kind.isBumpable else { return .none }
        let coord = TileCoord(col: col, row: row)
        switch kind {
        case .questionCoin:
            map[coord] = .used
            bumps[coord] = frame
            return .coin
        case .questionPower:
            map[coord] = .used
            bumps[coord] = frame
            return .spawnItem(form == .small && roll >= 0.25 ? .onigiri : .shurikenScroll)
        case .questionKatana:
            map[coord] = .used
            bumps[coord] = frame
            return .spawnItem(.goldenKatana)
        case .brickOneUp:
            map[coord] = .used
            bumps[coord] = frame
            return .spawnItem(.greenScroll)
        case .brick:
            if form == .small {
                bumps[coord] = frame
                return .none
            }
            map[coord] = .empty
            return .broke
        default:
            return .none
        }
    }

    mutating func tick(frame: Int) {
        bumps = bumps.filter { frame - $0.value < BlockSystem.bumpOffsets.count }
    }

    func offset(col: Int, row: Int, frame: Int) -> Double {
        guard let start = bumps[TileCoord(col: col, row: row)] else { return 0 }
        let index = frame - start
        guard index >= 0, index < BlockSystem.bumpOffsets.count else { return 0 }
        return BlockSystem.bumpOffsets[index]
    }

    var activeCoordinates: [TileCoord] { Array(bumps.keys) }
}
