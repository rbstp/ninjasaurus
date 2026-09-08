import CoreGraphics
import SpriteKit

@MainActor
final class TextureStore {
    private let atlas: SKTexture
    private let atlasSize: Int
    private let rects: [String: AtlasRect]
    private let scales: [String: Int]
    private var cache: [String: SKTexture] = [:]

    init() {
        let layout: AtlasLayout
        do {
            layout = try AtlasBuilder.buildFitting(SpriteArt.registry)
        } catch {
            fatalError("sprite atlas does not fit: \(error)")
        }
        atlasSize = layout.canvas.width
        rects = layout.rects
        scales = SpriteArt.registry.mapValues { $0.scale }
        atlas = TextureStore.makeTexture(from: layout.canvas)
        atlas.filteringMode = .nearest
    }

    func has(_ name: String) -> Bool {
        rects[name] != nil
    }

    func texture(_ name: String) -> SKTexture {
        if let cached = cache[name] { return cached }
        guard let rect = rects[name] else {
            assertionFailure("missing sprite \(name)")
            return cache["missing"] ?? texture("fx.missing")
        }
        let size = CGFloat(atlasSize)
        // Atlas rows count from the top; SpriteKit texture rects from the bottom.
        let unit = CGRect(
            x: CGFloat(rect.x) / size,
            y: 1 - CGFloat(rect.y + rect.height) / size,
            width: CGFloat(rect.width) / size,
            height: CGFloat(rect.height) / size
        )
        let texture = SKTexture(rect: unit, in: atlas)
        texture.filteringMode = .nearest
        cache[name] = texture
        return texture
    }

    func size(of name: String) -> CGSize {
        guard let rect = rects[name] else { return CGSize(width: 16, height: 16) }
        let scale = CGFloat(scales[name] ?? 1)
        return CGSize(width: CGFloat(rect.width) / scale, height: CGFloat(rect.height) / scale)
    }

    func sprite(_ name: String, anchor: CGPoint = CGPoint(x: 0.5, y: 0)) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture(name), size: size(of: name))
        node.anchorPoint = anchor
        node.name = name
        return node
    }

    static func makeTexture(from canvas: PixelCanvas) -> SKTexture {
        var bytes = canvas.bytes
        let image: CGImage = bytes.withUnsafeMutableBytes { buffer -> CGImage in
            let context = CGContext(
                data: buffer.baseAddress,
                width: canvas.width,
                height: canvas.height,
                bitsPerComponent: 8,
                bytesPerRow: canvas.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            )!
            return context.makeImage()!
        }
        return SKTexture(cgImage: image)
    }
}
