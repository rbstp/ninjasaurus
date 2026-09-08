import CoreGraphics
import SpriteKit

/// Parallax backdrops drawn with Core Graphics at the sprites' pixel density.
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

    private static let pixelsPerUnit: CGFloat = 2
    private static let layerWidth: CGFloat = 512
    private static let layerHeight: CGFloat = 176

    static func layers(for theme: Theme) -> Layers {
        Layers(sky: sky(for: theme), far: far(for: theme), near: near(for: theme))
    }

    private static func draw(width: CGFloat, height: CGFloat, _ body: (CGContext) -> Void) -> SKTexture {
        let context = CGContext(
            data: nil, width: Int(width * pixelsPerUnit), height: Int(height * pixelsPerUnit), bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        context.scaleBy(x: pixelsPerUnit, y: pixelsPerUnit)
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

    private static func gradient(_ context: CGContext, top: UInt32, bottom: UInt32, height: CGFloat) {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let gradient = CGGradient(colorsSpace: space, colors: [color(top), color(bottom)] as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: 0, y: 0), options: [])
    }

    /// Ellipse with an outline, a body colour and a highlight offset up and left.
    private static func blob(_ context: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, outline: UInt32, body: UInt32, light: UInt32) {
        context.setFillColor(color(outline))
        context.fillEllipse(in: CGRect(x: x - 1.5, y: y - 1.5, width: w + 3, height: h + 3))
        context.setFillColor(color(body))
        context.fillEllipse(in: CGRect(x: x, y: y, width: w, height: h))
        context.setFillColor(color(light))
        context.fillEllipse(in: CGRect(x: x + w * 0.12, y: y + h * 0.3, width: w * 0.6, height: h * 0.55))
    }

    private static func cloud(_ context: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, shade: UInt32, body: UInt32) {
        let h = w * 0.32
        for (dx, dw, dh) in [(0.0, 1.0, 1.0), (0.18, 0.5, 1.7), (0.5, 0.42, 1.45)] {
            context.setFillColor(color(shade))
            context.fillEllipse(in: CGRect(x: x + w * dx - 1.5, y: y - 1.5, width: w * dw + 3, height: h * dh + 3))
        }
        for (dx, dw, dh) in [(0.0, 1.0, 1.0), (0.18, 0.5, 1.7), (0.5, 0.42, 1.45)] {
            context.setFillColor(color(body))
            context.fillEllipse(in: CGRect(x: x + w * dx, y: y, width: w * dw, height: h * dh))
        }
        context.setFillColor(color(shade))
        context.fill(CGRect(x: x + 2, y: y, width: w - 4, height: h * 0.28))
    }

    private static func sky(for theme: Theme) -> SKTexture {
        draw(width: 4, height: layerHeight) { context in
            switch theme {
            case .grass: gradient(context, top: 0x2C88EC, bottom: 0xB0E4FC, height: layerHeight)
            case .cave: gradient(context, top: 0x0C1424, bottom: 0x2C3C60, height: layerHeight)
            case .sky: gradient(context, top: 0x1850C8, bottom: 0xD0F0FC, height: layerHeight)
            case .lava: gradient(context, top: 0x180408, bottom: 0x6C2418, height: layerHeight)
            }
        }
    }

    private static func far(for theme: Theme) -> SKTexture {
        draw(width: layerWidth, height: layerHeight) { context in
            switch theme {
            case .grass:
                for (x, w, h) in [(-40.0, 190.0, 96.0), (140.0, 260.0, 120.0), (350.0, 170.0, 84.0), (470.0, 150.0, 70.0)] {
                    blob(context, x: x, y: 22 - h / 2, w: w, h: h, outline: 0x246830, body: 0x50B050, light: 0x78D068)
                }
                context.setFillColor(color(0x246830))
                context.fill(CGRect(x: 0, y: 0, width: layerWidth, height: 26))
                context.setFillColor(color(0x3C9440))
                context.fill(CGRect(x: 0, y: 0, width: layerWidth, height: 22))
            case .cave:
                context.setFillColor(color(0x1A2640))
                context.fill(CGRect(x: 0, y: 150, width: layerWidth, height: 26))
                for x in stride(from: CGFloat(0), to: layerWidth, by: 44) {
                    let h = 34 + CGFloat(Int(x * 7) % 30)
                    for (inset, hex) in [(0.0, 0x1A2640), (5.0, 0x263858)] {
                        context.setFillColor(color(UInt32(hex)))
                        context.move(to: CGPoint(x: x + inset, y: 176))
                        context.addLine(to: CGPoint(x: x + 44 - inset, y: 176))
                        context.addLine(to: CGPoint(x: x + 22, y: 176 - h + inset * 1.5))
                        context.closePath()
                        context.fillPath()
                    }
                }
                context.setFillColor(color(0x1A2640))
                context.fill(CGRect(x: 0, y: 0, width: layerWidth, height: 14))
                for (x, h) in [(60.0, 20.0), (210.0, 26.0), (330.0, 16.0), (450.0, 22.0)] {
                    context.setFillColor(color(0x50B8D8, alpha: 0.35))
                    context.fillEllipse(in: CGRect(x: x - 16, y: 4, width: 32, height: h))
                    context.setFillColor(color(0x70D8F0))
                    context.move(to: CGPoint(x: x - 6, y: 14)); context.addLine(to: CGPoint(x: x, y: 14 + h)); context.addLine(to: CGPoint(x: x + 6, y: 14)); context.closePath(); context.fillPath()
                }
            case .sky:
                for (x, w) in [(10.0, 110.0), (170.0, 150.0), (350.0, 100.0), (460.0, 90.0)] {
                    cloud(context, x: x, y: 8, w: w, shade: 0x8CC0F0, body: 0xE8F4FF)
                }
            case .lava:
                for x in stride(from: CGFloat(0), to: layerWidth, by: 64) {
                    let h = 44 + CGFloat(Int(x * 5) % 50)
                    for (inset, hex) in [(0.0, 0x2C0C10), (5.0, 0x401418)] {
                        context.setFillColor(color(UInt32(hex)))
                        context.move(to: CGPoint(x: x - inset, y: 0))
                        context.addLine(to: CGPoint(x: x + 32, y: h - inset * 1.5))
                        context.addLine(to: CGPoint(x: x + 64 + inset, y: 0))
                        context.closePath()
                        context.fillPath()
                    }
                }
                context.setFillColor(color(0xF06020, alpha: 0.5))
                context.fill(CGRect(x: 0, y: 14, width: layerWidth, height: 2))
                context.setFillColor(color(0x2C0C10))
                context.fill(CGRect(x: 0, y: 0, width: layerWidth, height: 14))
            }
        }
    }

    private static func near(for theme: Theme) -> SKTexture {
        draw(width: layerWidth, height: layerHeight) { context in
            switch theme {
            case .grass:
                for (x, r) in [(60.0, 22.0), (100.0, 30.0), (280.0, 26.0), (320.0, 18.0), (440.0, 24.0)] {
                    blob(context, x: x - r, y: -r * 0.4, w: r * 2, h: r * 1.3, outline: 0x1C6028, body: 0x2C8C3C, light: 0x48B050)
                }
                for (x, w) in [(30.0, 70.0), (230.0, 96.0), (410.0, 64.0)] {
                    cloud(context, x: x, y: 130, w: w, shade: 0xA8D4F8, body: 0xFFFFFF)
                }
            case .cave:
                for (x, h) in [(50.0, 26.0), (200.0, 36.0), (340.0, 22.0), (470.0, 30.0)] {
                    context.setFillColor(color(0x60D0F0, alpha: 0.25))
                    context.fillEllipse(in: CGRect(x: x - 22, y: 0, width: 44, height: h + 10))
                    for (dx, dh, hex) in [(-9.0, 0.6, 0x3898B8), (0.0, 1.0, 0x70D8F0), (10.0, 0.75, 0x50B8D8)] {
                        context.setFillColor(color(UInt32(hex)))
                        context.move(to: CGPoint(x: x + dx - 5, y: 0)); context.addLine(to: CGPoint(x: x + dx, y: h * dh)); context.addLine(to: CGPoint(x: x + dx + 5, y: 0)); context.closePath(); context.fillPath()
                        context.setFillColor(color(0xC8F4FF))
                        context.move(to: CGPoint(x: x + dx - 1, y: 0)); context.addLine(to: CGPoint(x: x + dx, y: h * dh)); context.addLine(to: CGPoint(x: x + dx + 1, y: 0)); context.closePath(); context.fillPath()
                    }
                }
            case .sky:
                for (x, w) in [(0.0, 130.0), (220.0, 170.0), (420.0, 120.0)] {
                    cloud(context, x: x, y: 60, w: w, shade: 0xB0D8F8, body: 0xFFFFFF)
                }
            case .lava:
                for (x, w, h) in [(20.0, 30.0, 16.0), (150.0, 44.0, 22.0), (300.0, 26.0, 12.0), (430.0, 40.0, 18.0)] {
                    context.setFillColor(color(0x2C0C10))
                    context.fill(CGRect(x: x - 2, y: 0, width: w + 4, height: h + 2))
                    context.setFillColor(color(0x501C1C))
                    context.fill(CGRect(x: x, y: 0, width: w, height: h))
                    context.setFillColor(color(0x6C2C28))
                    context.fill(CGRect(x: x + 3, y: h - 4, width: w - 6, height: 3))
                }
                for (x, y, s) in [(40.0, 40.0, 3.0), (130.0, 110.0, 2.0), (230.0, 70.0, 3.0), (320.0, 150.0, 2.0), (400.0, 90.0, 3.0), (480.0, 130.0, 2.0), (90.0, 160.0, 2.0)] {
                    context.setFillColor(color(0xF89030, alpha: 0.6))
                    context.fill(CGRect(x: x - 1, y: y - 1, width: s + 2, height: s + 2))
                    context.setFillColor(color(0xFCC040))
                    context.fill(CGRect(x: x, y: y, width: s, height: s))
                }
            }
        }
    }
}
