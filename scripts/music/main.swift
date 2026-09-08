import Foundation

// Renders every song to WAV for listening: run `make music`.
let dir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
for song in Music.all {
    let data = ToneSynth.wavData(samples: Music.render(song), sampleRate: Music.sampleRate)
    try! data.write(to: URL(fileURLWithPath: "\(dir)/\(song.name).wav"))
    print("\(song.name): \(String(format: "%.1f", song.duration)) s")
}
