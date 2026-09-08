import XCTest
@testable import Ninjasaurus

final class LevelParserTests: XCTestCase {
    private let sample = """
    ! name: Test Meadow
    ! theme: cave
    ..........
    ...?M*+...
    .S.r..a.F.
    GGGGGG..GG
    ######..##
    """

    func testParsesHeaderGridAndMarkers() throws {
        let level = try LevelParser.parse(sample)
        XCTAssertEqual(level.name, "Test Meadow")
        XCTAssertEqual(level.theme, .cave)
        XCTAssertEqual(level.map.width, 10)
        XCTAssertEqual(level.map.height, 5)
        // Line 1 of the file is the TOP row.
        XCTAssertEqual(level.map[0, 0], .fill)
        XCTAssertEqual(level.map[0, 1], .groundTop)
        XCTAssertEqual(level.map[6, 0], .empty)
        XCTAssertEqual(level.map[3, 3], .questionCoin)
        XCTAssertEqual(level.map[4, 3], .questionPower)
        XCTAssertEqual(level.map[5, 3], .questionKatana)
        XCTAssertEqual(level.map[6, 3], .brickOneUp)
        XCTAssertEqual(level.map[0, 4], .empty)
        // Markers are stripped from the grid.
        XCTAssertEqual(level.map[1, 2], .empty)
        XCTAssertEqual(level.map[3, 2], .empty)
        XCTAssertEqual(level.playerStart, Vec2(x: 24, y: 32))
        XCTAssertEqual(level.spawns, [
            EnemySpawn(kind: .raptor, col: 3, row: 2),
            EnemySpawn(kind: .anky, col: 6, row: 2),
        ])
        XCTAssertEqual(level.goal, AABB(minX: 128, minY: 32, width: 32, height: 48))
        XCTAssertNil(level.bossSpawn)
    }

    func testBossMarker() throws {
        let level = try LevelParser.parse("S...X.F\nGGGGGGG")
        XCTAssertEqual(level.bossSpawn, Vec2(x: 72, y: 16))
        XCTAssertTrue(level.hasBoss)
    }

    func testErrors() {
        XCTAssertThrowsError(try LevelParser.parse("")) { XCTAssertEqual($0 as? LevelParseError, .emptyLevel) }
        XCTAssertThrowsError(try LevelParser.parse("S.F\nGG")) { XCTAssertEqual($0 as? LevelParseError, .raggedRow(line: 2)) }
        XCTAssertThrowsError(try LevelParser.parse("S.Fz\nGGGG")) { XCTAssertEqual($0 as? LevelParseError, .unknownCharacter("z", line: 1)) }
        XCTAssertThrowsError(try LevelParser.parse("..F\nGGG")) { XCTAssertEqual($0 as? LevelParseError, .missingStart) }
        XCTAssertThrowsError(try LevelParser.parse("S..\nGGG")) { XCTAssertEqual($0 as? LevelParseError, .missingGoal) }
        XCTAssertThrowsError(try LevelParser.parse("SSF\nGGG")) { XCTAssertEqual($0 as? LevelParseError, .multipleStarts) }
        XCTAssertThrowsError(try LevelParser.parse("! theme: moon\nS.F\nGGG")) { XCTAssertEqual($0 as? LevelParseError, .unknownTheme("moon")) }
    }

    func testMapOutOfBoundsRules() {
        var map = TileMap(width: 3, height: 2)
        map[1, 1] = .brick
        XCTAssertEqual(map[1, 1], .brick)
        XCTAssertEqual(map[-1, 0], .wall)
        XCTAssertEqual(map[3, 0], .wall)
        XCTAssertEqual(map[0, -1], .empty)
        XCTAssertEqual(map[0, 2], .empty)
        map[9, 9] = .brick  // silently ignored
        XCTAssertEqual(map[0, 0], .empty)
    }

    func testBundledLevelsParse() throws {
        let bundle = Bundle(for: LevelParserTests.self)
        for (index, id) in LevelCatalog.ids.enumerated() {
            let level = try LevelCatalog.load(index: index, bundle: Bundle.main)
            XCTAssertFalse(level.name.isEmpty, id)
            XCTAssertGreaterThan(level.map.width, 40, id)
            XCTAssertGreaterThanOrEqual(level.map.height, 13, id)
            XCTAssertEqual(level.hasBoss, id == "1-4", id)
            _ = bundle
        }
    }
}
