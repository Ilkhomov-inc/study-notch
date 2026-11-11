import SwiftUI

/// Focus scene: the dragon flies from Dragonstone (east, right) to King's Landing (west, left).
/// The sky goes from dawn to a golden sunset as the flight progresses.
/// With `arrival` set (0...1) it plays the landing: a loop over the Red Keep, fire into the sky, "Долетел!".
enum FlightPainter {
    struct Layout {
        let w: CGFloat, h: CGFloat, u: CGFloat, hy: CGFloat
        let kingsLanding: CGPoint
        let dragonstone: CGPoint
        let route: QuadCurve

        init(_ size: CGSize) {
            w = size.width
            h = size.height
            u = h / 118
            hy = h * 0.72
            kingsLanding = CGPoint(x: w * 0.105, y: hy - 2 * u)
            dragonstone = CGPoint(x: w * 0.87, y: hy)
            let start = CGPoint(x: dragonstone.x - 3 * u, y: hy - 44 * u)
            let end = CGPoint(x: kingsLanding.x + 4 * u, y: hy - 42 * u)
            route = QuadCurve(p0: start, c: CGPoint(x: w * 0.5, y: hy - 100 * u), p1: end)
        }
    }

    static let skyTop: [(Double, RGB)] = [(0, RGB(0.20, 0.27, 0.52)), (0.5, RGB(0.16, 0.40, 0.76)), (1, RGB(0.30, 0.16, 0.44))]
    static let skyBottom: [(Double, RGB)] = [(0, RGB(0.97, 0.72, 0.62)), (0.5, RGB(0.62, 0.82, 0.96)), (1, RGB(1.0, 0.58, 0.30))]

    static func draw(_ c: GraphicsContext, size: CGSize, progress: Double, t: Double, paused: Bool, arrival: Double?) {
        let L = Layout(size)
        let u = L.u
        let p = arrival == nil ? progress : 1
        let warmth = abs(p - 0.5) * 2

        Landscape.sky(c, size, top: RGB.keyframes(skyTop, p), bottom: RGB.keyframes(skyBottom, p), horizon: L.hy)

        let sunColor = RGB.lerp(RGB(1, 0.95, 0.8), RGB(1, 0.62, 0.32), warmth)
        let sunPos = CGPoint(
            x: M.lerp(L.w * 0.80, L.w * 0.20, CGFloat(p)),
            y: L.hy - 8 * u - CGFloat(sin(.pi * p)) * 58 * u
        )
        Landscape.sun(c, at: sunPos, radius: 8 * u, color: sunColor, glow: 1)
        Landscape.clouds(c, size, u: u, t: t, tint: RGB.lerp(RGB(1, 1, 1), RGB(1, 0.82, 0.72), warmth), opacity: 1)

        Landscape.sea(c, size, horizon: L.hy, u: u, t: t,
                      top: RGB.lerp(RGB(0.30, 0.48, 0.66), RGB(0.52, 0.34, 0.40), p),
                      bottom: RGB(0.05, 0.12, 0.22), glint: sunColor, glintX: sunPos.x)

        // Coast with King's Landing.
        let landColor = RGB.lerp(RGB(0.16, 0.17, 0.16), RGB(0.22, 0.12, 0.12), p)
        var land = Path()
        land.move(to: CGPoint(x: 0, y: L.hy - 8 * u))
        land.addQuadCurve(to: CGPoint(x: L.w * 0.27, y: L.h), control: CGPoint(x: L.w * 0.24, y: L.hy - 8 * u))
        land.addLine(to: CGPoint(x: 0, y: L.h))
        land.closeSubpath()
        c.fill(land, with: .color(landColor.color()))

        let lit = arrival != nil ? 1 : 0.3 + 0.7 * M.smoothstep(0.6, 1, p)
        Landscape.kingsLanding(c, base: L.kingsLanding, u: u, t: t, lit: lit, land: landColor)
        Landscape.dragonstone(c, base: L.dragonstone, u: u, t: t, rock: RGB.lerp(RGB(0.34, 0.34, 0.42), RGB(0.40, 0.28, 0.32), p))

        // Route: dots ahead, a glow behind.
        let tp = CGFloat(p)
        c.stroke(L.route.path(from: tp, to: 1), with: .color(.white.opacity(0.55)),
                 style: StrokeStyle(lineWidth: 1.2 * u, lineCap: .round, dash: [0.1, 4.5 * u]))
        var glow = c
        glow.addFilter(.blur(radius: 1.5 * u))
        glow.stroke(L.route.path(from: 0, to: tp), with: .color(Theme.focus.opacity(0.45)), lineWidth: 1.4 * u)

        if arrival == nil {
            // Target pulses over King's Landing.
            let pulse = M.fract(t * 0.6)
            c.stroke(Ink.circle(L.route.p1, (2 + 6 * CGFloat(pulse)) * u),
                     with: .color(Theme.focus.opacity(0.7 * (1 - pulse))), lineWidth: 1 * u)
        }

        Landscape.label(c, "Королевская Гавань", at: CGPoint(x: L.kingsLanding.x + 6 * u, y: L.h - 8 * u), u: u)
        Landscape.label(c, "Драконий Камень", at: CGPoint(x: L.dragonstone.x, y: L.h - 8 * u), u: u)

        if let arrival {
            drawArrival(c, L, a: arrival, t: t)
        } else {
            drawCruise(c, L, p: progress, t: t, paused: paused)
        }
    }

    private static func drawCruise(_ c: GraphicsContext, _ L: Layout, p: Double, t: Double, paused: Bool) {
        let u = L.u
        let tp = CGFloat(p)

        // Embers trail behind the tail.
        var e = c
        e.blendMode = .plusLighter
        let fade = min(1, p * 25)
        for i in 0..<24 {
            let age = M.fract(t * 0.9 + M.rand(i, 40))
            let back = CGFloat(0.05 + age * 0.06)
            var q = L.route.point(max(0, tp - back))
            q.x += CGFloat(M.rand(i, 41) - 0.5) * 6 * u * CGFloat(age)
            q.y += CGFloat(M.rand(i, 42) - 0.2) * 8 * u * CGFloat(age)
            let col = RGB.lerp(RGB(1, 0.86, 0.45), RGB(0.95, 0.25, 0.08), age)
            e.fill(Ink.circle(q, (1.5 - 1.1 * CGFloat(age)) * u), with: .color(col.color((1 - age) * 0.85 * fade)))
        }

        var pos = L.route.point(tp)
        pos.y += CGFloat(sin(t * 2 * .pi * 0.9)) * 1.6 * u
        let d = L.route.derivative(tp)
        let angle = max(-0.45, min(0.45, Double(atan2(-d.y, -d.x)) * 0.7))
        let pose = DragonPose(position: pos, angle: angle, scale: 0.36 * u, flip: -1)
        DragonPainter.drawFlying(c, pose: pose, flapPhase: t * 2 * .pi * (paused ? 0.8 : 1.8), t: t, palette: .drogon)
    }

    private static func drawArrival(_ c: GraphicsContext, _ L: Layout, a: Double, t: Double) {
        let u = L.u
        let end = L.route.p1
        let loopEnd = 0.5
        let r: CGFloat = 16 * u

        // A loop over the Red Keep, then hovering.
        var pos: CGPoint
        var vel: CGPoint
        if a < loopEnd {
            let th = -Double.pi / 2 - 2 * Double.pi * M.easeInOut(a / loopEnd)
            let center = CGPoint(x: end.x, y: end.y + r * 0.5)
            pos = CGPoint(x: center.x + r * CGFloat(cos(th)), y: center.y + r * 0.5 * CGFloat(sin(th)))
            vel = CGPoint(x: CGFloat(sin(th)), y: -0.5 * CGFloat(cos(th)))
        } else {
            let k = M.smoothstep(loopEnd, loopEnd + 0.12, a)
            pos = CGPoint(x: end.x, y: end.y - 3 * u * CGFloat(k) + CGFloat(sin(t * 2 * .pi * 0.9)) * 1.2 * u)
            vel = CGPoint(x: -1, y: 0)
        }
        let flip = max(-1, min(1, vel.x / 0.35))
        let sign: CGFloat = flip < 0 ? -1 : 1
        let angle = max(-0.5, min(0.5, Double(atan2(vel.y * sign, abs(vel.x)))))
        let pose = DragonPose(position: pos, angle: angle, scale: 0.36 * u, flip: flip)
        DragonPainter.drawFlying(c, pose: pose, flapPhase: t * 2 * .pi * 1.6, t: t, palette: .drogon)

        // Fire into the sky.
        let env = M.smoothstep(0.55, 0.62, a) * (1 - M.smoothstep(0.88, 0.97, a))
        if env > 0.01 {
            let mouth = DragonPainter.mouth(pose)
            var f = c
            f.blendMode = .plusLighter
            f.fill(Ink.circle(mouth, 12 * u), with: .radialGradient(
                Gradient(colors: [RGB(1, 0.7, 0.3).color(0.6 * env), RGB(1, 0.5, 0.2).color(0)]),
                center: mouth, startRadius: 0, endRadius: 12 * u
            ))
            for i in 0..<46 {
                let life = M.fract(t * 1.7 + M.rand(i, 60))
                let dir = Double.pi + 0.55 + (M.rand(i, 61) - 0.5) * 0.5
                let dist = CGFloat(life) * 38 * u
                let q = CGPoint(x: mouth.x + CGFloat(cos(dir)) * dist,
                                y: mouth.y + CGFloat(sin(dir)) * dist - CGFloat(life * life) * 6 * u)
                let col = life < 0.25 ? RGB(1, 0.95, 0.75) : (life < 0.6 ? RGB(1, 0.6, 0.15) : RGB(0.85, 0.22, 0.08))
                f.fill(Ink.circle(q, (1.2 + CGFloat(life) * 4.2) * u), with: .color(col.color((1 - life) * 0.75 * env)))
            }
            let flicker = 0.75 + 0.25 * sin(t * 23)
            c.fill(Path(CGRect(x: 0, y: 0, width: L.w, height: L.h)), with: .color(RGB(1, 0.55, 0.2).color(0.16 * env * flicker)))
        }

        // "Долетел!" pops in.
        if a > 0.6 {
            let k = min(1, (a - 0.6) / 0.14)
            let s = CGFloat(M.easeOutBack(k))
            var tc = c
            tc.opacity = min(1, k * 2) * (1 - M.smoothstep(0.94, 1, a))
            tc.translateBy(x: L.w * 0.5, y: L.h * 0.3)
            tc.scaleBy(x: s, y: s)
            tc.addFilter(.shadow(color: Theme.focus.opacity(0.9), radius: 6 * u))
            tc.draw(Text("Долетел!").font(.system(size: 18 * u, weight: .heavy, design: .rounded)).foregroundStyle(Color.white),
                    at: .zero, anchor: .center)
            // Sparks around the text.
            for i in 0..<8 {
                let ang = Double(i) / 8 * 2 * .pi + t * 0.8
                let rr = (44 + 6 * CGFloat(sin(t * 3 + Double(i)))) * u
                let q = CGPoint(x: CGFloat(cos(ang)) * rr, y: CGFloat(sin(ang)) * rr * 0.35)
                tc.fill(Ink.sparkle(q, 2.4 * u), with: .color(RGB(1, 0.85, 0.5).color(0.9)))
            }
        }
    }
}
