struct InputState: Equatable, Sendable {
    var left = false
    var right = false
    var jump = false
    var action = false

    static let none = InputState()

    func merged(with other: InputState) -> InputState {
        InputState(left: left || other.left, right: right || other.right, jump: jump || other.jump, action: action || other.action)
    }

    var horizontal: Double {
        (right ? 1 : 0) - (left ? 1 : 0)
    }
}

struct InputFrame: Equatable, Sendable {
    var held: InputState
    var pressed: InputState

    init(held: InputState, previous: InputState) {
        self.held = held
        pressed = InputState(
            left: held.left && !previous.left,
            right: held.right && !previous.right,
            jump: held.jump && !previous.jump,
            action: held.action && !previous.action
        )
    }
}
