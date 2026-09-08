import Foundation

struct Step: Equatable, Sendable {
    var midi: Int?
    var beats: Double
    /// Slide up into the note from this many semitones below.
    var bend: Int = 0
}

struct Song: Equatable, Sendable {
    var name: String
    var bpm: Double
    var melody: [Step]
    var bass: [Step]
    var melodyGain: Float = 0.13
    var bassGain: Float = 0.14
    var drumGain: Float = 0.15
    /// Beats within a bar that get a taiko hit; offbeats get a rim click.
    var taiko: [Double] = [0, 2]
    var clicks: [Double] = [1, 3]

    var beats: Double { melody.reduce(0) { $0 + $1.beats } }
    var duration: Double { beats * 60 / bpm }
}

/// Chiptune in a Japanese folk idiom: pentatonic yo and in scales, plucked
/// notes, taiko on the strong beats. Written as text, rendered at launch.
enum Music {
    static let sampleRate = 22050.0

    /// "D5 E5:.5 . A5^:2": note, optional ^ for a bend, optional :beats (default 1), . for a rest.
    static func steps(_ text: String) -> [Step] {
        text.split(separator: " ").map { token in
            var name = String(token)
            var beats = 1.0
            if let colon = name.firstIndex(of: ":") {
                beats = Double(name[name.index(after: colon)...]) ?? 1
                name = String(name[..<colon])
            }
            var bend = 0
            if name.hasSuffix("^") {
                bend = 2
                name.removeLast()
            }
            return Step(midi: name == "." ? nil : midi(name), beats: beats, bend: bend)
        }
    }

    static func midi(_ name: String) -> Int {
        let letters: [Character: Int] = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]
        var chars = Array(name)
        let base = letters[chars.removeFirst()] ?? 0
        var accidental = 0
        if chars.first == "#" { accidental = 1; chars.removeFirst() }
        if chars.first == "b" { accidental = -1; chars.removeFirst() }
        let octave = Int(String(chars)) ?? 4
        return 12 * (octave + 1) + base + accidental
    }

    static func render(_ song: Song) -> [Float] {
        let secondsPerBeat = 60 / song.bpm
        let melody = voice(song.melody, wave: .square(duty: 0.5), secondsPerBeat: secondsPerBeat, pluck: true)
        let bass = voice(song.bass, wave: .triangle, secondsPerBeat: secondsPerBeat, pluck: false)
        let count = min(melody.count, bass.count)
        var out = [Float](repeating: 0, count: count)
        for i in 0..<count {
            out[i] = melody[i] * song.melodyGain + bass[i] * song.bassGain
        }
        let don = ToneSynth.render(ToneRecipe(wave: .triangle, segments: [.sweep(150, 45, 0.18, gain: 1, release: 0.12)], sampleRate: sampleRate))
        let thump = ToneSynth.render(ToneRecipe(wave: .noise, segments: [.sweep(700, 150, 0.05, gain: 0.5, release: 0.03)], sampleRate: sampleRate))
        let ka = ToneSynth.render(ToneRecipe(wave: .noise, segments: [.sweep(5000, 3000, 0.02, gain: 0.5, release: 0.01)], sampleRate: sampleRate))
        var bar = 0.0
        while bar < song.beats {
            for beat in song.taiko {
                mix(don, into: &out, at: (bar + beat) * secondsPerBeat, gain: song.drumGain)
                mix(thump, into: &out, at: (bar + beat) * secondsPerBeat, gain: song.drumGain)
            }
            for beat in song.clicks {
                mix(ka, into: &out, at: (bar + beat) * secondsPerBeat, gain: song.drumGain * 0.5)
            }
            bar += 4
        }
        return out.map { max(-1, min(1, $0)) }
    }

    private static func mix(_ sample: [Float], into out: inout [Float], at seconds: Double, gain: Float) {
        let start = Int(seconds * sampleRate)
        for (i, value) in sample.enumerated() where start + i < out.count {
            out[start + i] += value * gain
        }
    }

    private static func voice(_ steps: [Step], wave: Waveform, secondsPerBeat: Double, pluck: Bool) -> [Float] {
        var segments: [ToneSegment] = []
        for step in steps {
            let duration = step.beats * secondsPerBeat
            guard let midi = step.midi else {
                segments.append(.rest(duration))
                continue
            }
            let hz = Note.hz(midi)
            let sounding = duration * (pluck ? 0.9 : 0.75)
            if step.bend > 0 {
                let slide = min(0.08, sounding * 0.3)
                segments.append(ToneSegment(startHz: Note.hz(midi - step.bend), endHz: hz, duration: slide, attack: 0.003, release: 0, gain: 1))
                segments.append(ToneSegment(startHz: hz, endHz: hz, duration: sounding - slide, attack: 0, release: pluck ? (sounding - slide) * 0.7 : 0.03, gain: 1))
            } else {
                segments.append(ToneSegment(startHz: hz, endHz: hz, duration: sounding, attack: 0.003, release: pluck ? sounding * 0.7 : 0.03, gain: 1))
            }
            segments.append(.rest(duration - sounding))
        }
        return ToneSynth.render(ToneRecipe(wave: wave, segments: segments, sampleRate: sampleRate))
    }

    // MARK: Songs

    static let title = Song(
        name: "title", bpm: 108,
        melody: steps(
            "D5 E5:.5 G5:.5 A5:2 B5:.5 A5:.5 G5 E5:2 D5:.5 E5:.5 G5 A5:.5 B5:.5 D6 B5 A5:2 . "
            + "G5:.5 A5:.5 B5 D6^:2 B5:.5 A5:.5 G5 E5 D5 E5:.5 G5:.5 A5:.5 G5:.5 E5 D5 D5:2 .:2"
        ),
        bass: steps("D3:2 A2:2 D3:2 A2:2 G2:2 A2:2 D3:2 A2:2 G2:2 D3:2 G2:2 A2:2 D3:2 A2:2 D3:2 D3:2"),
        drumGain: 0.16, taiko: [0], clicks: [2]
    )

    static let meadow = Song(
        name: "meadow", bpm: 144,
        melody: steps(
            "G5:.5 A5:.5 B5 D6:.5 B5:.5 A5 G5:.5 A5:.5 G5 E5 D5 E5:.5 G5:.5 A5 B5:.5 A5:.5 G5 A5 B5:2 . "
            + "D6:.5 B5:.5 A5 G5:.5 A5:.5 B5 A5:.5 G5:.5 E5 D5 E5 G5:.5 A5:.5 B5:.5 D6:.5 E6 D6 B5 A5:.5 G5:.5 G5:2 "
            + "B5:.5 D6:.5 E6 D6:.5 B5:.5 A5 G5:.5 A5:.5 B5 A5 G5 E5:.5 G5:.5 A5 B5:.5 D6:.5 B5 A5 G5:2 . "
            + "D5:.5 E5:.5 G5 A5:.5 B5:.5 D6 B5:.5 A5:.5 G5 E5 G5 A5:.5 B5:.5 D6:.5 E6:.5 D6 B5 A5 G5:.5 A5:.5 G5:2"
        ),
        bass: steps(bassLine(["G", "G", "E", "D", "G", "E", "G", "D", "G", "G", "E", "D", "G", "E", "D", "G"]))
    )

    static let cave = Song(
        name: "cave", bpm: 96,
        melody: steps(
            "E4^ .:.5 F4:.5 A4:2 B4 A4:.5 F4:.5 E4:2 A4^ B4 C5:2 B4:.5 A4:.5 F4 E4:2 "
            + "E5^ .:.5 C5:.5 B4:2 A4:.5 B4:.5 A4 F4:2 E4 F4 A4 B4 E4:3 .:1"
        ),
        bass: steps("E2:4 E2:4 A2:4 B2:4 E2:4 A2:4 F2:4 E2:4"),
        melodyGain: 0.11, bassGain: 0.13, drumGain: 0.12, taiko: [0], clicks: []
    )

    static let sky = Song(
        name: "sky", bpm: 132,
        melody: steps(
            "A5:.5 B5:.5 D6:.5 E6:.5 F#6 E6 D6:.5 E6:.5 D6:.5 B5:.5 A5:2 B5:.5 D6:.5 E6:.5 F#6:.5 A6 F#6 E6:.5 D6:.5 B5:.5 A5:.5 B5:2 "
            + "F#6:.5 E6:.5 D6:.5 B5:.5 A5 B5 D6:.5 E6:.5 F#6 E6:.5 D6:.5 B5 A5:.5 B5:.5 D6:.5 E6:.5 D6 B5 A5^:2 .:2"
        ),
        bass: steps(bassLine(["A", "D", "A", "E", "F#", "D", "E", "A"])),
        melodyGain: 0.12, drumGain: 0.14
    )

    static let lava = Song(
        name: "lava", bpm: 160,
        melody: steps(
            "D5:.5 D5:.5 Eb5:.5 D5:.5 A5 G5 Bb5:.5 A5:.5 G5:.5 Eb5:.5 D5:2 D5:.5 D5:.5 G5:.5 A5:.5 Bb5 A5 G5:.5 Eb5:.5 D5:.5 Eb5:.5 D5:2 "
            + "A5:.5 A5:.5 Bb5:.5 A5:.5 D6 Bb5 A5:.5 G5:.5 Eb5:.5 G5:.5 A5:2 D6^ Bb5 A5 G5 Eb5:.5 D5:.5 Eb5:.5 D5:.5 D5:2"
        ),
        bass: steps(pulse(["D", "D", "Bb", "G", "A", "G", "D", "D"])),
        melodyGain: 0.11, bassGain: 0.14, drumGain: 0.17, taiko: [0, 1.5, 2], clicks: [1, 3, 3.5]
    )

    static func song(for theme: Theme) -> Song {
        switch theme {
        case .grass: return meadow
        case .cave: return cave
        case .sky: return sky
        case .lava: return lava
        }
    }

    static let all: [Song] = [title, meadow, cave, sky, lava]

    private static func bassLine(_ roots: [String]) -> String {
        roots.map { root in
            let rootMidi = midi(root + "2")
            return "\(name(rootMidi)):.5 .:.5 \(name(rootMidi + 7)):.5 .:.5 \(name(rootMidi)):.5 .:.5 \(name(rootMidi + 7)):.5 .:.5"
        }.joined(separator: " ")
    }

    private static func pulse(_ roots: [String]) -> String {
        roots.map { root in
            Array(repeating: "\(root)2:.5", count: 8).joined(separator: " ")
        }.joined(separator: " ")
    }

    private static func name(_ midi: Int) -> String {
        let names = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"]
        return names[midi % 12] + String(midi / 12 - 1)
    }
}
