import AVFoundation

/// Sound effects through a small pool of player nodes, music through one
/// looping node. Music plays only when a song is wanted, the preference is on,
/// the game is not paused, the app is active and no interruption is in force.
@MainActor
final class AudioPlayer {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
    private var nextPlayer = 0
    private var observers: [NSObjectProtocol] = []

    private let musicNode = AVAudioPlayerNode()
    private var musicBuffers: [String: AVAudioPCMBuffer] = [:]
    private var currentSong: Song?
    private var scheduled = false
    private var gamePaused = false
    private var appActive = true
    private var interrupted = false

    var isMuted = false
    var musicVolume: Float = 0.5 {
        didSet { musicNode.volume = musicVolume }
    }
    var isMusicEnabled = true {
        didSet { refreshMusic() }
    }

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
        observers.append(NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.engineConfigurationChanged() }
        })
        observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = AVAudioSession.InterruptionOptions(rawValue: note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
            MainActor.assumeIsolated { self?.interruption(began: raw == AVAudioSession.InterruptionType.began.rawValue, shouldResume: options.contains(.shouldResume)) }
        })
    }

    // MARK: Effects

    func play(_ sfx: Sfx) {
        guard !isMuted, let buffer = buffers[sfx], startEngine() else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    // MARK: Music

    func playMusic(_ song: Song) {
        if currentSong?.name != song.name {
            currentSong = song
            musicNode.stop()
            scheduled = false
        }
        gamePaused = false
        refreshMusic()
    }

    func pauseMusic() {
        gamePaused = true
        refreshMusic()
    }

    func resumeMusic() {
        gamePaused = false
        refreshMusic()
    }

    func stopMusic() {
        currentSong = nil
        scheduled = false
        musicNode.stop()
    }

    func setAppActive(_ active: Bool) {
        appActive = active
        refreshMusic()
    }

    private var shouldPlayMusic: Bool {
        currentSong != nil && isMusicEnabled && !gamePaused && appActive && !interrupted
    }

    private func refreshMusic() {
        guard shouldPlayMusic, let song = currentSong else {
            if musicNode.isPlaying { musicNode.pause() }
            return
        }
        guard startEngine() else { return }
        if !scheduled {
            if musicBuffers[song.name] == nil {
                musicBuffers[song.name] = makeBuffer(Music.render(song))
            }
            guard let buffer = musicBuffers[song.name] else { return }
            musicNode.stop()
            musicNode.scheduleBuffer(buffer, at: nil, options: .loops)
            scheduled = true
        }
        if !musicNode.isPlaying { musicNode.play() }
    }

    private func interruption(began: Bool, shouldResume: Bool) {
        if began {
            interrupted = true
            if musicNode.isPlaying { musicNode.pause() }
        } else {
            interrupted = false
            if shouldResume { refreshMusic() }
        }
    }

    private func engineConfigurationChanged() {
        engine.stop()
        engine.prepare()
        musicNode.stop()
        scheduled = false
        refreshMusic()
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
