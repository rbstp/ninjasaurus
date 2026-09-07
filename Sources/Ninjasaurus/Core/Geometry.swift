import Foundation

struct Vec2: Equatable, Sendable {
    var x: Double
    var y: Double

    static let zero = Vec2(x: 0, y: 0)

    static func + (lhs: Vec2, rhs: Vec2) -> Vec2 { Vec2(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: Vec2, rhs: Vec2) -> Vec2 { Vec2(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
    static func * (lhs: Vec2, rhs: Double) -> Vec2 { Vec2(x: lhs.x * rhs, y: lhs.y * rhs) }
}

enum Facing: Sendable {
    case left
    case right

    var sign: Double { self == .right ? 1 : -1 }
    var flipped: Facing { self == .right ? .left : .right }
}

struct AABB: Equatable, Sendable {
    var minX: Double
    var minY: Double
    var width: Double
    var height: Double

    init(minX: Double, minY: Double, width: Double, height: Double) {
        self.minX = minX
        self.minY = minY
        self.width = width
        self.height = height
    }

    init(bottomCenter: Vec2, size: Vec2) {
        self.init(minX: bottomCenter.x - size.x / 2, minY: bottomCenter.y, width: size.x, height: size.y)
    }

    var maxX: Double {
        get { minX + width }
        set { minX = newValue - width }
    }

    var maxY: Double {
        get { minY + height }
        set { minY = newValue - height }
    }

    var midX: Double { minX + width / 2 }
    var midY: Double { minY + height / 2 }
    var size: Vec2 { Vec2(x: width, y: height) }
    var bottomCenter: Vec2 { Vec2(x: midX, y: minY) }
    var center: Vec2 { Vec2(x: midX, y: midY) }

    func intersects(_ other: AABB) -> Bool {
        minX < other.maxX && maxX > other.minX && minY < other.maxY && maxY > other.minY
    }

    func contains(_ point: Vec2) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }

    func offset(by delta: Vec2) -> AABB {
        AABB(minX: minX + delta.x, minY: minY + delta.y, width: width, height: height)
    }

    func resized(to size: Vec2) -> AABB {
        AABB(bottomCenter: bottomCenter, size: size)
    }
}

enum Tiles {
    static func index(_ value: Double) -> Int {
        Int((value / GameConstants.tileSize).rounded(.down))
    }

    static func origin(_ index: Int) -> Double {
        Double(index) * GameConstants.tileSize
    }
}
