import SpriteKit

@MainActor
final class TileLayer {
    private let textures: TextureStore
    private let parent: SKNode
    private let theme: Theme
    private var nodes: [TileCoord: SKSpriteNode] = [:]
    private var animated: Set<TileCoord> = []
    private var bumped: Set<TileCoord> = []
    private var columns: ClosedRange<Int>?

    init(textures: TextureStore, parent: SKNode, theme: Theme) {
        self.textures = textures
        self.parent = parent
        self.theme = theme
    }

    static func spriteName(for kind: TileKind, theme: Theme, frame: Int) -> String? {
        switch kind {
        case .empty: return nil
        case .groundTop: return "tile.\(theme.rawValue).groundTop"
        case .fill: return "tile.\(theme.rawValue).fill"
        case .brick, .brickOneUp: return "tile.brick"
        case .questionCoin, .questionPower, .questionKatana:
            let blink = [1, 1, 1, 1, 2, 3, 2][(frame / 8) % 7]
            return "tile.question\(blink)"
        case .used: return "tile.used"
        case .logCap: return "tile.logCap"
        case .logBody: return "tile.logBody"
        case .cloud: return "tile.cloud"
        case .coin: return "tile.coin\(1 + (frame / 6) % 4)"
        case .hazard: return theme == .lava ? "tile.hazard.lava\(1 + (frame / 16) % 2)" : "tile.hazard.spikes"
        case .lantern: return "tile.lantern"
        case .lanternLit: return "tile.lanternLit"
        case .wall: return "tile.wall"
        }
    }

    private static func isAnimated(_ kind: TileKind) -> Bool {
        switch kind {
        case .questionCoin, .questionPower, .questionKatana, .coin: return true
        case .hazard: return true
        default: return false
        }
    }

    func sync(world: GameWorld) {
        let view = world.cameraRect
        let first = max(0, Tiles.index(view.minX) - 2)
        let last = min(world.map.width - 1, Tiles.index(view.maxX) + 2)
        guard first <= last else { return }
        let wanted = first...last
        if wanted != columns {
            if let current = columns {
                for col in current where !wanted.contains(col) {
                    removeColumn(col, height: world.map.height)
                }
                for col in wanted where !current.contains(col) {
                    addColumn(col, world: world)
                }
            } else {
                for col in wanted { addColumn(col, world: world) }
            }
            columns = wanted
        }
        for coord in animated {
            guard let node = nodes[coord], let name = TileLayer.spriteName(for: world.map[coord], theme: theme, frame: world.frame) else { continue }
            if node.name != name {
                node.texture = textures.texture(name)
                node.name = name
            }
        }
        let active = Set(world.blocks.activeCoordinates)
        for coord in bumped.subtracting(active) {
            nodes[coord]?.position.y = Tiles.origin(coord.row)
        }
        for coord in active {
            nodes[coord]?.position.y = Tiles.origin(coord.row) + world.bumpOffset(col: coord.col, row: coord.row)
        }
        bumped = active
    }

    func tileChanged(col: Int, row: Int, world: GameWorld) {
        let coord = TileCoord(col: col, row: row)
        nodes[coord]?.removeFromParent()
        nodes[coord] = nil
        animated.remove(coord)
        if let cols = columns, cols.contains(col) {
            addTile(coord, kind: world.map[coord], frame: world.frame)
        }
    }

    func reset() {
        nodes.values.forEach { $0.removeFromParent() }
        nodes.removeAll()
        animated.removeAll()
        bumped.removeAll()
        columns = nil
    }

    private func addColumn(_ col: Int, world: GameWorld) {
        for row in 0..<world.map.height {
            addTile(TileCoord(col: col, row: row), kind: world.map[col, row], frame: world.frame)
        }
    }

    private func removeColumn(_ col: Int, height: Int) {
        for row in 0..<height {
            let coord = TileCoord(col: col, row: row)
            nodes[coord]?.removeFromParent()
            nodes[coord] = nil
            animated.remove(coord)
        }
    }

    private func addTile(_ coord: TileCoord, kind: TileKind, frame: Int) {
        guard let name = TileLayer.spriteName(for: kind, theme: theme, frame: frame) else { return }
        let node = SKSpriteNode(texture: textures.texture(name), size: CGSize(width: GameConstants.tileSize, height: GameConstants.tileSize))
        node.anchorPoint = .zero
        node.position = CGPoint(x: Tiles.origin(coord.col), y: Tiles.origin(coord.row))
        node.name = name
        node.zPosition = kind == .cloud ? 1 : 0
        parent.addChild(node)
        nodes[coord] = node
        if TileLayer.isAnimated(kind) { animated.insert(coord) }
    }
}
