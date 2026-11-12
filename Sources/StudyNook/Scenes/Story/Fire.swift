import SwiftUI

/// Fire, smoke, embers. All deterministic functions of time, with small particle limits.
enum Fire {
    /// A wall of flames along a baseline. `intensity` 0...1.2, `height` in points.
    static func flames(_ c: GraphicsContext, x0: CGFloat, x1: CGFloat, y: CGFloat, height: CGFloat,
                       intensity: Double, t: Double, seed: Int, u: CGFloat) {
        guard intensity > 0.02, x1 > x0 else { return }
        var g = c
        g.blendMode = .plusLighter
        let n = max(3, min(26, Int((x1 - x0) / (6 * u))))
        let layers: [(RGB, CGFloat, Double)] = [
            (RGB(0.80, 0.14, 0.04), 1.0, 0.85),
            (RGB(1.00, 0.45, 0.08), 0.74, 0.8),
            (RGB(1.00, 0.86, 0.38), 0.45, 0.75),
        ]
        for (li, layer) in layers.enumerated() {
            var path = Path()
            for i in 0..<n {
                let fx = x0 + (x1 - x0) * (CGFloat(i) + CGFloat(M.rand(i, seed)) * 0.7) / CGFloat(n)
                let flick = 0.65 + 0.35 * sin(t * (5 + M.rand(i, seed + 1) * 5) + Double(i) * 1.7 + Double(li))
                let hh = height * layer.1 * CGFloat(intensity) * CGFloat(0.5 + 0.5 * M.rand(i, seed + 2)) * CGFloat(flick)
                let ww = (x1 - x0) / CGFloat(n) * 1.5 * layer.1 + 2 * u
                let sway = CGFloat(sin(t * 3 + Double(i) * 0.9)) * 2.2 * u
                path.move(to: CGPoint(x: fx - ww / 2, y: y))
                path.addQuadCurve(to: CGPoint(x: fx + sway, y: y - hh), control: CGPoint(x: fx - ww * 0.35, y: y - hh * 0.55))
                path.addQuadCurve(to: CGPoint(x: fx + ww / 2, y: y), control: CGPoint(x: fx + ww * 0.35, y: y - hh * 0.5))
                path.closeSubpath()
            }
            g.fill(path, with: .color(layer.0.color(layer.2 * min(1, intensity))))
        }
        // Heat glow above the fire.
        let mid = CGPoint(x: (x0 + x1) / 2, y: y - height * 0.4)
        g.fill(Ink.ellipse(mid, (x1 - x0) * 0.7, height * 0.9), with: .radialGradient(
            Gradient(colors: [RGB(1, 0.5, 0.15).color(0.28 * min(1, intensity)), RGB(1, 0.5, 0.15).color(0)]),
            center: mid, startRadius: 0, endRadius: max((x1 - x0) * 0.7, height * 0.9)))
    }

    /// One flame tongue at a point (torches, small fires).
    static func torch(_ c: GraphicsContext, at p: CGPoint, size: CGFloat, t: Double, seed: Int = 0) {
        flames(c, x0: p.x - size * 0.5, x1: p.x + size * 0.5, y: p.y, height: size * 1.6, intensity: 1, t: t, seed: seed, u: size / 6)
    }

    /// Smoke columns drifting up and sideways.
    static func smoke(_ c: GraphicsContext, x0: CGFloat, x1: CGFloat, y: CGFloat, rise: CGFloat,
                      t: Double, u: CGFloat, opacity: Double = 0.35, seed: Int = 0, wind: CGFloat = 8) {
        for i in 0..<9 {
            let age = M.fract(t * 0.22 + M.rand(i, seed + 5))
            let x = x0 + (x1 - x0) * CGFloat(M.rand(i, seed + 6)) + CGFloat(age) * wind * u
            let yy = y - CGFloat(age) * rise
            let r = (3 + CGFloat(age) * 11) * u
            let a = opacity * (1 - age) * M.smoothstep(0, 0.12, age)
            c.fill(Ink.circle(CGPoint(x: x, y: yy), r), with: .color(RGB(0.22, 0.2, 0.22).color(a)))
        }
    }

    /// Embers / ash flying up.
    static func embers(_ c: GraphicsContext, _ env: SceneEnv, x0: CGFloat, x1: CGFloat, y: CGFloat, count: Int, rise: CGFloat, color: RGB = RGB(1, 0.62, 0.2)) {
        var g = c
        g.blendMode = .plusLighter
        for i in 0..<min(count, 40) {
            let age = M.fract(env.t * (0.25 + 0.2 * M.rand(i, 90)) + M.rand(i, 91))
            let x = x0 + (x1 - x0) * CGFloat(M.rand(i, 92)) + CGFloat(sin(env.t * 1.3 + Double(i))) * 4 * env.u
            let yy = y - CGFloat(age) * rise
            g.fill(Ink.circle(CGPoint(x: x, y: yy), (0.4 + 0.8 * CGFloat(M.rand(i, 93))) * env.u),
                   with: .color(color.color((1 - age) * 0.9)))
        }
    }

    /// Cone of dragon fire from `from` in direction `angle` (radians, 0 = right).
    static func breath(_ c: GraphicsContext, from: CGPoint, angle: Double, length: CGFloat, t: Double, u: CGFloat, intensity: Double = 1) {
        guard intensity > 0.02 else { return }
        var g = c
        g.blendMode = .plusLighter
        g.fill(Ink.circle(from, 10 * u), with: .radialGradient(
            Gradient(colors: [RGB(1, 0.75, 0.35).color(0.6 * intensity), RGB(1, 0.5, 0.2).color(0)]),
            center: from, startRadius: 0, endRadius: 10 * u))
        for i in 0..<44 {
            let life = M.fract(t * 1.9 + M.rand(i, 60))
            let spread = (M.rand(i, 61) - 0.5) * 0.42 * (0.4 + life)
            let a = angle + spread
            let d = CGFloat(life) * length
            let q = CGPoint(x: from.x + CGFloat(cos(a)) * d, y: from.y + CGFloat(sin(a)) * d - CGFloat(life * life) * 5 * u)
            let col = life < 0.25 ? RGB(1, 0.95, 0.75) : (life < 0.6 ? RGB(1, 0.6, 0.15) : RGB(0.85, 0.22, 0.08))
            g.fill(Ink.circle(q, (1.1 + CGFloat(life) * 4.4) * u), with: .color(col.color((1 - life) * 0.75 * intensity)))
        }
    }

    /// Blue fire (undead dragon, the Night King).
    static func blueBreath(_ c: GraphicsContext, from: CGPoint, angle: Double, length: CGFloat, t: Double, u: CGFloat, intensity: Double = 1) {
        var g = c
        g.blendMode = .plusLighter
        for i in 0..<34 {
            let life = M.fract(t * 1.7 + M.rand(i, 70))
            let a = angle + (M.rand(i, 71) - 0.5) * 0.38 * (0.4 + life)
            let d = CGFloat(life) * length
            let q = CGPoint(x: from.x + CGFloat(cos(a)) * d, y: from.y + CGFloat(sin(a)) * d)
            let col = life < 0.35 ? RGB(0.85, 0.95, 1) : RGB(0.25, 0.55, 1)
            g.fill(Ink.circle(q, (1.0 + CGFloat(life) * 4) * u), with: .color(col.color((1 - life) * 0.8 * intensity)))
        }
    }
}
