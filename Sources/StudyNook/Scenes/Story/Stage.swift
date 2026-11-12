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
        }
    }

    /// Soft rolling hills, a cheap way to get depth.
    static func hills(_ c: GraphicsContext, _ env: SceneEnv, color: RGB, y: CGFloat, amp: CGFloat, freq: Double, phase: Double = 0, scroll: CGFloat = 0) {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: env.h))
        var x: CGFloat = 0
        while x <= env.w + 6 {
            let a = Double(x + scroll) / Double(env.w) * freq * 2 * .pi + phase
            let yy = y + CGFloat(sin(a) * 0.6 + sin(a * 2.3 + 1.3) * 0.4) * amp
            p.addLine(to: CGPoint(x: x, y: yy))
            x += 6
        }
        p.addLine(to: CGPoint(x: env.w, y: env.h))
        p.closeSubpath()
        c.fill(p, with: .color(color.color()))
    }

    /// Jagged mountains.
    static func mountains(_ c: GraphicsContext, _ env: SceneEnv, color: RGB, base: CGFloat, height: CGFloat, count: Int, seed: Int, snow: Bool = false) {
        var p = Path()
        p.move(to: CGPoint(x: -10, y: base))
        var caps = Path()
        for i in 0..<count {
            let cx = (CGFloat(i) + 0.5) / CGFloat(count) * env.w + CGFloat(M.rand(i, seed) - 0.5) * env.w / CGFloat(count) * 0.8
            let hh = height * CGFloat(0.55 + 0.45 * M.rand(i, seed + 1))
            let hw = env.w / CGFloat(count) * 0.75
            p.addLine(to: CGPoint(x: cx - hw, y: base))
            p.addLine(to: CGPoint(x: cx - hw * 0.15, y: base - hh * 0.85))
            p.addLine(to: CGPoint(x: cx, y: base - hh))
            p.addLine(to: CGPoint(x: cx + hw * 0.2, y: base - hh * 0.8))
            p.addLine(to: CGPoint(x: cx + hw, y: base))
            if snow {
                caps.move(to: CGPoint(x: cx - hw * 0.28, y: base - hh * 0.72))
                caps.addLine(to: CGPoint(x: cx, y: base - hh))
                caps.addLine(to: CGPoint(x: cx + hw * 0.32, y: base - hh * 0.7))
                caps.addLine(to: CGPoint(x: cx + hw * 0.1, y: base - hh * 0.66))
                caps.addLine(to: CGPoint(x: cx - hw * 0.05, y: base - hh * 0.74))
                caps.closeSubpath()
            }
        }
        p.addLine(to: CGPoint(x: env.w + 10, y: base))
        p.addLine(to: CGPoint(x: env.w + 10, y: env.h))
        p.addLine(to: CGPoint(x: -10, y: env.h))
        p.closeSubpath()
        c.fill(p, with: .color(color.color()))
        if snow { c.fill(caps, with: .color(RGB(0.93, 0.96, 1).color(0.9))) }
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
