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

let gradient = CGGradient(colorsSpace: space, colors: [rgb(0x3C98F0), rgb(0xA8E0FC)] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
context.setFillColor(rgb(0xF8E048))
context.fillEllipse(in: CGRect(x: 740, y: 740, width: 170, height: 170))
for (x, r) in [(120, 320), (820, 360)] {
    context.setFillColor(rgb(0x2C7838))
    context.fillEllipse(in: CGRect(x: x - r - 8, y: 150 - r / 2, width: 2 * r + 16, height: r + 8))
    context.setFillColor(rgb(0x58B858))
    context.fillEllipse(in: CGRect(x: x - r, y: 150 - r / 2, width: 2 * r, height: r))
    context.setFillColor(rgb(0x80D870))
    context.fillEllipse(in: CGRect(x: x - r / 2, y: 190, width: r, height: r / 3))
}

let ground = SpriteArt.groundTop(SpriteArt.grounds[.grass]!)
let tile = 128
for x in stride(from: 0, to: size, by: tile) {
    draw(ground, x: x, y: 0, scale: tile / ground.width)
}

let ninja = SpriteArt.bigNinja(.standard, .idle)
let ninjaScale = 12
draw(ninja, x: (size - ninja.width * ninjaScale) / 2 - 60, y: tile, scale: ninjaScale)
let raptor = SpriteArt.raptor(.walk1).flippedHorizontally()
draw(raptor, x: 640, y: tile, scale: 9)

let image = context.makeImage()!
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write("failed to write \(output)\n".data(using: .utf8)!)
    exit(1)
}
print("wrote \(output)")
