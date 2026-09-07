import AVFoundation

@MainActor
final class AudioPlayer {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
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
        guard !isMuted, let buffer = buffers[sfx] else { return }
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                return
            }
        }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    private func restart() {
        engine.stop()
        engine.prepare()
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
