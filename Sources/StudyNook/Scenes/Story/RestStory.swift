import SwiftUI
import StudyNookCore

/// Rest scenes: Daenerys with her dragons, changing with the chapter just finished.
/// Happy rests have hearts and warm light. After Viserion and Rhaegal fall, the rests are quiet and blue,
/// with the fallen dragons lying beside the living ones as pale ghosts. The last rest is the burning city.
enum RestStory {
    static let petPeriod = 2.8

    static func isSad(_ ch: Chapter) -> Bool {
        switch ch {
        case .beyondWall, .winterfell, .rhaegal: true
        default: false
        }
    }

    /// Size of lying dragons by chapter.
    static func restScale(_ ch: Chapter) -> CGFloat {
        switch ch {
        case .birth: 0.34
        case .qarth: 0.40
        case .astapor: 0.48
        case .vaesDothrak: 0.58
        case .meereen: 0.70
        case .sailing: 0.80
        case .goldenRoad: 0.86
        default: 0.92
        }
    }

    private static func layout(_ env: SceneEnv) -> (B: CGPoint, ground: (CGFloat) -> CGFloat) {
        let B = CGPoint(x: env.w * 0.36, y: env.h * 0.69)
        let cx = B.x + 22 * env.u
        return (B, { x in B.y + pow((x - cx) / (env.w * 0.5), 2) * env.h * 0.5 })
    }

    // MARK: - Background

    static func background(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
        let u = env.u, hy = env.hy
        let calm = SceneEnv(size: env.size, t: env.t, p: 0.9, total: env.total)
        let sunset = M.smoothstep(0, 1, env.p)
        switch ch {
        case .birth:
            Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB(0.03, 0.04, 0.11), skyBottom: RGB(0.26, 0.13, 0.16), stars: 1, ground: .land(far: RGB(0.14, 0.09, 0.09), near: RGB(0.05, 0.04, 0.05))))
        case .qarth:
            Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB.lerp(RGB(0.32, 0.2, 0.42), RGB(0.03, 0.04, 0.12), sunset), skyBottom: RGB.lerp(RGB(1, 0.62, 0.38), RGB(0.3, 0.18, 0.32), sunset),
                sun: (0.8, 0.45 + 0.4 * CGFloat(sunset), RGB(1, 0.7, 0.4), 11), stars: sunset, ground: .land(far: RGB(0.42, 0.26, 0.2), near: RGB(0.14, 0.09, 0.09))))
        case .astapor, .meereen:
            JourneyEarly.astaporBackground(c, SceneEnv(size: env.size, t: env.t, p: 0.55 + 0.4 * sunset, total: env.total))
        case .vaesDothrak:
            JourneyEarly.vaesBackground(c, env)
            // Many campfires of the horde in the distance.
            for i in 0..<14 {
                let x = env.w * CGFloat(M.rand(i, 120)), y = hy + (3 + 10 * CGFloat(M.rand(i, 121))) * u
                c.fill(Ink.circle(CGPoint(x: x, y: y), 5 * u), with: .radialGradient(Gradient(colors: [RGB(1, 0.5, 0.15).color(0.5), RGB(1, 0.5, 0.15).color(0)]), center: CGPoint(x: x, y: y), startRadius: 0, endRadius: 5 * u))
            }
        case .sailing:
            JourneyLate.sailingBackground(c, SceneEnv(size: env.size, t: env.t, p: 0.6 + 0.4 * sunset, total: env.total))
        case .goldenRoad:
            Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB(0.03, 0.05, 0.14), skyBottom: RGB(0.2, 0.18, 0.34), moon: CGPoint(x: 0.2, y: 0.26), stars: 1,
                ground: .sea(top: RGB(0.1, 0.14, 0.26), bottom: RGB(0.02, 0.04, 0.1))))
            Landscape.dragonstone(c, base: CGPoint(x: env.w * 0.92, y: hy + 2 * u), u: 0.9 * u, t: 0, rock: RGB(0.2, 0.2, 0.28))
        case .beyondWall: JourneyLate.wallBackground(c, calm)
        case .winterfell: JourneyLate.winterfellBackground(c, calm)
        case .rhaegal: JourneyLate.rhaegalBackground(c, SceneEnv(size: env.size, t: env.t, p: 1, total: env.total))
        case .kingsLanding: JourneyLate.landingBurnBackground(c, env)
        case .epilogue:
            Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB(0.18, 0.2, 0.42), skyBottom: RGB(1.0, 0.7, 0.5), sun: (0.88, 0.62, RGB(1, 0.85, 0.55), 12),
                ground: .sea(top: RGB(0.5, 0.4, 0.5), bottom: RGB(0.08, 0.1, 0.2))))
        }
        if ch != .kingsLanding && ch != .epilogue {
            // The hill where Daenerys sits.
            let (B, ground) = layout(env)
            var hill = Path()
            var ridge = Path()
            hill.move(to: CGPoint(x: 0, y: env.h))
            for x in stride(from: CGFloat(0), through: env.w, by: 4) {
                let y = min(env.h + 2, ground(x))
                hill.addLine(to: CGPoint(x: x, y: y))
                if x == 0 { ridge.move(to: CGPoint(x: x, y: y)) } else { ridge.addLine(to: CGPoint(x: x, y: y)) }
            }
            hill.addLine(to: CGPoint(x: env.w, y: env.h))
            hill.closeSubpath()
            c.fill(hill, with: .linearGradient(Gradient(colors: [RGB(0.17, 0.10, 0.18).color(), RGB(0.06, 0.04, 0.09).color()]),
                                               startPoint: CGPoint(x: 0, y: B.y), endPoint: CGPoint(x: 0, y: env.h)))
            var textured = c
            textured.clip(to: hill)
            Stage.groundTexture(textured, env, y0: B.y, y1: env.h, color: RGB(0.34, 0.24, 0.34), density: 70, seed: 5, grass: true)
            c.stroke(ridge, with: .color((isSad(ch) ? RGB(0.5, 0.6, 0.85) : RGB(1, 0.62, 0.42)).color(0.3)), lineWidth: u)
        }
    }

    // MARK: - Foreground

    static func foreground(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
        switch ch {
        case .kingsLanding:
            finalFire(c, env)
        case .epilogue:
            epilogue(c, env)
        default:
            tableau(c, env, ch)
        }
    }

    private static func tableau(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
        let u = env.u, t = env.t
        let (B, ground) = layout(env)
        let sad = isSad(ch)
        let s = restScale(ch) * u
        let k = restScale(ch) / 0.9

        // Petting rhythm: the hand strokes the head, then lifts and comes back.
        let phi = M.fract(t / petPeriod)
        let lift = phi < 0.62 ? sin(.pi * phi / 0.62) : 0
        let eyesClosed = phi > 0.04 && phi < 0.74

        // Dragons lie to the right of Daenerys, facing her.
        let alive = Dragon.allCases.filter { ch.dragons.contains($0) }
        var rigs: [(Dragon, RestDragonRig)] = []
        for (i, d) in alive.enumerated() {
            let x = B.x + (16 + 28 * k + CGFloat(i) * 34 * k) * u
            let y = ground(x) + (i == 0 ? 0 : -CGFloat(i) * 1.5 * u)
            let rig = RestDragonRig(base: CGPoint(x: x, y: y), scale: s * (i == 0 ? 1 : 0.94), t: t + Double(i) * 1.3, lift: i == 0 ? lift : 0.1)
            rigs.append((d, rig))
        }
        // Fallen dragons: pale ghosts further away.
        for (i, d) in ch.fallen.enumerated() {
            let x = B.x + (16 + 28 * k + CGFloat(alive.count + i) * 34 * k) * u
            let rig = RestDragonRig(base: CGPoint(x: x, y: ground(x)), scale: s * 0.94, t: t * 0.6 + Double(i), lift: 0)
            var g = c
            g.opacity = 0.6 + 0.15 * sin(t * 0.8 + Double(i))
            DragonPainter.drawResting(g, rig: rig, t: t * 0.6, eyesClosed: true, palette: .ghost(d))
            // Fireflies rise from the ghost.
            var glow = c
            glow.blendMode = .plusLighter
            for j in 0..<6 {
                let age = M.fract(t * 0.18 + M.rand(j, 130 + i))
                let q = CGPoint(x: x + CGFloat(M.rand(j, 131) - 0.5) * 30 * u, y: rig.pose.position.y - CGFloat(age) * 40 * u)
                glow.fill(Ink.circle(q, 1.1 * u), with: .color(RGB(0.7, 0.85, 1).color(0.9 * sin(.pi * age))))
            }
        }
        // Draw far dragons first so the main one is on top.
        for (d, rig) in rigs.reversed() {
            DragonPainter.drawResting(c, rig: rig, t: t, eyesClosed: d == .drogon ? eyesClosed : true, palette: .of(d))
        }

        // Jorah's grave after Winterfell.
        if ch == .winterfell {
            let gx = B.x - 42 * u
            let gyy = ground(gx)
            c.stroke(Path { $0.move(to: CGPoint(x: gx, y: gyy + 2 * u)); $0.addLine(to: CGPoint(x: gx, y: gyy - 24 * u)) }, with: .color(RGB(0.75, 0.78, 0.86).color()), lineWidth: 1.4 * u)
            c.stroke(Path { $0.move(to: CGPoint(x: gx - 5 * u, y: gyy - 17 * u)); $0.addLine(to: CGPoint(x: gx + 5 * u, y: gyy - 17 * u)) }, with: .color(RGB(0.75, 0.78, 0.86).color()), lineWidth: 1.4 * u)
            c.fill(Path { p in
                p.move(to: CGPoint(x: gx + 1 * u, y: gyy - 15 * u)); p.addQuadCurve(to: CGPoint(x: gx + 9 * u, y: gyy + 1 * u), control: CGPoint(x: gx + 9 * u + CGFloat(sin(t)) * u, y: gyy - 8 * u))
                p.addLine(to: CGPoint(x: gx + 1 * u, y: gyy)); p.closeSubpath()
            }, with: .color(RGB(0.3, 0.23, 0.16).color()))
            Fire.torch(c, at: CGPoint(x: gx - 12 * u, y: gyy - 2 * u), size: 2.4 * u, t: t, seed: 12)
        }

        // Jon Snow joins after the Golden Road.
        if ch.rawValue >= Chapter.goldenRoad.rawValue && ch != .winterfell || ch == .winterfell {
            let jx = B.x - 30 * u
            Figure.draw(c, feet: CGPoint(x: jx, y: ground(jx) + 1 * u), h: 36 * u, style: .jon, facing: 1, t: t, arms: 0)
        }

        // Daenerys strokes the first dragon's head.
        let (_, main) = rigs[0]
        let front = main.headWorld(CGPoint(x: 11, y: -5.4)), back = main.headWorld(CGPoint(x: 2, y: -6.3))
        var hand: CGPoint
        if phi < 0.62 {
            hand = M.lerp(front, back, CGFloat(M.easeInOut(phi / 0.62)))
        } else {
            let q = (phi - 0.62) / 0.38
            hand = M.lerp(back, front, CGFloat(M.easeInOut(q)))
            hand.y -= CGFloat(sin(.pi * q)) * 4 * u
        }
        Daenerys.draw(c, base: B, u: u, hand: hand, t: t, rim: (sad ? RGB(0.5, 0.6, 0.9) : RGB(1, 0.65, 0.4)).color(0.35), outfit: .of(ch))

        if sad {
            // Quiet blue light and slow snow, no hearts.
            Stage.wash(c, env, RGB(0.3, 0.45, 0.8), 0.1)
            Stage.snow(c, env)
        } else {
            let nostril = main.headWorld(DragonPainter.nostrilLocal)
            for q in 0..<3 {
                let a = M.fract(t / 3.3 + Double(q) / 3)
                let pt = CGPoint(x: nostril.x - CGFloat(a) * 8 * u, y: nostril.y - CGFloat(a) * 9 * u)
                c.stroke(Ink.circle(pt, (0.8 + CGFloat(a) * 2.6) * u), with: .color(.white.opacity(0.35 * (1 - a) * M.smoothstep(0, 0.15, a))), lineWidth: 0.7 * u)
            }
            let hb = main.headWorld(CGPoint(x: 5, y: -9))
            for q in 0..<2 {
                let a = M.fract(t / 3.6 + Double(q) * 0.5)
                let pt = CGPoint(x: hb.x + CGFloat(sin(a * 5 + Double(q) * 2)) * 2.5 * u + CGFloat(q) * 5 * u, y: hb.y - CGFloat(a) * 26 * u)
                c.fill(Ink.heart(pt, (3.5 + 3 * CGFloat(a)) * u), with: .color(RGB(1, 0.42, 0.55).color(sin(.pi * a) * 0.9)))
            }
        }
        // Fireflies.
        var g = c
        g.blendMode = .plusLighter
        for i in 0..<10 {
            let bx = env.w * CGFloat(M.rand(i, 70)), by = env.h * CGFloat(0.35 + 0.5 * M.rand(i, 71))
            let q = CGPoint(x: bx + CGFloat(sin(t * 0.45 + Double(i))) * 9 * u, y: by + CGFloat(cos(t * 0.6 + Double(i) * 1.3)) * 5 * u)
            let blink = pow(0.5 + 0.5 * sin(t * 1.6 + Double(i) * 2.1), 3) * (0.4 + 0.6 * env.p)
            let col = sad ? RGB(0.7, 0.85, 1) : RGB(1, 0.95, 0.55)
            g.fill(Ink.circle(q, 4 * u), with: .radialGradient(Gradient(colors: [col.color(0.5 * blink), col.color(0)]), center: q, startRadius: 0, endRadius: 4 * u))
            g.fill(Ink.circle(q, 0.8 * u), with: .color(col.color(blink)))
        }
        // A fire near the group in the first chapters.
        if ch == .birth || ch == .qarth {
            Fire.flames(c, x0: env.w * 0.12, x1: env.w * 0.12 + 14 * u, y: ground(env.w * 0.12) + 2 * u, height: 12 * u, intensity: 0.9, t: t, seed: 66, u: u)
        }
    }

    // MARK: - The final rest: the city burns

    private static func finalFire(_ c: GraphicsContext, _ env: SceneEnv) {
        JourneyLate.landingBurnForeground(c, env)
    }

    // MARK: - Epilogue rest

    private static func epilogue(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, t = env.t
        Landscape.clouds(c, env.size, u: u, t: t, tint: RGB(1, 0.85, 0.75), opacity: 0.7)
        for i in 0..<9 {
            let b = pow(max(0, sin(t * 1.5 + Double(i) * 1.9)), 8)
            guard b > 0.02 else { continue }
            c.fill(Ink.sparkle(CGPoint(x: env.w * CGFloat(M.rand(i, 140)), y: env.hy + (4 + 28 * CGFloat(M.rand(i, 141))) * u), (1 + 1.4 * CGFloat(b)) * u), with: .color(.white.opacity(b)))
        }
        // Drogon carries Daenerys east, toward the sunrise.
        let pos = CGPoint(x: env.w * (0.3 + 0.35 * CGFloat(M.smoothstep(0, 1, env.p))), y: env.h * 0.34 + CGFloat(sin(t * 1.4)) * 3 * u)
        DragonKit.fly(c, at: pos, scale: 0.62 * u, climb: 0.04, facing: 1, t: t, palette: .drogon, hz: 1.1)
        DragonKit.carry(c, at: pos, scale: 0.62 * u, climb: 0.04, facing: 1, t: t)
        var glow = c
        glow.blendMode = .plusLighter
        for i in 0..<16 {
            let age = M.fract(t * 0.5 + M.rand(i, 142))
            glow.fill(Ink.circle(CGPoint(x: pos.x - CGFloat(age) * 70 * u, y: pos.y + CGFloat(M.rand(i, 143) - 0.5) * 14 * u), (1.4 - age) * u), with: .color(RGB(1, 0.6, 0.25).color((1 - age) * 0.7)))
        }
    }
}
