import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders the app icon from the game's own sprite art. Run `make icon`.
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.setAllowsAntialiasing(false)

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

func draw(_ sprite: PixelSprite, x originX: Int, y originY: Int, scale: Int) {
    for y in 0..<sprite.height {
        for x in 0..<sprite.width {
            let c = sprite.pixel(x: x, y: y)
            guard !c.isTransparent else { continue }
            context.setFillColor(CGColor(srgbRed: CGFloat(c.r) / 255, green: CGFloat(c.g) / 255, blue: CGFloat(c.b) / 255, alpha: 1))
            let py = originY + (sprite.height - 1 - y) * scale
            context.fill(CGRect(x: originX + x * scale, y: py, width: scale, height: scale))
        }
    }
}

let gradient = CGGradient(colorsSpace: space, colors: [rgb(0x180408), rgb(0x7C2C18)] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
for (x, w, h) in [(-80, 360, 420), (300, 300, 300), (620, 420, 520), (900, 260, 340)] {
    context.setFillColor(rgb(0x2C0C10))
    context.move(to: CGPoint(x: x, y: 128)); context.addLine(to: CGPoint(x: x + w / 2, y: 128 + h)); context.addLine(to: CGPoint(x: x + w, y: 128)); context.closePath(); context.fillPath()
    context.setFillColor(rgb(0x421418))
    context.move(to: CGPoint(x: x + 30, y: 128)); context.addLine(to: CGPoint(x: x + w / 2, y: 128 + h - 60)); context.addLine(to: CGPoint(x: x + w - 30, y: 128)); context.closePath(); context.fillPath()
}
for (x, y, s) in [(120, 560, 14), (260, 760, 10), (520, 880, 12), (700, 640, 10), (860, 820, 14), (960, 520, 10), (400, 620, 8)] {
    context.setFillColor(rgb(0xF89030))
    context.fill(CGRect(x: x - 3, y: y - 3, width: s + 6, height: s + 6))
    context.setFillColor(rgb(0xFCC040))
    context.fill(CGRect(x: x, y: y, width: s, height: s))
}

let ground = SpriteArt.groundTop(SpriteArt.grounds[.lava]!)
let lavaTile = SpriteArt.lava(0)
let tile = 128
for (index, x) in stride(from: 0, to: size, by: tile).enumerated() {
    draw(index == 0 || index == 7 ? lavaTile : ground, x: x, y: 0, scale: tile / ground.width)
}

let ninja = SpriteArt.bigNinja(.standard, .idle)
draw(ninja, x: 150, y: tile, scale: 9)
let rex = SpriteArt.rex(.roar).flippedHorizontally()
draw(rex, x: 400, y: tile, scale: 10)

let image = context.makeImage()!
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write("failed to write \(output)\n".data(using: .utf8)!)
    exit(1)
}
print("wrote \(output)")
