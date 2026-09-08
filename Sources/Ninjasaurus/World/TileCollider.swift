enum TileCollider {
    static let epsilon = 0.01

    struct XResult: Equatable {
        var rect: AABB
        var hitWall: Bool
    }

    struct YResult: Equatable {
        var rect: AABB
        var landed: Bool
        var hitCeiling: Bool
        var ceilingRow: Int
        var ceilingColumns: [Int]
    }

    static func moveX(_ rect: AABB, by dx: Double, in map: TileMap) -> XResult {
        var moved = rect
        moved.minX += dx
        guard dx != 0 else { return XResult(rect: moved, hitWall: false) }
        let rows = Tiles.index(moved.minY + epsilon)...Tiles.index(moved.maxY - epsilon)
        if dx > 0 {
            let col = Tiles.index(moved.maxX - epsilon)
            if rows.contains(where: { map[col, $0].isSolid }) {
                moved.maxX = Tiles.origin(col)
                return XResult(rect: moved, hitWall: true)
            }
        } else {
            let col = Tiles.index(moved.minX + epsilon)
            if rows.contains(where: { map[col, $0].isSolid }) {
                moved.minX = Tiles.origin(col + 1)
                return XResult(rect: moved, hitWall: true)
            }
        }
        return XResult(rect: moved, hitWall: false)
    }

    static func moveY(_ rect: AABB, by dy: Double, previous: AABB, in map: TileMap) -> YResult {
        var moved = rect
        moved.minY += dy
        let cols = Tiles.index(moved.minX + epsilon)...Tiles.index(moved.maxX - epsilon)
        if dy <= 0 {
            let row = Tiles.index(moved.minY + epsilon)
            let top = Tiles.origin(row + 1)
            let landed = cols.contains { col in
                let tile = map[col, row]
                return tile.isSolid || (tile.isOneWay && previous.minY >= top - 0.5)
            }
            if landed {
                moved.minY = top
                return YResult(rect: moved, landed: true, hitCeiling: false, ceilingRow: row, ceilingColumns: [])
            }
            return YResult(rect: moved, landed: false, hitCeiling: false, ceilingRow: row, ceilingColumns: [])
        }
        let row = Tiles.index(moved.maxY - epsilon)
        let solid = cols.filter { map[$0, row].isSolid }
        if !solid.isEmpty {
            moved.maxY = Tiles.origin(row)
            return YResult(rect: moved, landed: false, hitCeiling: true, ceilingRow: row, ceilingColumns: solid)
        }
        return YResult(rect: moved, landed: false, hitCeiling: false, ceilingRow: row, ceilingColumns: [])
    }

    static func hazardAhead(x: Double, footY: Double, in map: TileMap) -> Bool {
        let col = Tiles.index(x)
        let footRow = Tiles.index(footY + epsilon)
        if map[col, footRow].isHazard { return true }
        for row in stride(from: footRow - 1, through: footRow - 3, by: -1) {
            let tile = map[col, row]
            if tile.isHazard { return true }
            if tile.isSolid || tile.isOneWay { return false }
        }
        return false
    }

    static func hasFloor(x: Double, belowY y: Double, in map: TileMap) -> Bool {
        let tile = map[Tiles.index(x), Tiles.index(y - epsilon)]
        return tile.isSolid || tile.isOneWay
    }
}
