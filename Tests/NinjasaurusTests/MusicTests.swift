import XCTest
@testable import Ninjasaurus

final class MusicTests: XCTestCase {
    func testNoteNames() {
        XCTAssertEqual(Music.midi("C4"), 60)
        XCTAssertEqual(Music.midi("A4"), 69)
        XCTAssertEqual(Music.midi("Bb2"), 46)
        XCTAssertEqual(Music.midi("G#5"), 80)
        let steps = Music.steps("C5:.5 . G5:2")
        XCTAssertEqual(steps, [Step(midi: 72, beats: 0.5), Step(midi: nil, beats: 1), Step(midi: 79, beats: 2)])
    }

    func testVoicesHaveEqualLengthAndSongsRenderInRange() {
        for song in Music.all {
            let melodyBeats = song.melody.reduce(0) { $0 + $1.beats }
            let bassBeats = song.bass.reduce(0) { $0 + $1.beats }
            XCTAssertEqual(melodyBeats, bassBeats, accuracy: 1e-9, "\(song.name) voices differ in length")
            XCTAssertEqual(melodyBeats.truncatingRemainder(dividingBy: 4), 0, accuracy: 1e-9, "\(song.name) does not end on a bar")
            let samples = Music.render(song)
            XCTAssertEqual(Double(samples.count), song.duration * Music.sampleRate, accuracy: 4 * Double(song.melody.count) + 100, song.name)
            XCTAssertTrue(samples.allSatisfy { $0 >= -1 && $0 <= 1 }, song.name)
            let peak = samples.map { abs($0) }.max() ?? 0
            XCTAssertLessThan(peak, 0.5, "\(song.name) is loud")
            XCTAssertGreaterThan(peak, 0.1, "\(song.name) is silent")
        }
    }
}
