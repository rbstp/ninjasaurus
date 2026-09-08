struct FixedStepClock: Sendable {
    let step: Double
    let maxSteps: Int
    private(set) var accumulator: Double = 0
    private var lastTime: Double?

    init(step: Double = GameConstants.stepDuration, maxSteps: Int = GameConstants.maxStepsPerFrame) {
        self.step = step
        self.maxSteps = maxSteps
    }

    mutating func advance(to time: Double) -> Int {
        guard let last = lastTime else {
            lastTime = time
            return 0
        }
        lastTime = time
        let elapsed = min(max(0, time - last), step * Double(maxSteps))
        accumulator += elapsed
        var steps = 0
        while accumulator >= step - 1e-9 && steps < maxSteps {
            accumulator -= step
            steps += 1
        }
        if steps == maxSteps {
            accumulator = 0
        }
        return steps
    }

    mutating func reset() {
        lastTime = nil
        accumulator = 0
    }
}
