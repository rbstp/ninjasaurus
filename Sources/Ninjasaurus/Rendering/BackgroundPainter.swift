import CoreGraphics
import SpriteKit

@MainActor
enum BackgroundPainter {
    struct Layers {
        let sky: SKTexture
        let far: SKTexture
        let near: SKTexture
        let farFactor: CGFloat = 0.3
        let nearFactor: CGFloat = 0.6
        let tileWidth: CGFloat = 512
    }

    private static let scale = 4
    private static let layerWidth = 128
    private static let layerHeight = 52

    static func layers(for theme: Theme) -> Layers {
        Layers(sky: sky(for: theme), far: far(for: theme), near: near(for: theme))
    }

    // MARK: - Drawing helpers

    private static func draw(width: Int, height: Int, _ body: (CGContext) -> Void) -> SKTexture {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        body(context)
        let texture = SKTexture(cgImage: context.makeImage()!)
        texture.filteringMode = .nearest
        return texture
    }

    private static func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
        CGColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    private static func gradient(_ context: CGContext, top: UInt32, bottom: UInt32, height: Int) {
        let steps = 8
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps - 1)
            let mix = { (a: UInt32, b: UInt32, shift: UInt32) -> CGFloat in
                let ca = CGFloat((a >> shift) & 0xFF), cb = CGFloat((b >> shift) & 0xFF)
                return (ca + (cb - ca) * t) / 255
            }
            context.setFillColor(CGColor(srgbRed: mix(top, bottom, 16), green: mix(top, bottom, 8), blue: mix(top, bottom, 0), alpha: 1))
            let bandHeight = CGFloat(height) / CGFloat(steps)
            context.fill(CGRect(x: 0, y: CGFloat(height) - CGFloat(i + 1) * bandHeight, width: 1, height: bandHeight + 1))
        }
    }

    private static func sky(for theme: Theme) -> SKTexture {
        draw(width: 1, height: layerHeight) { context in
            switch theme {
            case .grass: gradient(context, top: 0x3C98F0, bottom: 0xA8E0FC, height: layerHeight)
            case .cave: gradient(context, top: 0x101828, bottom: 0x283858, height: layerHeight)
            case .sky: gradient(context, top: 0x2060D0, bottom: 0xC8ECFC, height: layerHeight)
            case .lava: gradient(context, top: 0x200810, bottom: 0x602018, height: layerHeight)
            }
        }
    }

    private static func far(for theme: Theme) -> SKTexture {
        draw(width: layerWidth, height: layerHeight) { context in
            switch theme {
            case .grass:
                context.setFillColor(color(0x58B858))
                for (x, r) in [(10, 22), (48, 30), (92, 18), (124, 26)] {
                    context.fillEllipse(in: CGRect(x: x - r, y: 8 - r / 2, width: 2 * r, height: r + r / 2))
                }
                context.setFillColor(color(0x489848))
                context.fill(CGRect(x: 0, y: 0, width: layerWidth, height: 9))
            case .cave:
                context.setFillColor(color(0x1C2840))
                for x in stride(from: 0, to: layerWidth, by: 12) {
                    let h = 10 + (x * 7) % 14
                    context.move(to: CGPoint(x: x, y: layerHeight))
                    context.addLine(to: CGPoint(x: x + 12, y: layerHeight))
                    context.addLine(to: CGPoint(x: x + 6, y: layerHeight - h))
                    context.closePath()
                    context.fillPath()
                }
                context.fill(CGRect(x: 0, y: 0, width: layerWidth, height: 6))
            case .sky:
                context.setFillColor(color(0xFFFFFF, alpha: 0.8))
                for (x, w) in [(4, 26), (44, 34), (90, 22), (112, 20)] {
                    context.fillEllipse(in: CGRect(x: x, y: 4, width: w, height: 8))
                    context.fillEllipse(in: CGRect(x: x + w / 4, y: 7, width: w / 2, height: 8))
                }
            case .lava:
                context.setFillColor(color(0x381010))
                for x in stride(from: 0, to: layerWidth, by: 16) {
                    let h = 12 + (x * 5) % 16
                    context.move(to: CGPoint(x: x, y: 0))
                    context.addLine(to: CGPoint(x: x + 8, y: h))
                    context.addLine(to: CGPoint(x: x + 16, y: 0))
                    context.closePath()
                    context.fillPath()
                }
                context.fill(CGRect(x: 0, y: 0, width: layerWidth, height: 5))
            }
        }
    }

    private static func near(for theme: Theme) -> SKTexture {
        draw(width: layerWidth, height: layerHeight) { context in
            switch theme {
            case .grass:
                context.setFillColor(color(0x2C8838))
                for (x, r) in [(20, 6), (30, 8), (72, 7), (82, 5), (110, 6)] {
                    context.fillEllipse(in: CGRect(x: x - r, y: 0, width: 2 * r, height: r + 4))
                }
                context.setFillColor(color(0xFFFFFF, alpha: 0.9))
                for (x, w) in [(8, 18), (60, 24), (104, 16)] {
                    context.fillEllipse(in: CGRect(x: x, y: 36, width: w, height: 6))
                    context.fillEllipse(in: CGRect(x: x + w / 4, y: 38, width: w / 2, height: 7))
                }
            case .cave:
                context.setFillColor(color(0x60C8E8, alpha: 0.9))
                for (x, h) in [(14, 6), (52, 9), (88, 5), (118, 7)] {
                    context.move(to: CGPoint(x: x, y: 0))
                    context.addLine(to: CGPoint(x: x + 3, y: h))
                    context.addLine(to: CGPoint(x: x + 6, y: 0))
                    context.closePath()
                    context.fillPath()
                }
            case .sky:
                context.setFillColor(color(0xFFFFFF))
                for (x, w) in [(0, 30), (58, 40), (104, 24)] {
                    context.fillEllipse(in: CGRect(x: x, y: 20, width: w, height: 10))
                    context.fillEllipse(in: CGRect(x: x + w / 4, y: 24, width: w / 2, height: 10))
                }
            case .lava:
                context.setFillColor(color(0xF89030, alpha: 0.9))
                for (x, y) in [(10, 12), (34, 30), (58, 18), (80, 40), (100, 22), (120, 34)] {
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
                context.setFillColor(color(0x501818))
                for x in stride(from: 4, to: layerWidth, by: 24) {
                    context.fill(CGRect(x: x, y: 0, width: 6, height: 4 + (x % 5)))
                }
            }
        }
    }
}
