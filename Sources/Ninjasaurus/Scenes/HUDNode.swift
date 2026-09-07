import SpriteKit

final class HUDNode: SKNode {
    private let textures: TextureStore
    private let livesText: PixelTextNode
    private let coinsText: PixelTextNode
    private let scoreText: PixelTextNode
    private let livesIcon: SKSpriteNode
    private let coinIcon: SKSpriteNode
    private let pauseIcon: SKSpriteNode
    private var hearts: [SKSpriteNode] = []
    private var lastLives = -1
    private var lastCoins = -1
    private var lastScore = -1

    init(textures: TextureStore) {
        self.textures = textures
        livesText = PixelTextNode("x0", textures: textures)
        coinsText = PixelTextNode("x0", textures: textures, color: SKColor(red: 1, green: 0.9, blue: 0.4, alpha: 1))
        scoreText = PixelTextNode("000000", textures: textures, alignment: .center)
        livesIcon = textures.sprite("hud.ninjaHead", anchor: .zero)
        coinIcon = textures.sprite("hud.coin", anchor: .zero)
        pauseIcon = textures.sprite("hud.pause", anchor: CGPoint(x: 1, y: 1))
        super.init()
        zPosition = 100
        for node in [livesIcon, coinIcon, pauseIcon] { addChild(node) }
        for node in [livesText, coinsText, scoreText] { addChild(node) }
        pauseIcon.setScale(2)
        for _ in 0..<GameConstants.rexHitPoints {
            let heart = textures.sprite("hud.heart", anchor: CGPoint(x: 0.5, y: 1))
            heart.isHidden = true
            hearts.append(heart)
            addChild(heart)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("not used")
    }

    private(set) var pauseRect = CGRect.zero

    func layout(sceneSize: CGSize, insets: SafeInsets) {
        let left = -sceneSize.width / 2 + CGFloat(insets.left) + 6
        let top = sceneSize.height / 2 - CGFloat(insets.top) - 6
        let right = sceneSize.width / 2 - CGFloat(insets.right) - 6
        livesIcon.position = CGPoint(x: left, y: top - 8)
        livesText.position = CGPoint(x: left + 10, y: top - 8)
        coinIcon.position = CGPoint(x: left, y: top - 20)
        coinsText.position = CGPoint(x: left + 10, y: top - 20)
        scoreText.position = CGPoint(x: 0, y: top - 8)
        pauseIcon.position = CGPoint(x: right, y: top)
        pauseRect = CGRect(x: right - 28, y: top - 28, width: 40, height: 40)
        for (index, heart) in hearts.enumerated() {
            heart.position = CGPoint(x: CGFloat(index - 1) * 12, y: top - 18)
        }
    }

    func update(lives: Int, coins: Int, score: Int, bossHitPoints: Int?) {
        if lives != lastLives {
            livesText.text = "x\(lives)"
            lastLives = lives
        }
        if coins != lastCoins {
            coinsText.text = "x\(coins)"
            lastCoins = coins
        }
        if score != lastScore {
            scoreText.text = String(format: "%06d", min(score, 999_999))
            lastScore = score
        }
        for (index, heart) in hearts.enumerated() {
            guard let hp = bossHitPoints else {
                heart.isHidden = true
                continue
            }
            heart.isHidden = false
            let name = index < hp ? "hud.heart" : "hud.heartEmpty"
            if heart.name != name {
                heart.texture = textures.texture(name)
                heart.name = name
            }
        }
    }
}
