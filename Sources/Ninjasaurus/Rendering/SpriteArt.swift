enum SpriteArt {
    static let registry: [String: PixelSprite] = {
        var all: [String: PixelSprite] = [:]
        all.merge(PixelFont.sprites) { _, new in new }
        all.merge(effects) { _, new in new }
        all.merge(ninja) { _, new in new }
        all.merge(dinos) { _, new in new }
        all.merge(scenery) { _, new in new }
        return all
    }()

    static let effects: [String: PixelSprite] = {
        var out: [String: PixelSprite] = [:]
        out["fx.missing"] = PixelSprite(palette: ["M": Colors.magenta], rows: Array(repeating: String(repeating: "M", count: 8), count: 8))
        out["fx.white"] = PixelSprite(palette: ["W": .white], rows: Array(repeating: String(repeating: "W", count: 8), count: 8))
        return out
    }()

    /// Reserved for atlas packing checks: every registered sprite and its scale.
    static var scales: [String: Double] { registry.mapValues { $0.scale } }
}
