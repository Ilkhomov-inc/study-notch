import SwiftUI
import StudyNookCore

/// Chapters 1–4 (Essos): the wedding and the births, Qarth, Astapor, Vaes Dothrak.
enum JourneyEarly {
    // MARK: - Chapter 1: five scenes

    static let birthBeats: [Double] = [0.20, 0.45, 0.60, 0.85, 1.0]

    static func beat(_ p: Double) -> (index: Int, local: Double) {
        var start = 0.0
        for (i, end) in birthBeats.enumerated() where p <= end {
            return (i, (p - start) / (end - start))
        }
        start = birthBeats[birthBeats.count - 2]
        return (birthBeats.count - 1, 1)
    }

    static func birthBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let (b, l) = beat(env.p)
        let u = env.u, hy = env.hy
        switch b {
        case 0: // Pentos
            let top = RGB.lerp(Backdrop.dawnSky.0, Backdrop.daySky.0, l), bot = RGB.lerp(Backdrop.dawnSky.1, Backdrop.daySky.1, l)
            Stage.paintBackdrop(c, env, Backdrop(skyTop: top, skyBottom: bot,
                sun: (0.8, 0.5 - 0.25 * CGFloat(l), RGB(1, 0.9, 0.7), 8), ground: .land(far: RGB(0.80, 0.72, 0.58), near: RGB(0.56, 0.46, 0.36))))
            Buildings.pentos(c, env)
        case 1: // Red Waste
            let top = RGB.lerp(Backdrop.daySky.0, RGB(0.5, 0.3, 0.3), l * 0.5), bot = RGB.lerp(RGB(0.95, 0.8, 0.6), Backdrop.duskSky.1, l)
            Stage.paintBackdrop(c, env, Backdrop(skyTop: top, skyBottom: bot,
                sun: (0.25 + 0.5 * CGFloat(l), 0.4 + 0.2 * CGFloat(l), RGB(1, 0.85, 0.55), 10), ground: .land(far: RGB(0.86, 0.6, 0.38), near: RGB(0.62, 0.36, 0.22))))
            Stage.hills(c, env, color: RGB(0.78, 0.5, 0.32), y: hy - 2 * u, amp: 6 * u, freq: 2.2, phase: 0.5, haze: RGB(0.97, 0.8, 0.6), hazeAmount: 0.55)
            Stage.hills(c, env, color: RGB(0.68, 0.42, 0.27), y: hy + 12 * u, amp: 5 * u, freq: 3.1, phase: 2)
        case 2: // Tent
            c.fill(Path(CGRect(origin: .zero, size: env.size)), with: .linearGradient(
                Gradient(colors: [RGB(0.12, 0.05, 0.04).color(), RGB(0.42, 0.19, 0.09).color()]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: env.h)))
            var folds = Path()
            for i in 0..<9 {
                let x = env.w * CGFloat(i) / 8
                folds.move(to: CGPoint(x: env.w / 2, y: -4 * u))
                folds.addQuadCurve(to: CGPoint(x: x, y: env.h), control: CGPoint(x: (env.w / 2 + x) / 2, y: env.h * 0.3))
            }
            c.stroke(folds, with: .color(.black.opacity(0.25)), lineWidth: 1.2 * u)
            c.fill(Path(CGRect(x: 0, y: hy + 6 * u, width: env.w, height: env.h)), with: .color(RGB(0.25, 0.11, 0.07).color()))
        case 3: // Night, pyre
            Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB(0.02, 0.03, 0.09), skyBottom: RGB(0.14, 0.08, 0.14), stars: 1,
                ground: .land(far: RGB(0.10, 0.07, 0.07), near: RGB(0.04, 0.03, 0.04))))
        default: // Dawn after the fire
            let top = RGB.lerp(RGB(0.1, 0.1, 0.25), RGB(0.30, 0.25, 0.45), l), bot = RGB.lerp(RGB(0.6, 0.3, 0.25), RGB(1.0, 0.72, 0.45), l)
            Stage.paintBackdrop(c, env, Backdrop(skyTop: top, skyBottom: bot, sun: (0.5, 0.74 - 0.12 * CGFloat(l), RGB(1, 0.8, 0.5), 11),
                ground: .land(far: RGB(0.30, 0.25, 0.24), near: RGB(0.14, 0.11, 0.12))))
            Stage.hills(c, env, color: RGB(0.22, 0.18, 0.19), y: hy + 4 * u, amp: 3 * u, freq: 2, phase: 1)
        }
    }

    static func birthForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        let (b, l) = beat(env.p)
        let u = env.u, t = env.t, hy = env.hy
        let gy = hy + 20 * u
        switch b {
        case 0:
            Crowd.draw(c, env, kind: .soldiers, count: 22, xRange: 0...env.w, yFar: hy + 8 * u, yNear: hy + 14 * u, sFar: 0.65, sNear: 0.8,
                       speed: 0, far: RGB(0.35, 0.26, 0.2), near: RGB(0.25, 0.18, 0.14), seed: 3, standing: true)
            // Torches and ribbons.
            for fx in [CGFloat(0.12), 0.88] {
                c.stroke(Path { $0.move(to: CGPoint(x: env.w * fx, y: gy + 6 * u)); $0.addLine(to: CGPoint(x: env.w * fx, y: gy - 24 * u)) },
                         with: .color(RGB(0.3, 0.2, 0.12).color()), lineWidth: 1.6 * u)
                Fire.torch(c, at: CGPoint(x: env.w * fx, y: gy - 24 * u), size: 4 * u, t: t, seed: Int(fx * 10))
            }
            Figure.draw(c, feet: CGPoint(x: env.w * 0.44, y: gy), h: 34 * u, style: .dany(.wedding), facing: 1, t: t, arms: 0.35 + 0.1 * sin(t))
            Figure.draw(c, feet: CGPoint(x: env.w * 0.57, y: gy), h: 38 * u, style: .drogo, facing: -1, t: t)
            DragonKit.eggs(c, at: CGPoint(x: env.w * 0.2, y: gy + 7 * u), u: 1.2 * u, t: t, glow: 0.45)
            // Petals in the air.
            for i in 0..<16 {
                let a = M.fract(t * 0.07 + M.rand(i, 5))
                let p = CGPoint(x: env.w * CGFloat(M.rand(i, 6)) + CGFloat(sin(t + Double(i))) * 6 * u, y: -4 * u + CGFloat(a) * (env.h + 8 * u))
                c.fill(Ink.ellipse(p, 1.6 * u, 0.9 * u), with: .color(RGB(1, 0.82, 0.86).color(0.8)))
            }
        case 1:
            let bob = CGFloat(sin(t * 3.5)) * 0.6 * u
            Crowd.draw(c, env, kind: .riders, count: 16, xRange: -20...(env.w + 20), yFar: hy + 6 * u, yNear: hy + 30 * u, sFar: 0.6, sNear: 1.05,
                       speed: 46, far: RGB(0.42, 0.26, 0.17), near: RGB(0.20, 0.11, 0.08), seed: 4)
            // Drogo and Daenerys on horses, with the three eggs.
            let frame = Int(t * 7) & 3
            let drogoAt = CGPoint(x: env.w * 0.74, y: hy + 33 * u)
            c.fill(Stamps.rider[frame].applying(CGAffineTransform(translationX: drogoAt.x, y: drogoAt.y + bob).scaledBy(x: 1.45 * u, y: 1.45 * u)),
                   with: .color(RGB(0.10, 0.06, 0.05).color()))
            let danyAt = CGPoint(x: env.w * 0.52, y: hy + 33 * u)
            let hs = 1.3 * u
            c.fill(Stamps.horse[frame].applying(CGAffineTransform(translationX: danyAt.x, y: danyAt.y + bob).scaledBy(x: hs, y: hs)),
                   with: .color(RGB(0.86, 0.86, 0.9).color()))
            Figure.draw(c, feet: CGPoint(x: danyAt.x + 1 * u, y: danyAt.y + bob - 12.5 * hs), h: 20 * u, style: .dany(.dothraki), facing: 1, t: t, arms: 0.1)
            DragonKit.eggs(c, at: CGPoint(x: danyAt.x - 12 * u, y: danyAt.y + bob - 9 * hs), u: 0.55 * u, t: t, glow: 0.5)
            // Dust.
            for i in 0..<18 {
                let a = M.fract(t * 0.5 + M.rand(i, 8))
                let p = CGPoint(x: env.w * 0.52 - CGFloat(a) * 90 * u - CGFloat(M.rand(i, 9)) * 20 * u, y: danyAt.y - CGFloat(M.rand(i, 10)) * 6 * u - CGFloat(a) * 4 * u)
                c.fill(Ink.circle(p, (2 + CGFloat(a) * 5) * u), with: .color(RGB(0.85, 0.6, 0.4).color(0.28 * (1 - a))))
            }
        case 2:
            // Inside the tent: Drogo lies on his bed, Daenerys sits next to him.
            c.fill(Path(roundedRect: CGRect(x: env.w * 0.34, y: hy + 2 * u, width: env.w * 0.4, height: 14 * u), cornerRadius: 4 * u),
                   with: .color(RGB(0.55, 0.12, 0.12).color()))
            c.fill(Path(roundedRect: CGRect(x: env.w * 0.34, y: hy - 1 * u, width: env.w * 0.4, height: 5 * u), cornerRadius: 3 * u),
                   with: .color(RGB(0.78, 0.65, 0.4).color()))
            var lying = c
            lying.translateBy(x: env.w * 0.72, y: hy + 1 * u)
            lying.rotate(by: .degrees(-90))
            Figure.draw(lying, feet: .zero, h: 34 * u, style: .drogo, facing: 1, t: t, arms: 0)
            let hand = CGPoint(x: env.w * 0.56, y: hy - 5 * u)
            Daenerys.draw(c, base: CGPoint(x: env.w * 0.3, y: hy + 17 * u), u: 1.2 * u, hand: hand, t: t, rim: RGB(1, 0.6, 0.3).color(0.4), outfit: .dothraki)
            // Candle light on the wall.
            let cx = env.w * 0.86
            c.fill(Path(CGRect(x: cx - 1.2 * u, y: hy - 2 * u, width: 2.4 * u, height: 12 * u)), with: .color(RGB(0.9, 0.85, 0.7).color()))
            Fire.torch(c, at: CGPoint(x: cx, y: hy - 2 * u), size: 2.4 * u, t: t, seed: 7)
            Stage.wash(c, env, RGB(1, 0.5, 0.2), 0.08 + 0.04 * sin(t * 9))
            Stage.vignette(c, env, strength: 0.55)
        case 3:
            pyre(c, env, local: l)
        default:
            hatching(c, env, local: l)
        }
        // Soft cut between scenes: a quick dip to black.
        let half = 0.45 / env.total
        for edge in birthBeats.dropLast() {
            let d = abs(env.p - edge)
            if d < half { Stage.wash(c, env, RGB(0, 0, 0), 1 - d / half) }
        }
    }

    private static func pyre(_ c: GraphicsContext, _ env: SceneEnv, local l: Double) {
        let u = env.u, t = env.t, hy = env.hy
        let gy = hy + 22 * u
        let cx = env.w * 0.5
        Crowd.draw(c, env, kind: .soldiers, count: 26, xRange: 0...env.w, yFar: hy + 12 * u, yNear: hy + 34 * u, sFar: 0.7, sNear: 1,
                   speed: 0, far: RGB(0.14, 0.09, 0.08), near: RGB(0.07, 0.04, 0.04), seed: 21, standing: true)
        // Logs.
        for i in 0..<9 {
            let ang = Double(i) / 8 * .pi - .pi / 2
            let x = cx + CGFloat(sin(ang)) * 26 * u
            c.stroke(Path { $0.move(to: CGPoint(x: x, y: gy + 2 * u)); $0.addLine(to: CGPoint(x: cx + CGFloat(sin(ang)) * 7 * u, y: gy - 20 * u)) },
                     with: .color(RGB(0.28, 0.16, 0.09).color()), style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
        }
        c.fill(Path(roundedRect: CGRect(x: cx - 30 * u, y: gy, width: 60 * u, height: 5 * u), cornerRadius: 2 * u), with: .color(RGB(0.2, 0.11, 0.07).color()))
        // Daenerys walks into the fire.
        let walk = M.smoothstep(0.05, 0.5, l)
        let into = M.smoothstep(0.5, 0.85, l)
        let dx = M.lerp(env.w * 0.22, cx - 4 * u, CGFloat(walk))
        if into < 0.98 {
            var d = c
            d.opacity = 1 - into * 0.9
            Figure.draw(d, feet: CGPoint(x: dx, y: gy + 3 * u - CGFloat(into) * 6 * u), h: 32 * u, style: .dany(.dothraki), facing: 1, t: t, walk: walk < 0.98 ? 1 : 0, arms: into * 0.9)
        }
        let intensity = 0.25 + 1.0 * M.smoothstep(0.1, 0.9, l)
        Fire.flames(c, x0: cx - 32 * u, x1: cx + 32 * u, y: gy + 2 * u, height: (30 + 45 * CGFloat(l)) * u, intensity: intensity, t: t, seed: 5, u: u)
        // The glowing figure inside the flames.
        if into > 0.3 {
            let a = M.smoothstep(0.3, 0.8, into)
            var g = c
            g.blendMode = .plusLighter
            Figure.draw(g, feet: CGPoint(x: cx, y: gy - 2 * u), h: 30 * u, style: .dany(.pyre), facing: 1, t: t, arms: 0.8)
            g.fill(Ink.ellipse(CGPoint(x: cx, y: gy - 20 * u), 14 * u, 22 * u), with: .radialGradient(
                Gradient(colors: [RGB(1, 0.9, 0.6).color(0.35 * a), RGB(1, 0.9, 0.6).color(0)]),
                center: CGPoint(x: cx, y: gy - 20 * u), startRadius: 0, endRadius: 22 * u))
        }
        Fire.smoke(c, x0: cx - 20 * u, x1: cx + 20 * u, y: gy - 30 * u, rise: 60 * u, t: t, u: u, opacity: 0.4)
        Fire.embers(c, env, x0: cx - 30 * u, x1: cx + 30 * u, y: gy - 10 * u, count: 30, rise: 90 * u)
        Stage.wash(c, env, RGB(1, 0.45, 0.1), 0.12 * intensity)
    }

    private static func hatching(_ c: GraphicsContext, _ env: SceneEnv, local l: Double) {
        let u = env.u, t = env.t, hy = env.hy
        let gy = hy + 24 * u
        let cx = env.w * 0.5
        // Smoldering ashes.
        Fire.flames(c, x0: cx - 26 * u, x1: cx + 26 * u, y: gy + 3 * u, height: 7 * u, intensity: 0.35, t: t, seed: 9, u: u)
        Fire.smoke(c, x0: cx - 26 * u, x1: cx + 26 * u, y: gy - 2 * u, rise: 70 * u, t: t, u: u, opacity: 0.28, wind: 14)
        // Kneeling Dothraki, more of them as the scene goes.
        let n = Int(6 + 34 * M.smoothstep(0.1, 0.9, l))
        Crowd.draw(c, env, kind: .kneelers, count: n, xRange: 0...env.w, yFar: hy + 12 * u, yNear: hy + 36 * u, sFar: 0.7, sNear: 1.2,
                   speed: 0, far: RGB(0.18, 0.12, 0.12), near: RGB(0.06, 0.04, 0.05), seed: 31, standing: true)
        let rise = CGFloat(M.smoothstep(0, 0.25, l))
        Figure.draw(c, feet: CGPoint(x: cx, y: gy), h: 36 * u, style: .dany(.pyre), facing: 1, t: t, arms: 0.5 + 0.2 * sin(t * 0.8))
        // The three newborns: Drogon on her shoulder, Rhaegal in the air, Viserion at her feet.
        let a = Double(rise)
        if a > 0.05 {
            var d = c
            d.opacity = a
            DragonKit.sitting(d, base: CGPoint(x: cx - 7 * u, y: gy - 24 * u), scale: 0.1 * u, t: t, palette: .drogon, facing: 1)
            DragonKit.fly(d, at: CGPoint(x: cx + 24 * u + CGFloat(sin(t * 0.9)) * 4 * u, y: gy - 44 * u + CGFloat(sin(t * 2)) * 3 * u),
                          scale: 0.12 * u, climb: 0.1, facing: -1, t: t, palette: .rhaegal, hz: 2.4)
            DragonKit.sitting(d, base: CGPoint(x: cx + 16 * u, y: gy + 4 * u), scale: 0.11 * u, t: t, palette: .viserion, facing: -1, eyesClosed: false)
        }
        // Golden light and sparkles.
        var g = c
        g.blendMode = .plusLighter
        g.fill(Ink.circle(CGPoint(x: cx, y: gy - 22 * u), 50 * u), with: .radialGradient(
            Gradient(colors: [RGB(1, 0.8, 0.45).color(0.22), RGB(1, 0.8, 0.45).color(0)]),
            center: CGPoint(x: cx, y: gy - 22 * u), startRadius: 0, endRadius: 50 * u))
        for i in 0..<10 {
            let age = M.fract(t * 0.3 + M.rand(i, 40))
            let p = CGPoint(x: cx + CGFloat(M.rand(i, 41) - 0.5) * 90 * u, y: gy - CGFloat(age) * 70 * u)
            g.fill(Ink.sparkle(p, (1 + 2 * CGFloat(sin(.pi * age))) * u), with: .color(RGB(1, 0.9, 0.6).color(sin(.pi * age))))
        }
        // Ash falls.
        for i in 0..<14 {
            let age = M.fract(t * 0.12 + M.rand(i, 42))
            let p = CGPoint(x: env.w * CGFloat(M.rand(i, 43)) + CGFloat(sin(t * 0.7 + Double(i))) * 5 * u, y: CGFloat(age) * env.h)
            c.fill(Ink.circle(p, 0.7 * u), with: .color(RGB(0.7, 0.65, 0.65).color(0.55)))
        }
    }

    // MARK: - Chapter 2: Red Waste → Qarth

    static func qarthBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, hy = env.hy
        if p < 0.8 {
            let top = RGB.lerp(Backdrop.daySky.0, RGB(0.45, 0.25, 0.38), M.smoothstep(0.4, 0.8, p))
            let bot = RGB.lerp(RGB(0.97, 0.82, 0.62), Backdrop.duskSky.1, M.smoothstep(0.4, 0.8, p))
            Stage.paintBackdrop(c, env, Backdrop(skyTop: top, skyBottom: bot, sun: (0.22 + 0.2 * CGFloat(p), 0.42 + 0.2 * CGFloat(p), RGB(1, 0.85, 0.55), 10),
                ground: .land(far: RGB(0.86, 0.62, 0.40), near: RGB(0.6, 0.36, 0.22))))
            Stage.hills(c, env, color: RGB(0.78, 0.52, 0.34), y: hy - 1 * u, amp: 5 * u, freq: 2.4, phase: 1)
            let k = M.smoothstep(0.3, 0.75, p)
            if k > 0.02 { Buildings.qarth(c, env, x0: M.lerp(env.w * 1.05, env.w * 0.5, CGFloat(k)), scale: CGFloat(0.5 + 0.5 * k)) }
        } else {
            // The House of the Undying.
            c.fill(Path(CGRect(origin: .zero, size: env.size)), with: .linearGradient(
                Gradient(colors: [RGB(0.05, 0.03, 0.12).color(), RGB(0.2, 0.1, 0.32).color()]), startPoint: .zero, endPoint: CGPoint(x: 0, y: env.h)))
            for i in 0..<6 {
                let x = env.w * (0.05 + 0.18 * CGFloat(i))
                c.fill(Path(CGRect(x: x, y: 0, width: 9 * u, height: env.h)), with: .color(RGB(0.1, 0.06, 0.2).color()))
            }
            c.fill(Path(CGRect(x: 0, y: hy + 10 * u, width: env.w, height: env.h)), with: .color(RGB(0.08, 0.05, 0.14).color()))
        }
    }

    static func qarthForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let size = DragonKit.size(.qarth)
        if p < 0.8 {
            Crowd.draw(c, env, kind: .riders, count: 14, xRange: -20...(env.w + 20), yFar: hy + 8 * u, yNear: hy + 32 * u, sFar: 0.6, sNear: 1.05,
                       speed: 40, far: RGB(0.46, 0.28, 0.18), near: RGB(0.22, 0.12, 0.08), seed: 12)
            let danyAt = CGPoint(x: env.w * 0.5, y: hy + 33 * u)
            let frame = Int(t * 6) & 3
            let hs = 1.25 * u, bob = CGFloat(sin(t * 3)) * 0.6 * u
            c.fill(Stamps.horse[frame].applying(CGAffineTransform(translationX: danyAt.x, y: danyAt.y + bob).scaledBy(x: hs, y: hs)), with: .color(RGB(0.86, 0.86, 0.9).color()))
            Figure.draw(c, feet: CGPoint(x: danyAt.x + 1 * u, y: danyAt.y + bob - 12.5 * hs), h: 20 * u, style: .dany(.dothraki), facing: 1, t: t, arms: 0.1)
            // The three little dragons fly along.
            for (i, d) in Dragon.allCases.enumerated() {
                let a = Double(i) * 2.1
                let pos = CGPoint(x: danyAt.x + CGFloat(i - 1) * 24 * u + CGFloat(sin(t * 0.9 + a)) * 5 * u, y: danyAt.y - 38 * u - CGFloat(i % 2) * 8 * u + CGFloat(sin(t * 2.6 + a)) * 3 * u)
                DragonKit.fly(c, at: pos, scale: size * u, climb: 0.05, facing: 1, t: t, palette: .of(d), hz: 2.4, offset: a)
            }
            Stage.hazeDust(c, env, y: hy + 36 * u)
        } else {
            // Drogon's first "Dracarys".
            let gy = hy + 22 * u
            let pyat = CGPoint(x: env.w * 0.66, y: gy)
            let burn = M.smoothstep(0.84, 0.92, p)
            Figure.draw(c, feet: pyat, h: 36 * u, style: FigureStyle(skin: RGB(0.6, 0.7, 0.8), cloth: RGB(0.35, 0.2, 0.55), cloth2: RGB(0.7, 0.6, 0.85), hair: RGB(0.2, 0.2, 0.25), hairKind: .hood), facing: -1, t: t, arms: 0.4)
            Figure.draw(c, feet: CGPoint(x: env.w * 0.3, y: gy), h: 34 * u, style: .dany(.dothraki), facing: 1, t: t, arms: 0.55)
            let dpos = CGPoint(x: env.w * 0.42, y: gy - 28 * u + CGFloat(sin(t * 2)) * 2 * u)
            DragonKit.fly(c, at: dpos, scale: 0.2 * u, climb: -0.08, facing: 1, t: t, palette: .drogon, hz: 2.6)
            if burn > 0.01 {
                let m = DragonKit.mouth(at: dpos, scale: 0.2 * u, climb: -0.08, facing: 1)
                let ang = atan2(Double(pyat.y - 14 * u - m.y), Double(pyat.x - m.x))
                Fire.breath(c, from: m, angle: ang, length: hypot(pyat.x - m.x, pyat.y - m.y), t: t, u: u, intensity: burn)
                Fire.flames(c, x0: pyat.x - 8 * u, x1: pyat.x + 8 * u, y: pyat.y, height: 38 * u * CGFloat(burn), intensity: burn, t: t, seed: 4, u: u)
                Stage.wash(c, env, RGB(1, 0.5, 0.2), 0.16 * burn)
            }
            // Blue light of the House.
            Stage.wash(c, env, RGB(0.3, 0.2, 0.8), 0.1)
            Stage.vignette(c, env, strength: 0.5)
        }
        let d = abs(p - 0.8), half = 0.45 / env.total
        if d < half { Stage.wash(c, env, RGB(0, 0, 0), 1 - d / half) }
    }

    // MARK: - Chapter 3: Astapor

    static func astaporBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, hy = env.hy
        let k = M.smoothstep(0, 1, p)
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB.lerp(RGB(0.28, 0.4, 0.7), RGB(0.3, 0.2, 0.45), k), skyBottom: RGB.lerp(RGB(0.98, 0.8, 0.6), RGB(1, 0.55, 0.3), k),
            sun: (0.2 + 0.3 * CGFloat(k), 0.4 + 0.12 * CGFloat(k), RGB(1, 0.85, 0.55), 9), ground: .land(far: RGB(0.82, 0.58, 0.38), near: RGB(0.56, 0.34, 0.22))))
        Buildings.astapor(c, env, t: 0)
        Stage.hills(c, env, color: RGB(0.7, 0.45, 0.3), y: hy + 14 * u, amp: 3 * u, freq: 2.6, phase: 0.3)
    }

    static func astaporForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let gy = hy + 24 * u
        let march = M.smoothstep(0.62, 1, p)
        // Unsullied: standing in ranks, then marching right.
        let ox = env.w * 0.56 + CGFloat(march) * 40 * u + CGFloat(t) * 0
        Crowd.formation(c, env, kind: .unsullied, cols: 9, rows: 3, origin: CGPoint(x: ox, y: gy - 8 * u), dx: 9, dy: 7, scale: 1.05,
                        color: RGB(0.22, 0.2, 0.24), dir: 1, march: march > 0.05)
        // Kraznys on his platform.
        let burn = M.smoothstep(0.40, 0.50, p) * (1 - M.smoothstep(0.72, 0.8, p))
        let kx = env.w * 0.16
        c.fill(Path(roundedRect: CGRect(x: kx - 22 * u, y: gy - 2 * u, width: 44 * u, height: 8 * u), cornerRadius: 2 * u), with: .color(RGB(0.5, 0.3, 0.2).color()))
        if p < 0.78 {
            Figure.draw(c, feet: CGPoint(x: kx, y: gy - 2 * u), h: 36 * u, style: .kraznys, facing: 1, t: t, arms: 0.5 + 0.2 * sin(t * 2))
        }
        Figure.draw(c, feet: CGPoint(x: env.w * 0.42 + CGFloat(march) * 36 * u, y: gy + 2 * u), h: 34 * u, style: .dany(.blue), facing: 1, t: t, walk: march > 0.05 ? 1 : 0, arms: 0.2)
        // Drogon: from her shoulder to the sky.
        let dpos = CGPoint(x: env.w * 0.40 + CGFloat(march) * 36 * u, y: gy - 34 * u + CGFloat(sin(t * 2.2)) * 2.5 * u)
        DragonKit.fly(c, at: dpos, scale: 0.24 * u, climb: -0.1, facing: -1, t: t, palette: .drogon, hz: 2.2)
        if burn > 0.01 {
            let m = DragonKit.mouth(at: dpos, scale: 0.24 * u, climb: -0.1, facing: -1)
            let target = CGPoint(x: kx, y: gy - 20 * u)
            Fire.breath(c, from: m, angle: atan2(Double(target.y - m.y), Double(target.x - m.x)), length: hypot(target.x - m.x, target.y - m.y), t: t, u: u, intensity: burn)
            Fire.flames(c, x0: kx - 7 * u, x1: kx + 7 * u, y: gy - 2 * u, height: 40 * u * CGFloat(burn), intensity: burn, t: t, seed: 2, u: u)
            Stage.wash(c, env, RGB(1, 0.5, 0.2), 0.14 * burn)
        }
        if p > 0.62 {
            // The other two dragons join.
            for (i, d) in [Dragon.rhaegal, .viserion].enumerated() {
                let a = Double(i) * 1.7 + 1
                DragonKit.fly(c, at: CGPoint(x: env.w * (0.3 + 0.18 * CGFloat(i)) + CGFloat(march) * 36 * u, y: gy - 56 * u - CGFloat(i) * 8 * u + CGFloat(sin(t * 2.4 + a)) * 3 * u),
                              scale: 0.2 * u, climb: 0.05, facing: 1, t: t, palette: .of(d), hz: 2.3, offset: a)
            }
        }
        Stage.hazeDust(c, env, y: gy + 6 * u)
    }

    // MARK: - Chapter 4: Vaes Dothrak

    static func vaesBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        if env.calm { vaesRoadBackground(c, env); return }
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB(0.02, 0.03, 0.09), skyBottom: RGB(0.22, 0.10, 0.12), stars: 1,
            ground: .land(far: RGB(0.14, 0.11, 0.08), near: RGB(0.05, 0.04, 0.04))))
        Stage.hills(c, env, color: RGB(0.09, 0.07, 0.07), y: env.hy + 2 * env.u, amp: 3 * env.u, freq: 2, phase: 0.8)
    }

    static func vaesForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        if env.calm { JourneyLate.vaesRoad(c, env); return }
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let gy = hy + 24 * u, cx = env.w * 0.5
        // The temple: a big wooden hall with a pointed roof.
        var hall = Path()
        hall.move(to: CGPoint(x: cx - 44 * u, y: gy))
        hall.addLine(to: CGPoint(x: cx - 44 * u, y: gy - 26 * u))
        hall.addLine(to: CGPoint(x: cx, y: gy - 58 * u))
        hall.addLine(to: CGPoint(x: cx + 44 * u, y: gy - 26 * u))
        hall.addLine(to: CGPoint(x: cx + 44 * u, y: gy))
        hall.closeSubpath()
        c.fill(hall, with: .linearGradient(Gradient(colors: [RGB(0.12, 0.07, 0.05).color(), RGB(0.3, 0.16, 0.08).color()]),
                                           startPoint: CGPoint(x: cx, y: gy - 58 * u), endPoint: CGPoint(x: cx, y: gy)))
        var door = Path()
        door.move(to: CGPoint(x: cx - 9 * u, y: gy)); door.addLine(to: CGPoint(x: cx - 9 * u, y: gy - 20 * u))
        door.addQuadCurve(to: CGPoint(x: cx + 9 * u, y: gy - 20 * u), control: CGPoint(x: cx, y: gy - 32 * u)); door.addLine(to: CGPoint(x: cx + 9 * u, y: gy))
        door.closeSubpath()
        c.fill(door, with: .color(RGB(0.9, 0.35, 0.05).color(0.15 + 0.7 * M.smoothstep(0, 0.4, p))))
        let intensity = 0.15 + 1.1 * M.smoothstep(0.05, 0.55, p)
        Fire.flames(c, x0: cx - 42 * u, x1: cx + 42 * u, y: gy, height: 70 * u, intensity: intensity, t: t, seed: 15, u: u)
        Fire.flames(c, x0: cx - 30 * u, x1: cx + 30 * u, y: gy - 24 * u, height: 40 * u, intensity: intensity * M.smoothstep(0.25, 0.6, p), t: t + 1, seed: 16, u: u)
        Fire.smoke(c, x0: cx - 30 * u, x1: cx + 30 * u, y: gy - 50 * u, rise: 70 * u, t: t, u: u, opacity: 0.4, wind: 16)
        Fire.embers(c, env, x0: cx - 40 * u, x1: cx + 40 * u, y: gy - 20 * u, count: 34, rise: 100 * u)
        // Daenerys steps out of the flames.
        let out = M.smoothstep(0.55, 0.8, p)
        if out > 0.01 {
            let pos = CGPoint(x: cx, y: gy + 16 * u * CGFloat(out))
            var g = c
            g.opacity = Double(min(1, out * 2))
            Figure.draw(g, feet: pos, h: (24 + 12 * CGFloat(out)) * u, style: .dany(.white), facing: 1, t: t, arms: 0.85)
            var glow = c
            glow.blendMode = .plusLighter
            glow.fill(Ink.circle(CGPoint(x: pos.x, y: pos.y - 18 * u), 22 * u), with: .radialGradient(
                Gradient(colors: [RGB(1, 0.85, 0.55).color(0.3 * out), RGB(1, 0.85, 0.55).color(0)]), center: CGPoint(x: pos.x, y: pos.y - 18 * u), startRadius: 0, endRadius: 22 * u))
        }
        // Thousands kneel.
        let n = Int(4 + 52 * M.smoothstep(0.65, 0.98, p))
        Crowd.draw(c, env, kind: .kneelers, count: n, xRange: 0...env.w, yFar: hy + 22 * u, yNear: hy + 38 * u, sFar: 0.8, sNear: 1.25,
                   speed: 0, far: RGB(0.2, 0.12, 0.1), near: RGB(0.06, 0.04, 0.04), seed: 41, standing: true)
        Stage.wash(c, env, RGB(1, 0.45, 0.1), 0.1 * intensity)
        Stage.vignette(c, env)
    }
}

extension Stage {
    /// Low dust haze along the ground.
    static func hazeDust(_ c: GraphicsContext, _ env: SceneEnv, y: CGFloat) {
        c.fill(Path(CGRect(x: 0, y: y - 6 * env.u, width: env.w, height: 14 * env.u)), with: .linearGradient(
            Gradient(colors: [RGB(0.9, 0.7, 0.5).color(0), RGB(0.9, 0.7, 0.5).color(0.18), RGB(0.9, 0.7, 0.5).color(0)]),
            startPoint: CGPoint(x: 0, y: y - 6 * env.u), endPoint: CGPoint(x: 0, y: y + 8 * env.u)))
    }
}
