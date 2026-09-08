import AVFoundation

@MainActor
final class AudioPlayer {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
    private let musicNode = AVAudioPlayerNode()
    private var musicBuffers: [String: AVAudioPCMBuffer] = [:]
    private var currentSong: String?
    var musicVolume: Float = 0.5 {
        didSet { musicNode.volume = musicVolume }
    }
    var isMusicEnabled = true {
        didSet {
            if isMusicEnabled { resumeMusic() } else { musicNode.pause() }
        }
    }
    private var nextPlayer = 0
    private var observer: NSObjectProtocol?

    var isMuted = false

    init() {
        for _ in 0..<8 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }
        for sfx in Sfx.allCases {
            buffers[sfx] = makeBuffer(ToneSynth.render(sfx.recipe))
        }
        engine.attach(musicNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        musicNode.volume = musicVolume
        engine.prepare()
        observer = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.restart()
            }
        }
    }

    func play(_ sfx: Sfx) {
        guard !isMuted, let buffer = buffers[sfx], startEngine() else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    /// Loops the song; switching to the same song is a no-op.
    func playMusic(_ song: Song) {
        guard song.name != currentSong else {
            resumeMusic()
            return
        }
        currentSong = song.name
        if musicBuffers[song.name] == nil {
            musicBuffers[song.name] = makeBuffer(Music.render(song))
        }
        guard let buffer = musicBuffers[song.name], startEngine() else { return }
        musicNode.stop()
        musicNode.scheduleBuffer(buffer, at: nil, options: .loops)
        if isMusicEnabled { musicNode.play() }
    }

    func pauseMusic() {
        musicNode.pause()
    }

    func resumeMusic() {
        guard isMusicEnabled, currentSong != nil, startEngine(), !musicNode.isPlaying else { return }
        musicNode.play()
    }

    func stopMusic() {
        currentSong = nil
        musicNode.stop()
    }

    private func startEngine() -> Bool {
        if engine.isRunning { return true }
        try? AVAudioSession.sharedInstance().setActive(true)
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    private func restart() {
        engine.stop()
        engine.prepare()
        if isMusicEnabled, currentSong != nil, startEngine() {
            musicNode.play()
        }
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer {
        let count = AVAudioFrameCount(samples.count)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: max(count, 1))!
        buffer.frameLength = count
        if let channel = buffer.floatChannelData?[0] {
            for (index, sample) in samples.enumerated() {
                channel[index] = sample
            }
        }
        return buffer
    }
}
