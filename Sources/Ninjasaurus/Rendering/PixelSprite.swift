enum PixelSpriteError: Error, Equatable {
    case emptySprite
    case raggedRow(index: Int)
    case unknownCharacter(Character, row: Int)
}

struct PixelSprite: Equatable, Sendable {
    let width: Int
    let height: Int
    let pixels: [PixelColor]

    init(width: Int, height: Int, pixels: [PixelColor]) {
        precondition(pixels.count == width * height, "pixel count mismatch")
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    init(palette: Palette, rows: [String]) {
        do {
            self = try PixelSprite(validating: palette, rows: rows)
        } catch {
            fatalError("bad sprite: \(error)\n\(rows.joined(separator: "\n"))")
        }
    }

    init(validating palette: Palette, rows: [String]) throws {
        guard let first = rows.first, !first.isEmpty else { throw PixelSpriteError.emptySprite }
        let width = first.count
        var pixels: [PixelColor] = []
        pixels.reserveCapacity(width * rows.count)
        for (rowIndex, row) in rows.enumerated() {
            guard row.count == width else { throw PixelSpriteError.raggedRow(index: rowIndex) }
            for char in row {
                if char == "." {
                    pixels.append(.clear)
                } else if let color = palette[char] {
                    pixels.append(color)
                } else {
                    throw PixelSpriteError.unknownCharacter(char, row: rowIndex)
                }
            }
        }
        self.init(width: width, height: rows.count, pixels: pixels)
    }

    func pixel(x: Int, y: Int) -> PixelColor {
        pixels[y * width + x]
    }

    func flippedHorizontally() -> PixelSprite {
        var out = pixels
        for y in 0..<height {
            for x in 0..<width {
                out[y * width + x] = pixels[y * width + (width - 1 - x)]
            }
        }
        return PixelSprite(width: width, height: height, pixels: out)
    }

    func recolored(_ transform: (PixelColor) -> PixelColor) -> PixelSprite {
        PixelSprite(width: width, height: height, pixels: pixels.map { $0.isTransparent ? $0 : transform($0) })
    }

    func recolored(mapping: [PixelColor: PixelColor]) -> PixelSprite {
        recolored { mapping[$0] ?? $0 }
    }

    func flashedWhite() -> PixelSprite {
        recolored { _ in .white }
    }

    func silhouette(_ color: PixelColor) -> PixelSprite {
        recolored { _ in color }
    }
}
