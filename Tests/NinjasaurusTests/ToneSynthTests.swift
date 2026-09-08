import XCTest
@testable import Ninjasaurus

final class ToneSynthTests: XCTestCase {
    func testSampleCountMatchesDuration() {
        let recipe = ToneRecipe(wave: .square(duty: 0.5), segments: [.note(440, 0.5), .rest(0.25)], sampleRate: 22050)
        let samples = ToneSynth.render(recipe)
        XCTAssertEqual(samples.count, Int(0.75 * 22050))
    }

    func testAmplitudeStaysInRangeForEveryWaveform() {
        for wave in [Waveform.square(duty: 0.25), .triangle, .saw, .noise] {
            let samples = ToneSynth.render(ToneRecipe(wave: wave, segments: [.sweep(100, 2000, 0.2, gain: 1)]))
            XCTAssertFalse(samples.isEmpty)
            XCTAssertTrue(samples.allSatisfy { $0 >= -1 && $0 <= 1 }, "\(wave) out of range")
            XCTAssertTrue(samples.contains { abs($0) > 0.5 }, "\(wave) is silent")
        }
    }

    func testEnvelopeStartsAndEndsQuiet() {
        let samples = ToneSynth.render(ToneRecipe(wave: .square(duty: 0.5), segments: [.note(440, 0.2, gain: 1, release: 0.05)]))
        XCTAssertEqual(samples.first!, 0, accuracy: 0.01)
        XCTAssertEqual(samples.last!, 0, accuracy: 0.02)
    }

    func testRenderingIsDeterministic() {
        let a = ToneSynth.render(Sfx.stomp.recipe)
        let b = ToneSynth.render(Sfx.stomp.recipe)
        XCTAssertEqual(a, b)
    }

    func testEverySfxRendersSomething() {
        for sfx in Sfx.allCases {
            let samples = ToneSynth.render(sfx.recipe)
            XCTAssertGreaterThan(samples.count, 100, "\(sfx)")
            XCTAssertLessThan(samples.count, Int(3 * 22050), "\(sfx) is too long")
        }
    }

    func testWavHeader() {
        let samples: [Float] = [0, 0.5, -0.5, 1]
        let data = ToneSynth.wavData(samples: samples, sampleRate: 22050)
        XCTAssertEqual(data.count, 44 + samples.count * 2)
        XCTAssertEqual(String(decoding: data[0..<4], as: UTF8.self), "RIFF")
        XCTAssertEqual(String(decoding: data[8..<12], as: UTF8.self), "WAVE")
        XCTAssertEqual(String(decoding: data[36..<40], as: UTF8.self), "data")
        let dataSize = data[40..<44].withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
        XCTAssertEqual(UInt32(littleEndian: dataSize), UInt32(samples.count * 2))
        let last = data[(data.count - 2)...].withUnsafeBytes { $0.loadUnaligned(as: Int16.self) }
        XCTAssertEqual(Int16(littleEndian: last), 32767)
    }
}
