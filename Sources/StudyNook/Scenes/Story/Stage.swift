import SwiftUI

/// Everything a scene needs to draw one frame.
struct SceneEnv {
    let size: CGSize
    /// Seconds, for animation.
    let t: Double
    /// Progress of the current phase, 0...1.
    let p: Double
    var horizon: CGFloat = 0.72
    /// Length of the phase in seconds (used for fades that should last about half a second).
    var total: Double = 1500

    var w: CGFloat { size.width }
    var h: CGFloat { size.height }
    /// Scene unit: 1 at the normal card height of 118 pt.
    var u: CGFloat { size.height / 118 }
    var hy: CGFloat { size.height * horizon }

    func at(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint { CGPoint(x: w * fx, y: h * fy) }
}

enum GroundKind {
    case sea(top: RGB, bottom: RGB)
    case land(far: RGB, near: RGB)
}

/// Sky + sun + ground, the slow-changing part of a scene (drawn a few times per second).
struct Backdrop {
    var skyTop: RGB
    var skyBottom: RGB
    var sun: (x: CGFloat, y: CGFloat, color: RGB, radius: CGFloat)?
    var moon: CGPoint?
    var stars: Double = 0
    var ground: GroundKind
    var horizon: CGFloat = 0.72
    var clouds: RGB?
    var cloudOpacity: Double = 1

    // Time-of-day looks.
    static let dawnSky = (RGB(0.20, 0.27, 0.52), RGB(0.97, 0.72, 0.62))
    static let daySky = (RGB(0.16, 0.40, 0.76), RGB(0.62, 0.82, 0.96))
    static let duskSky = (RGB(0.30, 0.16, 0.44), RGB(1.0, 0.58, 0.30))
    static let nightSky = (RGB(0.03, 0.05, 0.14), RGB(0.18, 0.16, 0.34))
    static let overcastSky = (RGB(0.36, 0.40, 0.46), RGB(0.70, 0.72, 0.76))
    static let fireSky = (RGB(0.16, 0.05, 0.05), RGB(0.95, 0.38, 0.10))
}

enum Stage {
    static func paintBackdrop(_ c: GraphicsContext, _ env: SceneEnv, _ b: Backdrop) {
        let hy = env.size.height * b.horizon
        Landscape.sky(c, env.size, top: b.skyTop, bottom: b.skyBottom, horizon: hy)
        if b.stars > 0.01 {
            Landscape.stars(c, env.size, u: env.u, t: 0, opacity: b.stars, maxY: hy * 0.85, count: 36)
        }
        if let s = b.sun {
            Landscape.sun(c, at: CGPoint(x: env.w * s.x, y: env.h * s.y), radius: s.radius * env.u, color: s.color, glow: 1)
        }
        if let m = b.moon {
            let p = CGPoint(x: env.w * m.x, y: env.h * m.y), r = 6.5 * env.u
            c.fill(Ink.circle(p, r * 4), with: .radialGradient(
                Gradient(colors: [RGB(0.8, 0.85, 1).color(0.25), RGB(0.8, 0.85, 1).color(0)]),
                center: p, startRadius: r * 0.5, endRadius: r * 4))
            c.fill(Ink.circle(p, r), with: .color(RGB(0.98, 0.95, 0.85).color()))
        }
        if let s = b.sun, s.y < b.horizon + 0.02 {
            godRays(c, env, from: CGPoint(x: env.w * s.x, y: env.h * s.y), color: s.color, alpha: 0.07)
        }
        switch b.ground {
        case let .sea(top, bottom):
            c.fill(Path(CGRect(x: 0, y: hy, width: env.w, height: env.h - hy)), with: .linearGradient(
                Gradient(colors: [top.color(), bottom.color()]),
                startPoint: CGPoint(x: 0, y: hy), endPoint: CGPoint(x: 0, y: env.h)))
            c.fill(Path(CGRect(x: 0, y: hy - 0.4 * env.u, width: env.w, height: env.u)), with: .color(.white.opacity(0.14)))
        case let .land(far, near):
            c.fill(Path(CGRect(x: 0, y: hy, width: env.w, height: env.h - hy)), with: .linearGradient(
                Gradient(colors: [far.color(), near.color()]),
                startPoint: CGPoint(x: 0, y: hy), endPoint: CGPoint(x: 0, y: env.h)))
            groundTexture(c, env, y0: hy + 4 * env.u, y1: env.h, color: near, density: 90, seed: 3)
        }
        fog(c, env, y: hy, height: 12 * env.u, color: b.skyBottom, alpha: 0.4)
    }

    /// Rolling hills with a lit ridge, a soft gradient, optional haze toward the sky and tufts of grass.
    static func hills(_ c: GraphicsContext, _ env: SceneEnv, color: RGB, y: CGFloat, amp: CGFloat, freq: Double,
                      phase: Double = 0, scroll: CGFloat = 0, haze: RGB? = nil, hazeAmount: Double = 0.0, tufts: Bool = false) {
        var pts: [CGPoint] = []
        var x: CGFloat = -4
        while x <= env.w + 8 {
            let a = Double(x + scroll) / Double(env.w) * freq * 2 * .pi + phase
            let yy = y + CGFloat(sin(a) * 0.6 + sin(a * 2.3 + 1.3) * 0.3 + sin(a * 5.1 + 0.4) * 0.1) * amp
            pts.append(CGPoint(x: x, y: yy))
            x += 5
        }
        var fill = Path()
        fill.move(to: CGPoint(x: -4, y: env.h + 2))
        pts.forEach { fill.addLine(to: $0) }
        fill.addLine(to: CGPoint(x: env.w + 8, y: env.h + 2))
        fill.closeSubpath()
        let top = haze.map { RGB.lerp(color, $0, hazeAmount) } ?? color
        let dark = RGB(color.r * 0.55, color.g * 0.55, color.b * 0.6)
        c.fill(fill, with: .linearGradient(Gradient(colors: [top.color(), color.color(), dark.color()]),
                                           startPoint: CGPoint(x: 0, y: y - amp), endPoint: CGPoint(x: 0, y: y + amp * 5 + 30 * env.u)))
        // Surface texture, clipped to the hill.
        var clipped = c
        clipped.clip(to: fill)
        groundTexture(clipped, env, y0: y - amp * 0.5, y1: env.h, color: color, density: 34, seed: Int(y) % 97, grass: tufts)
        // Lit ridge.
        var ridge = Path()
        ridge.move(to: pts[0])
        pts.dropFirst().forEach { ridge.addLine(to: $0) }
        c.stroke(ridge, with: .color(RGB.lerp(color, RGB(1, 0.95, 0.85), 0.35).color(0.45)), lineWidth: 0.9 * env.u)
        // Soft shadow pockets under the ridge.
        for i in stride(from: 2, to: pts.count - 2, by: 7) {
            let p = pts[i]
            c.fill(Ink.ellipse(CGPoint(x: p.x, y: p.y + 4 * env.u), 14 * env.u, 2.2 * env.u), with: .color(dark.color(0.25)))
        }
        if tufts {
            var g = Path()
            for (i, p) in pts.enumerated() where i % 2 == 0 {
                let h = (1.5 + 2.5 * CGFloat(M.rand(i, Int(y) % 50))) * env.u
                let lean = CGFloat(M.rand(i, 7) - 0.5) * 2 * env.u
                g.move(to: CGPoint(x: p.x, y: p.y + 0.5 * env.u))
                g.addLine(to: CGPoint(x: p.x + lean, y: p.y - h))
            }
            c.stroke(g, with: .color(RGB.lerp(color, RGB(0.9, 1, 0.7), 0.15).color(0.7)), lineWidth: 0.6 * env.u)
        }
    }

    /// Jagged mountains: a lit and a shaded face, ridges, jagged snow caps and fog at the foot.
    static func mountains(_ c: GraphicsContext, _ env: SceneEnv, color: RGB, base: CGFloat, height: CGFloat, count: Int, seed: Int, snow: Bool = false) {
        let lit = RGB.lerp(color, RGB(1, 0.92, 0.82), 0.22)
        let shade = RGB(color.r * 0.62, color.g * 0.62, color.b * 0.7)
        for i in 0..<count {
            let slot = env.w / CGFloat(count)
            let cx = (CGFloat(i) + 0.5) * slot + CGFloat(M.rand(i, seed) - 0.5) * slot * 0.7
            let hh = height * CGFloat(0.55 + 0.45 * M.rand(i, seed + 1))
            let hw = slot * 0.85
            let tip = CGPoint(x: cx, y: base - hh)
            // Jagged edges: noisy points down each flank.
            func flank(_ dir: CGFloat) -> [CGPoint] {
                (0...6).map { k in
                    let f = CGFloat(k) / 6
                    let jag = CGFloat(M.rand(i * 7 + k, seed + (dir > 0 ? 3 : 4)) - 0.5) * hw * 0.16 * (k == 0 || k == 6 ? 0 : 1)
                    return CGPoint(x: cx + dir * hw * f + jag, y: base - hh * pow(1 - f, 0.9) + CGFloat(M.rand(i * 5 + k, seed + 9) - 0.5) * hh * 0.07 * (k == 0 || k == 6 ? 0 : 1))
                }
            }
            let left = flank(-1), right = flank(1)
            var lp = Path(), rp = Path()
            lp.move(to: CGPoint(x: cx - hw, y: base)); left.reversed().forEach { lp.addLine(to: $0) }; lp.addLine(to: CGPoint(x: cx + hw * 0.05, y: base)); lp.closeSubpath()
            rp.move(to: tip); right.forEach { rp.addLine(to: $0) }; rp.addLine(to: CGPoint(x: cx + hw * 0.05, y: base)); rp.addLine(to: CGPoint(x: cx + hw * 0.05, y: tip.y + hh * 0.35)); rp.closeSubpath()
            c.fill(lp, with: .linearGradient(Gradient(colors: [lit.color(), color.color()]), startPoint: tip, endPoint: CGPoint(x: cx - hw, y: base)))
            c.fill(rp, with: .linearGradient(Gradient(colors: [shade.color(), RGB(shade.r * 0.7, shade.g * 0.7, shade.b * 0.75).color()]), startPoint: tip, endPoint: CGPoint(x: cx + hw, y: base)))
            // Ridges down the lit face.
            var r = Path()
            for k in 0..<3 {
                let f = CGFloat(k + 1) / 4
                r.move(to: CGPoint(x: tip.x - hw * 0.04 * f, y: tip.y + hh * 0.18))
                r.addLine(to: CGPoint(x: cx - hw * (0.28 + 0.2 * f) + CGFloat(M.rand(k, seed + i)) * 6 * env.u, y: base - hh * 0.05))
            }
            c.stroke(r, with: .color(shade.color(0.28)), lineWidth: 0.7 * env.u)
            if snow {
                var cap = Path()
                let snowLine = hh * 0.42
                cap.move(to: tip)
                for k in 0...5 {
                    let f = CGFloat(k) / 5
                    cap.addLine(to: CGPoint(x: cx - hw * 0.5 * f * (0.8 + 0.2 * CGFloat(M.rand(k, seed + 20 + i))), y: tip.y + snowLine * f + CGFloat(k % 2 == 0 ? 0 : 1) * snowLine * 0.18))
                }
                cap.addLine(to: CGPoint(x: cx + hw * 0.02, y: tip.y + snowLine * 1.1))
                cap.closeSubpath()
                c.fill(cap, with: .color(RGB(0.95, 0.97, 1).color(0.92)))
                var capR = Path()
                capR.move(to: tip)
                for k in 0...4 {
                    let f = CGFloat(k) / 4
                    capR.addLine(to: CGPoint(x: cx + hw * 0.04 + hw * 0.36 * f, y: tip.y + snowLine * 0.9 * f + CGFloat(k % 2 == 1 ? 1 : 0) * snowLine * 0.12))
                }
                capR.addLine(to: CGPoint(x: cx + hw * 0.04, y: tip.y + snowLine))
                capR.closeSubpath()
                c.fill(capR, with: .color(RGB(0.62, 0.7, 0.86).color(0.9)))
            }
        }
        // Fog at the foot of the mountains.
        c.fill(Path(CGRect(x: 0, y: base - height * 0.3, width: env.w, height: height * 0.34)), with: .linearGradient(
            Gradient(colors: [color.color(0), RGB.lerp(color, RGB(0.85, 0.88, 0.95), 0.5).color(0.45)]),
            startPoint: CGPoint(x: 0, y: base - height * 0.3), endPoint: CGPoint(x: 0, y: base + 2 * env.u)))
        c.fill(Path(CGRect(x: 0, y: base, width: env.w, height: env.h - base + 2)), with: .color(color.color()))
    }

    /// A band of mist.
    static func fog(_ c: GraphicsContext, _ env: SceneEnv, y: CGFloat, height: CGFloat, color: RGB, alpha: Double) {
        c.fill(Path(CGRect(x: 0, y: y - height / 2, width: env.w, height: height)), with: .linearGradient(
            Gradient(colors: [color.color(0), color.color(alpha), color.color(0)]),
            startPoint: CGPoint(x: 0, y: y - height / 2), endPoint: CGPoint(x: 0, y: y + height / 2)))
    }

    /// Rays of light fanning out from the sun.
    static func godRays(_ c: GraphicsContext, _ env: SceneEnv, from: CGPoint, color: RGB, alpha: Double, count: Int = 7, spread: Double = 1.2) {
        var g = c
        g.blendMode = .plusLighter
        for i in 0..<count {
            let a = Double.pi / 2 + (Double(i) / Double(count - 1) - 0.5) * spread + (M.rand(i, 150) - 0.5) * 0.12
            let len = env.h * 1.6
            let w = 0.05 + 0.05 * M.rand(i, 151)
            var p = Path()
            p.move(to: from)
            p.addLine(to: CGPoint(x: from.x + CGFloat(cos(a - w)) * len, y: from.y + CGFloat(sin(a - w)) * len))
            p.addLine(to: CGPoint(x: from.x + CGFloat(cos(a + w)) * len, y: from.y + CGFloat(sin(a + w)) * len))
            p.closeSubpath()
            g.fill(p, with: .linearGradient(Gradient(colors: [color.color(alpha * (0.4 + 0.6 * M.rand(i, 152))), color.color(0)]),
                                            startPoint: from, endPoint: CGPoint(x: from.x, y: from.y + env.h)))
        }
    }

    /// Grass tufts, pebbles and cracks scattered on the ground, so flat colour reads as a surface.
    static func groundTexture(_ c: GraphicsContext, _ env: SceneEnv, y0: CGFloat, y1: CGFloat, color: RGB, density: Int, seed: Int = 0, grass: Bool = false) {
        var dark = Path(), light = Path(), blades = Path()
        for i in 0..<density {
            let z = CGFloat(M.rand(i, seed + 160))
            let x = env.w * CGFloat(M.rand(i, seed + 161))
            let y = y0 + (y1 - y0) * z
            let s = (0.5 + 1.1 * z) * env.u
            if grass {
                let hgt = (2 + 3 * CGFloat(M.rand(i, seed + 162))) * s
                blades.move(to: CGPoint(x: x, y: y)); blades.addLine(to: CGPoint(x: x + CGFloat(M.rand(i, seed + 163) - 0.5) * 2 * s, y: y - hgt))
                blades.move(to: CGPoint(x: x + s, y: y)); blades.addLine(to: CGPoint(x: x + s * 1.6, y: y - hgt * 0.7))
            } else {
                dark.addEllipse(in: CGRect(x: x, y: y, width: 2.4 * s, height: 0.9 * s))
                light.addEllipse(in: CGRect(x: x + s * 0.4, y: y - s * 0.5, width: 2.0 * s, height: 0.7 * s))
            }
        }
        c.fill(dark, with: .color(RGB(color.r * 0.55, color.g * 0.55, color.b * 0.6).color(0.45)))
        c.fill(light, with: .color(RGB.lerp(color, RGB(1, 0.95, 0.85), 0.4).color(0.35)))
        c.stroke(blades, with: .color(RGB.lerp(color, RGB(0.7, 0.9, 0.4), 0.3).color(0.7)), lineWidth: 0.6 * env.u)
    }

    /// Faceted boulders.
    static func rocks(_ c: GraphicsContext, _ env: SceneEnv, y0: CGFloat, y1: CGFloat, color: RGB, count: Int, seed: Int = 0) {
        for i in 0..<count {
            let z = CGFloat(M.rand(i, seed + 170))
            let x = env.w * CGFloat(M.rand(i, seed + 171))
            let y = y0 + (y1 - y0) * z
            let s = (2.5 + 4 * CGFloat(M.rand(i, seed + 172))) * (0.6 + 0.8 * z) * env.u
            var left = Path(), right = Path()
            left.move(to: CGPoint(x: x - s, y: y)); left.addLine(to: CGPoint(x: x - s * 0.7, y: y - s * 0.8)); left.addLine(to: CGPoint(x: x, y: y - s)); left.addLine(to: CGPoint(x: x, y: y)); left.closeSubpath()
            right.move(to: CGPoint(x: x, y: y - s)); right.addLine(to: CGPoint(x: x + s * 0.8, y: y - s * 0.6)); right.addLine(to: CGPoint(x: x + s, y: y)); right.addLine(to: CGPoint(x: x, y: y)); right.closeSubpath()
            c.fill(left, with: .color(RGB.lerp(color, RGB(1, 0.95, 0.85), 0.2).color()))
            c.fill(right, with: .color(RGB(color.r * 0.6, color.g * 0.6, color.b * 0.65).color()))
        }
    }

    static func caption(_ c: GraphicsContext, _ env: SceneEnv, _ text: String, at fx: CGFloat, y: CGFloat? = nil) {
        Landscape.label(c, text, at: CGPoint(x: env.w * fx, y: y ?? env.h - 8 * env.u), u: env.u)
    }

    /// Full-scene tint, for flashes and fire light.
    static func wash(_ c: GraphicsContext, _ env: SceneEnv, _ color: RGB, _ alpha: Double) {
        guard alpha > 0.005 else { return }
        c.fill(Path(CGRect(origin: .zero, size: env.size)), with: .color(color.color(alpha)))
    }

    /// Darkens the edges so the focus stays in the middle.
    static func vignette(_ c: GraphicsContext, _ env: SceneEnv, strength: Double = 0.35) {
        c.fill(Path(CGRect(origin: .zero, size: env.size)), with: .radialGradient(
            Gradient(colors: [.clear, .black.opacity(strength)]),
            center: CGPoint(x: env.w / 2, y: env.h * 0.55), startRadius: env.w * 0.25, endRadius: env.w * 0.62))
    }
}
