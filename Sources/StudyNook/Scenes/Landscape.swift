import SwiftUI

/// Shared pieces of the scenes: sky, sun, clouds, sea, King's Landing, Dragonstone.
/// `u` is the scene unit: 1 at the normal card height of 118 pt.
enum Landscape {
    static func sky(_ c: GraphicsContext, _ size: CGSize, top: RGB, bottom: RGB, horizon: CGFloat) {
        c.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [top.color(), bottom.color()]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)
        ))
    }

    static func sun(_ c: GraphicsContext, at p: CGPoint, radius r: CGFloat, color: RGB, glow: Double) {
        c.fill(Ink.circle(p, r * 5), with: .radialGradient(
            Gradient(colors: [color.color(0.45 * glow), color.color(0)]),
            center: p, startRadius: r * 0.5, endRadius: r * 5
        ))
        c.fill(Ink.circle(p, r), with: .radialGradient(
            Gradient(colors: [RGB(1, 0.98, 0.9).color(), color.color()]),
            center: p, startRadius: 0, endRadius: r
        ))
    }

    static func stars(_ c: GraphicsContext, _ size: CGSize, u: CGFloat, t: Double, opacity: Double, maxY: CGFloat, count: Int) {
        guard opacity > 0.01 else { return }
        for i in 0..<count {
            let p = CGPoint(x: CGFloat(M.rand(i, 1)) * size.width, y: CGFloat(M.rand(i, 2)) * maxY)
            let twinkle = 0.45 + 0.55 * sin(t * (0.8 + M.rand(i, 3) * 2) + Double(i))
            let a = opacity * max(0.15, twinkle)
            if i % 9 == 0 {
                c.fill(Ink.sparkle(p, 2.2 * u), with: .color(.white.opacity(a)))
            } else {
                c.fill(Ink.circle(p, (0.35 + CGFloat(M.rand(i, 4)) * 0.6) * u), with: .color(.white.opacity(a)))
            }
        }
    }

    static func clouds(_ c: GraphicsContext, _ size: CGSize, u: CGFloat, t: Double, tint: RGB, opacity: Double) {
        let puffs: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(-13, 2, 11, 5), (-3, -2, 10, 6.5), (8, 1, 11, 5.5), (0, 3, 18, 4)]
        let span = size.width + 120 * u
        for i in 0..<6 {
            let speed = (2.0 + 4.0 * M.rand(i, 7)) * Double(u)
            let phase = M.fract((M.rand(i, 8) * Double(span) - t * speed) / Double(span))
            let x = CGFloat(phase) * span - 60 * u
            let y = size.height * CGFloat(0.08 + 0.30 * M.rand(i, 9))
            let s = CGFloat(0.55 + 0.6 * M.rand(i, 10)) * u
            var cloud = Path()
            for (dx, dy, rx, ry) in puffs {
                cloud.addPath(Ink.ellipse(CGPoint(x: x + dx * s, y: y + dy * s), rx * s, ry * s))
            }
            c.fill(cloud, with: .color(tint.color(opacity * (0.4 + 0.3 * M.rand(i, 11)))))
        }
    }

    static func sea(_ c: GraphicsContext, _ size: CGSize, horizon hy: CGFloat, u: CGFloat, t: Double,
                    top: RGB, bottom: RGB, glint: RGB?, glintX: CGFloat) {
        let w = size.width, h = size.height
        c.fill(Path(CGRect(x: 0, y: hy, width: w, height: h - hy)), with: .linearGradient(
            Gradient(colors: [top.color(), bottom.color()]),
            startPoint: CGPoint(x: 0, y: hy), endPoint: CGPoint(x: 0, y: h)
        ))
        c.fill(Path(CGRect(x: 0, y: hy - 0.4 * u, width: w, height: 1.0 * u)), with: .color(.white.opacity(0.14)))

        // Sun or moon path on the water.
        if let glint {
            for k in 0..<7 {
                let y = hy + (2 + CGFloat(k) * 4.4) * u
                guard y < h else { break }
                let half = (10 - CGFloat(k)) * u * CGFloat(0.65 + 0.35 * sin(t * 3 + Double(k) * 1.3))
                let a = 0.4 * (1 - Double(k) / 8)
                c.fill(Path(roundedRect: CGRect(x: glintX - half, y: y, width: half * 2, height: 1.1 * u), cornerRadius: 0.5 * u),
                       with: .color(glint.color(a)))
            }
        }

        // Little waves drifting.
        for row in 0..<4 {
            let y = hy + (6 + CGFloat(row) * 8) * u
            guard y < h - u else { break }
            let gap = (22 + CGFloat(row) * 4) * u
            let offset = CGFloat(M.fract(t * (0.04 + 0.02 * Double(row)))) * gap
            var p = Path()
            var k = 0
            var x = -gap + offset
            while x < w + gap {
                let jitter = CGFloat(M.rand(k, 30 + row)) * 9 * u
                let len = (5 + CGFloat(row)) * u
                p.move(to: CGPoint(x: x + jitter, y: y))
                p.addQuadCurve(to: CGPoint(x: x + jitter + len, y: y), control: CGPoint(x: x + jitter + len / 2, y: y - 1.4 * u))
                x += gap
                k += 1
            }
            c.stroke(p, with: .color(.white.opacity(0.10 + 0.04 * Double(row))), lineWidth: 0.8 * u)
        }

        // Sparkles on the water.
        for i in 0..<12 {
            let b = pow(max(0, sin(t * 1.8 + Double(i) * 1.7)), 8)
            guard b > 0.02 else { continue }
            let p = CGPoint(x: CGFloat(M.rand(i, 20)) * w, y: hy + 3 * u + CGFloat(M.rand(i, 21)) * (h - hy - 6 * u))
            c.fill(Ink.sparkle(p, (1 + 1.5 * CGFloat(b)) * u), with: .color(.white.opacity(b)))
        }
    }

    /// King's Landing: see `Buildings.kingsLanding`.
    static func kingsLanding(_ c: GraphicsContext, base: CGPoint, u: CGFloat, t: Double, lit: Double, land: RGB, extent: CGFloat = 70) {
        Buildings.kingsLanding(c, base: base, u: u, t: t, lit: lit, land: land, extent: extent)
    }

    /// Dragonstone: see `Buildings.dragonstone`.
    static func dragonstone(_ c: GraphicsContext, base: CGPoint, u: CGFloat, t: Double, rock: RGB) {
        Buildings.dragonstone(c, base: base, u: u, t: t, rock: rock)
    }

    static func label(_ c: GraphicsContext, _ text: String, at p: CGPoint, u: CGFloat) {
        var l = c
        l.addFilter(.shadow(color: .black.opacity(0.7), radius: 2 * u))
        l.draw(
            Text(text)
                .font(.system(size: 8.5 * u, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85)),
            at: p, anchor: .center
        )
    }
}
