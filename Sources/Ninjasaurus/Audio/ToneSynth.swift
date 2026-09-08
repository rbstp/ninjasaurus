import Foundation

enum Waveform: Equatable, Sendable {
    case square(duty: Double)
    case triangle
    case saw
    case noise
}

struct ToneSegment: Equatable, Sendable {
    var startHz: Double
    var endHz: Double
    var duration: Double
    var attack: Double = 0.005
    var release: Double = 0.02
    var gain: Float = 0.5

    static func note(_ hz: Double, _ duration: Double, gain: Float = 0.5, release: Double = 0.02) -> ToneSegment {
        ToneSegment(startHz: hz, endHz: hz, duration: duration, release: release, gain: gain)
    }

    static func sweep(_ from: Double, _ to: Double, _ duration: Double, gain: Float = 0.5, release: Double = 0.02) -> ToneSegment {
        ToneSegment(startHz: from, endHz: to, duration: duration, release: release, gain: gain)
    }

    static func rest(_ duration: Double) -> ToneSegment {
        ToneSegment(startHz: 0, endHz: 0, duration: duration, attack: 0, release: 0, gain: 0)
    }
}

struct ToneRecipe: Equatable, Sendable {
    var wave: Waveform
    var segments: [ToneSegment]
    var sampleRate: Double = 22050
}

enum ToneSynth {
    static func render(_ recipe: ToneRecipe) -> [Float] {
        var rng = SeededRandom(seed: 0x5EED)
        var out: [Float] = []
        var phase = 0.0
        var noiseValue: Float = 0
        var noiseCounter = 0
        for segment in recipe.segments {
            let count = Int(segment.duration * recipe.sampleRate)
            guard count > 0 else { continue }
            let attackSamples = max(1, Int(segment.attack * recipe.sampleRate))
            let releaseSamples = max(1, Int(segment.release * recipe.sampleRate))
            for i in 0..<count {
                let t = Double(i) / Double(count)
                let hz = segment.startHz + (segment.endHz - segment.startHz) * t
                var envelope: Float = 1
                if i < attackSamples { envelope = Float(i) / Float(attackSamples) }
                let remaining = count - i
                if remaining < releaseSamples { envelope = min(envelope, Float(remaining) / Float(releaseSamples)) }
                var sample: Float = 0
                switch recipe.wave {
                case .square(let duty):
                    sample = phase < duty ? 1 : -1
                case .triangle:
                    sample = Float(phase < 0.5 ? (phase * 4 - 1) : (3 - phase * 4))
                case .saw:
                    sample = Float(phase * 2 - 1)
                case .noise:
                    // Sample-and-hold noise, pitched by hz so "low" noise sounds like a thud.
                    let hold = max(1, Int(recipe.sampleRate / max(hz, 1)))
                    if noiseCounter % hold == 0 {
                        noiseValue = Float(rng.nextUnit() * 2 - 1)
                    }
                    noiseCounter += 1
                    sample = noiseValue
                }
                out.append(sample * envelope * segment.gain)
                phase += hz / recipe.sampleRate
                if phase >= 1 { phase -= 1 }
            }
        }
        return out
    }

    static func wavData(samples: [Float], sampleRate: Double) -> Data {
        var data = Data()
        let byteRate = UInt32(sampleRate) * 2
        let dataSize = UInt32(samples.count * 2)
        func append(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        data.append(contentsOf: Array("RIFF".utf8))
        append(36 + dataSize)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        append(16)
        append16(1)
        append16(1)
        append(UInt32(sampleRate))
        append(byteRate)
        append16(2)
        append16(16)
        data.append(contentsOf: Array("data".utf8))
        append(dataSize)
        for sample in samples {
            let clamped = max(-1, min(1, sample))
            append16(UInt16(bitPattern: Int16(clamped * 32767)))
        }
        return data
    }
}

enum Note {
    static func hz(_ midi: Int) -> Double {
        440 * pow(2, Double(midi - 69) / 12)
    }

    static let c3 = hz(48), g3 = hz(55), c4 = hz(60), e4 = hz(64), g4 = hz(67)
    static let c5 = hz(72), d5 = hz(74), e5 = hz(76), g5 = hz(79), b5 = hz(83)
    static let c6 = hz(84), d6 = hz(86), e6 = hz(88), g6 = hz(91), c7 = hz(96), e7 = hz(100)
}
