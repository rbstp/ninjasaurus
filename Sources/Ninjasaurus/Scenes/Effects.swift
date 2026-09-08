import SpriteKit

@MainActor
final class Effects {
    private let textures: TextureStore
    private let parent: SKNode

    init(textures: TextureStore, parent: SKNode) {
        self.textures = textures
        self.parent = parent
    }

    func coinPop(at point: Vec2) {
        let coin = textures.sprite("tile.coin1", anchor: CGPoint(x: 0.5, y: 0.5))
        coin.position = CGPoint(x: point.x, y: point.y + 4)
        coin.zPosition = 30
        let frames = (1...4).map { textures.texture("tile.coin\($0)") }
        let spin = SKAction.repeat(SKAction.animate(with: frames, timePerFrame: 0.05), count: 3)
        let rise = SKAction.moveBy(x: 0, y: 40, duration: 0.3)
        rise.timingMode = .easeOut
        let fall = SKAction.moveBy(x: 0, y: -16, duration: 0.15)
        coin.run(SKAction.group([spin, SKAction.sequence([rise, fall, .fadeOut(withDuration: 0.1), .removeFromParent()])]))
        parent.addChild(coin)
    }

    func scorePopup(points: Int, at point: Vec2) {
        let text = PixelTextNode(points >= 1000 ? "\(points / 1000)000" : "\(points)", textures: textures, color: .white, alignment: .center)
        text.position = CGPoint(x: point.x, y: point.y + 2)
        text.zPosition = 31
        text.run(SKAction.sequence([.moveBy(x: 0, y: 24, duration: 0.6), .fadeOut(withDuration: 0.2), .removeFromParent()]))
        parent.addChild(text)
    }

    func label(_ string: String, at point: Vec2, color: SKColor = .white) {
        let text = PixelTextNode(string, textures: textures, color: color, alignment: .center)
        text.position = CGPoint(x: point.x, y: point.y + 2)
        text.zPosition = 31
        text.run(SKAction.sequence([.moveBy(x: 0, y: 24, duration: 0.8), .fadeOut(withDuration: 0.2), .removeFromParent()]))
        parent.addChild(text)
    }

    func brickBreak(col: Int, row: Int) {
        let rect = TileMap.rect(col: col, row: row)
        for (dx, dy) in [(-14.0, 60.0), (14.0, 60.0), (-10.0, 30.0), (10.0, 30.0)] {
            let chip = textures.sprite("fx.chip", anchor: CGPoint(x: 0.5, y: 0.5))
            chip.position = CGPoint(x: rect.midX + dx / 4, y: rect.midY + dy / 8)
            chip.zPosition = 30
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: dx * 1.5, y: -80), control: CGPoint(x: dx, y: dy))
            let fly = SKAction.follow(path, asOffset: true, orientToPath: false, duration: 0.7)
            let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.7)
            chip.run(SKAction.sequence([SKAction.group([fly, spin]), .removeFromParent()]))
            parent.addChild(chip)
        }
    }

    func puff(at point: Vec2) {
        let puff = textures.sprite("fx.puff1", anchor: CGPoint(x: 0.5, y: 0.5))
        puff.position = CGPoint(x: point.x, y: point.y)
        puff.zPosition = 30
        let frames = [textures.texture("fx.puff1"), textures.texture("fx.puff2")]
        puff.run(SKAction.sequence([.animate(with: frames, timePerFrame: 0.08), .removeFromParent()]))
        parent.addChild(puff)
    }

    func sparkle(at point: Vec2) {
        let spark = textures.sprite("fx.spark", anchor: CGPoint(x: 0.5, y: 0.5))
        spark.position = CGPoint(x: point.x, y: point.y)
        spark.zPosition = 30
        spark.run(SKAction.sequence([.scale(to: 1.6, duration: 0.15), .fadeOut(withDuration: 0.15), .removeFromParent()]))
        parent.addChild(spark)
    }

    func fireworks(at point: CGPoint, in node: SKNode, count: Int = 10, seed: UInt64) {
        var rng = SeededRandom(seed: seed)
        for _ in 0..<count {
            let star = textures.sprite("fx.star", anchor: CGPoint(x: 0.5, y: 0.5))
            star.position = point
            star.zPosition = 250
            let color: SKColor = [.systemYellow, .systemRed, .systemGreen, .cyan, .white][Int(rng.next() % 5)]
            star.color = color
            star.colorBlendFactor = 1
            let dx = rng.nextDouble(in: -70...70)
            let dy = rng.nextDouble(in: 20...90)
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: dx, y: dy - 60), control: CGPoint(x: dx / 2, y: dy))
            star.run(SKAction.sequence([
                SKAction.group([.follow(path, asOffset: true, orientToPath: false, duration: 0.9), .fadeOut(withDuration: 0.9)]),
                .removeFromParent(),
            ]))
            node.addChild(star)
        }
    }
}
