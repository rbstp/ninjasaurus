struct AnimationClip: Equatable, Sendable {
    let frames: [String]
    let hold: Int
    let loops: Bool

    init(_ frames: [String], hold: Int = 8, loops: Bool = true) {
        precondition(!frames.isEmpty)
        self.frames = frames
        self.hold = max(1, hold)
        self.loops = loops
    }

    init(single frame: String) {
        self.init([frame], hold: 1, loops: false)
    }

    func frame(at elapsed: Int) -> String {
        let index = max(0, elapsed) / hold
        if loops {
            return frames[index % frames.count]
        }
        return frames[min(index, frames.count - 1)]
    }
}
