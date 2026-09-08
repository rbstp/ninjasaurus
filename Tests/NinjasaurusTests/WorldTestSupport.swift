import XCTest
@testable import Ninjasaurus

enum WorldTestSupport {
    static func level(_ text: String) -> LevelDefinition {
        do {
            return try LevelParser.parse(text)
        } catch {
            fatalError("bad test level: \(error)")
        }
    }

    static func world(_ text: String, viewSize: Vec2 = Vec2(x: 416, y: 208)) -> GameWorld {
        GameWorld(level: level(text), viewSize: viewSize)
    }

    @discardableResult
    static func run(_ world: GameWorld, frames: Int, input: InputState = .none) -> [GameEvent] {
        var events: [GameEvent] = []
        for _ in 0..<frames {
            events += world.step(input: input)
        }
        return events
    }

    static func run(_ world: GameWorld, until predicate: (GameWorld) -> Bool, limit: Int = 600, input: InputState = .none) -> Int? {
        for frame in 0..<limit {
            _ = world.step(input: input)
            if predicate(world) { return frame + 1 }
        }
        return nil
    }

    static let flat = """
    ! name: Flat
    ! theme: grass
    ........................................
    ........................................
    ........................................
    ........................................
    ........................................
    ........................................
    ........................................
    ........................................
    ........................................
    ........................................
    ..S.................................F...
    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
    ########################################
    """
}

extension GameEvent {
    var isScorePopup: Bool {
        if case .scorePopup = self { return true }
        return false
    }

    var scorePoints: Int? {
        if case .scorePopup(let points, _) = self { return points }
        return nil
    }
}
