import GameController

@MainActor
final class GamepadInput {
    var input: InputState {
        var state = InputState.none
        if let pad = GCController.controllers().first?.extendedGamepad {
            state.left = pad.dpad.left.isPressed || pad.leftThumbstick.xAxis.value < -0.4
            state.right = pad.dpad.right.isPressed || pad.leftThumbstick.xAxis.value > 0.4
            state.jump = pad.buttonA.isPressed
            state.action = pad.buttonB.isPressed || pad.buttonX.isPressed
        }
        if let keys = GCKeyboard.coalesced?.keyboardInput {
            state.left = state.left || keys.button(forKeyCode: .leftArrow)?.isPressed == true || keys.button(forKeyCode: .keyA)?.isPressed == true
            state.right = state.right || keys.button(forKeyCode: .rightArrow)?.isPressed == true || keys.button(forKeyCode: .keyD)?.isPressed == true
            state.jump = state.jump || keys.button(forKeyCode: .spacebar)?.isPressed == true || keys.button(forKeyCode: .upArrow)?.isPressed == true
            state.action = state.action || keys.button(forKeyCode: .keyX)?.isPressed == true || keys.button(forKeyCode: .leftShift)?.isPressed == true
        }
        return state
    }
}
