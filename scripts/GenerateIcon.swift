#!/usr/bin/env swift
// Renders the app icon: run `make icon`.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let size = 1024

let palette: [Character: (CGFloat, CGFloat, CGFloat)] = [
    "K": (0x20, 0x28, 0x38), "D": (0x10, 0x18, 0x20), "H": (0x3C, 0x48, 0x68), "R": (0x28, 0x68, 0xE8),
    "S": (0xFC, 0xBC, 0x8C), "E": (0xFF, 0xFF, 0xFF), "P": (0x00, 0x00, 0x00), "Y": (0xF8, 0xC8, 0x38),
]

let ninja = [
    "......KKKK......", ".....KKKKKK.....", "....KKKKKKKK....", "....KKKKKKKK....",
    "..RRRRRRRRRRR...", ".R..KSSSSSSK....", "R...KSEPSEPK....", "....KSSSSSSK....",
    "....KKSSSSKK....", ".....KKKKKK.....", "....KKKKKKKK....", "...KKKKKKKKKK...",
    "..KKKKKHHKKKKK..", "..KKKKKHHKKKKK..", "..SKKKKHHKKKKS..", "..S.KKKKKKKK.S..",
    "....KKYYYYKK....", "....KKYYYYKK....", "....KKKKKKKK....", "....KKKKKKKK....",
    "....KKKKKKKK....", "....KKK..KKK....", "....KKK..KKK....", "....KKK..KKK....",
    "....KKK..KKK....", "....KKK..KKK....", "....KKK..KKK....", "....KKK..KKK....",
    "....KKK..KKK....", "....KKK..KKK....", "...DDDD..DDDD...", "...DDDD..DDDD...",
]

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.setAllowsAntialiasing(false)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1)
}

// Sky
let gradient = CGGradient(colorsSpace: space, colors: [rgb(0x3C, 0x98, 0xF0), rgb(0xA8, 0xE0, 0xFC)] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

// Sun
context.setFillColor(rgb(0xF8, 0xE0, 0x48))
context.fillEllipse(in: CGRect(x: 720, y: 720, width: 180, height: 180))

// Hills and ground
context.setFillColor(rgb(0x58, 0xB8, 0x58))
context.fillEllipse(in: CGRect(x: -100, y: 60, width: 600, height: 300))
context.fillEllipse(in: CGRect(x: 500, y: 40, width: 700, height: 320))
context.setFillColor(rgb(0x38, 0xA8, 0x48))
context.fill(CGRect(x: 0, y: 96, width: size, height: 64))
context.setFillColor(rgb(0xA8, 0x68, 0x28))
context.fill(CGRect(x: 0, y: 0, width: size, height: 96))

// Ninja, 16x32 pixels drawn at 24x
let scale = 24
let originX = (size - 16 * scale) / 2
let originY = 160
for (row, line) in ninja.enumerated() {
    for (col, char) in line.enumerated() {
        guard let color = palette[char] else { continue }
        context.setFillColor(rgb(color.0, color.1, color.2))
        let y = originY + (ninja.count - 1 - row) * scale
        context.fill(CGRect(x: originX + col * scale, y: y, width: scale, height: scale))
    }
}

let image = context.makeImage()!
let url = URL(fileURLWithPath: output)
let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write("failed to write \(output)\n".data(using: .utf8)!)
    exit(1)
}
print("wrote \(output)")
