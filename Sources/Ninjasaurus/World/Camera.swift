struct CameraState: Equatable, Sendable {
    var x: Double
    var y: Double

    func rect(viewSize: Vec2) -> AABB {
        AABB(minX: x - viewSize.x / 2, minY: y - viewSize.y / 2, width: viewSize.x, height: viewSize.y)
    }

    var rounded: CameraState {
        CameraState(x: x.rounded(), y: y.rounded())
    }
}

enum Camera {
    static func initial(playerRect: AABB, viewSize: Vec2, levelSize: Vec2) -> CameraState {
        CameraState(
            x: clamp(playerRect.midX, extent: viewSize.x, limit: levelSize.x),
            y: levelSize.y <= viewSize.y ? levelSize.y / 2 : clamp(playerRect.midY, extent: viewSize.y, limit: levelSize.y)
        )
    }

    static func update(
        _ camera: CameraState, playerRect: AABB, facing: Facing, onGround: Bool, viewSize: Vec2, levelSize: Vec2
    ) -> CameraState {
        var next = camera
        let target = playerRect.midX + facing.sign * GameConstants.cameraLookahead
        next.x += (target - next.x) * GameConstants.cameraFollowRate
        next.x = clamp(next.x, extent: viewSize.x, limit: levelSize.x)

        if levelSize.y <= viewSize.y {
            next.y = levelSize.y / 2
        } else {
            let dy = playerRect.midY - next.y
            let hard = GameConstants.cameraVerticalHardZone
            let dead = GameConstants.cameraVerticalDeadZone
            if abs(dy) > hard {
                next.y += dy - hard * (dy > 0 ? 1 : -1)
            } else if onGround && abs(dy) > dead {
                next.y += (dy - dead * (dy > 0 ? 1 : -1)) * 0.15
            }
            next.y = clamp(next.y, extent: viewSize.y, limit: levelSize.y)
        }
        return next
    }

    static func clamp(_ value: Double, extent: Double, limit: Double) -> Double {
        let half = extent / 2
        if limit <= extent { return limit / 2 }
        return min(max(value, half), limit - half)
    }
}
