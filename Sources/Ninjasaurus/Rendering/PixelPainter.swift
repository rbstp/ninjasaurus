import Foundation

extension PixelColor {
    func mixed(with other: PixelColor, _ t: Double) -> PixelColor {
        func mix(_ a: UInt8, _ b: UInt8) -> UInt8 { UInt8(max(0, min(255, Double(a) + (Double(b) - Double(a)) * t))) }
        return PixelColor(r: mix(r, other.r), g: mix(g, other.g), b: mix(b, other.b), a: a)
    }

    func lightened(_ t: Double) -> PixelColor { mixed(with: .white, t) }
    func darkened(_ t: Double) -> PixelColor { mixed(with: .black, t) }
}

/// Draws shapes into a pixel grid, top-left origin, y down. Coordinates are
/// pixel indices; ellipses and polygons test pixel centres.
struct PixelPainter {
    let width: Int
    let height: Int
    private(set) var pixels: [PixelColor]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        pixels = Array(repeating: .clear, count: width * height)
    }

    subscript(x: Int, y: Int) -> PixelColor {
        get {
            guard x >= 0, x < width, y >= 0, y < height else { return .clear }
            return pixels[y * width + x]
        }
        set {
            guard x >= 0, x < width, y >= 0, y < height else { return }
            pixels[y * width + x] = newValue
        }
    }

    mutating func fillRect(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ color: PixelColor, over: PixelColor? = nil) {
        for y in min(y0, y1)...max(y0, y1) {
            for x in min(x0, x1)...max(x0, x1) {
                if let over, self[x, y] != over { continue }
                self[x, y] = color
            }
        }
    }

    mutating func fillEllipse(cx: Double, cy: Double, rx: Double, ry: Double, _ color: PixelColor, over: PixelColor? = nil) {
        let x0 = max(0, Int(floor(cx - rx))), x1 = min(width - 1, Int(ceil(cx + rx)))
        let y0 = max(0, Int(floor(cy - ry))), y1 = min(height - 1, Int(ceil(cy + ry)))
        guard x0 <= x1, y0 <= y1 else { return }
        for y in y0...y1 {
            for x in x0...x1 {
                let dx = (Double(x) + 0.5 - cx) / rx
                let dy = (Double(y) + 0.5 - cy) / ry
                guard dx * dx + dy * dy <= 1 else { continue }
                if let over, self[x, y] != over { continue }
                self[x, y] = color
            }
        }
    }

    /// Ellipse with a highlight towards the top-left and a shadow rim bottom-right.
    mutating func shadedEllipse(cx: Double, cy: Double, rx: Double, ry: Double, _ color: PixelColor, light: Double = 0.25, dark: Double = 0.25) {
        fillEllipse(cx: cx, cy: cy, rx: rx, ry: ry, color.darkened(dark))
        fillEllipse(cx: cx - rx * 0.08, cy: cy - ry * 0.12, rx: rx * 0.9, ry: ry * 0.86, color)
        fillEllipse(cx: cx - rx * 0.3, cy: cy - ry * 0.35, rx: rx * 0.4, ry: ry * 0.3, color.lightened(light))
    }

    mutating func fillPolygon(_ points: [(Double, Double)], _ color: PixelColor) {
        guard points.count >= 3 else { return }
        let ys = points.map { $0.1 }
        let y0 = max(0, Int(floor(ys.min()!))), y1 = min(height - 1, Int(ceil(ys.max()!)))
        guard y0 <= y1 else { return }
        for y in y0...y1 {
            let sy = Double(y) + 0.5
            var crossings: [Double] = []
            for i in points.indices {
                let (ax, ay) = points[i]
                let (bx, by) = points[(i + 1) % points.count]
                if (ay <= sy && by > sy) || (by <= sy && ay > sy) {
                    crossings.append(ax + (sy - ay) / (by - ay) * (bx - ax))
                }
            }
            crossings.sort()
            var i = 0
            while i + 1 < crossings.count {
                let xa = Int(floor(crossings[i] + 0.5)), xb = Int(ceil(crossings[i + 1] - 0.5))
                if xa <= xb { fillRect(xa, y, xb, y, color) }
                i += 2
            }
        }
    }

    mutating func line(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ color: PixelColor, thickness: Int = 1) {
        var x = x0, y = y0
        let dx = abs(x1 - x0), dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            if thickness > 1 {
                fillRect(x, y, x + thickness - 1, y + thickness - 1, color)
            } else {
                self[x, y] = color
            }
            if x == x1 && y == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x += sx }
            if e2 <= dx { err += dx; y += sy }
        }
    }

    mutating func replace(_ from: PixelColor, with to: PixelColor) {
        for i in pixels.indices where pixels[i] == from { pixels[i] = to }
    }

    /// Opaque pixels touching transparency become the outline colour.
    mutating func outline(_ color: PixelColor) {
        var out = pixels
        for y in 0..<height {
            for x in 0..<width where !self[x, y].isTransparent {
                if self[x - 1, y].isTransparent || self[x + 1, y].isTransparent || self[x, y - 1].isTransparent || self[x, y + 1].isTransparent {
                    out[y * width + x] = color
                }
            }
        }
        pixels = out
    }

    /// Rim light under the top edge, shadow above the bottom edge.
    mutating func bevel(outline: PixelColor, light: Double = 0.3, dark: Double = 0.25) {
        var out = pixels
        for y in 0..<height {
            for x in 0..<width {
                let c = self[x, y]
                guard !c.isTransparent, c != outline else { continue }
                let up = self[x, y - 1], down = self[x, y + 1], left = self[x - 1, y], right = self[x + 1, y]
                if up == outline || up.isTransparent {
                    out[y * width + x] = c.lightened(light)
                } else if down == outline || down.isTransparent {
                    out[y * width + x] = c.darkened(dark)
                } else if left == outline || left.isTransparent {
                    out[y * width + x] = c.lightened(light * 0.5)
                } else if right == outline || right.isTransparent {
                    out[y * width + x] = c.darkened(dark * 0.6)
                }
            }
        }
        pixels = out
    }

    /// Transparent pixels touching an opaque one (8 neighbours) become the outline colour.
    mutating func outlineOutward(_ color: PixelColor) {
        var out = pixels
        for y in 0..<height {
            for x in 0..<width where self[x, y].isTransparent {
                var touches = false
                for dy in -1...1 {
                    for dx in -1...1 where !(dx == 0 && dy == 0) {
                        if !self[x + dx, y + dy].isTransparent { touches = true }
                    }
                }
                if touches { out[y * width + x] = color }
            }
        }
        pixels = out
    }

    /// EPX / Scale2x: doubles the size and rounds staircase edges.
    func scaled2x() -> PixelPainter {
        var out = PixelPainter(width: width * 2, height: height * 2)
        for y in 0..<height {
            for x in 0..<width {
                let p = self[x, y]
                let a = self[x, y - 1], b = self[x + 1, y], c = self[x - 1, y], d = self[x, y + 1]
                var tl = p, tr = p, bl = p, br = p
                if c == a && c != d && a != b { tl = a }
                if a == b && a != c && b != d { tr = b }
                if d == c && d != b && c != a { bl = c }
                if b == d && b != a && d != c { br = d }
                out[x * 2, y * 2] = tl
                out[x * 2 + 1, y * 2] = tr
                out[x * 2, y * 2 + 1] = bl
                out[x * 2 + 1, y * 2 + 1] = br
            }
        }
        return out
    }

    func flippedHorizontally() -> PixelPainter {
        var out = self
        for y in 0..<height {
            for x in 0..<width {
                out[x, y] = self[width - 1 - x, y]
            }
        }
        return out
    }

    func sprite(scale: Int = 2) -> PixelSprite {
        PixelSprite(width: width, height: height, pixels: pixels, scale: scale)
    }
}
