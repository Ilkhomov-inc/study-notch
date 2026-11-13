import SwiftUI
import StudyNookCore

/// Chapters 5–12: Meereen, the crossing, Westeros, the Wall, Winterfell, Rhaegal, King's Landing, the epilogue.
enum JourneyLate {
    // MARK: - Chapter 5: the speech on Drogon's back

    static func meereenBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, hy = env.hy
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB.lerp(Backdrop.daySky.0, Backdrop.duskSky.0, M.smoothstep(0.5, 1, p)),
            skyBottom: RGB.lerp(RGB(0.95, 0.85, 0.7), Backdrop.duskSky.1, M.smoothstep(0.5, 1, p)),
            sun: (0.5, 0.46 + 0.2 * CGFloat(M.smoothstep(0.5, 1, p)), RGB(1, 0.88, 0.6), 10),
            ground: .land(far: RGB(0.62, 0.55, 0.36), near: RGB(0.36, 0.3, 0.2))))
        // Gorge walls open up into the plain.
        let open = CGFloat(M.smoothstep(0.1, 0.5, p))
        for side in [CGFloat(0), 1] {
            var w = Path()
            let edge = M.lerp(env.w * 0.34, -20 * u, open)
            let x0 = side == 0 ? CGFloat(-10) : env.w + 10
            let x1 = side == 0 ? edge : env.w - edge
            w.move(to: CGPoint(x: x0, y: env.h))
            w.addLine(to: CGPoint(x: x0, y: 0))
            w.addLine(to: CGPoint(x: x1, y: 0))
            w.addLine(to: CGPoint(x: x1 + (side == 0 ? -8 : 8) * u, y: env.h * 0.4))
            w.addLine(to: CGPoint(x: x1 + (side == 0 ? -2 : 2) * u, y: hy + 6 * u))
            w.addLine(to: CGPoint(x: x1, y: env.h))
            w.closeSubpath()
            c.fill(w, with: .linearGradient(Gradient(colors: [RGB(0.55, 0.32, 0.22).color(), RGB(0.3, 0.16, 0.12).color()]),
                                            startPoint: CGPoint(x: x0, y: 0), endPoint: CGPoint(x: x1, y: 0)))
            // Layers of rock, a lit inner edge and a few ledges.
            var rock = c
            rock.clip(to: w)
            var strata = Path()
            for k in 0..<13 {
                let y = env.h * CGFloat(k) / 12
                strata.move(to: CGPoint(x: min(x0, x1) - 10, y: y))
                strata.addQuadCurve(to: CGPoint(x: max(x0, x1) + 10, y: y + 3 * u), control: CGPoint(x: (x0 + x1) / 2, y: y - 4 * u))
            }
            rock.stroke(strata, with: .color(RGB(0.2, 0.09, 0.06).color(0.38)), lineWidth: 1.1 * u)
            rock.stroke(strata.applying(CGAffineTransform(translationX: 0, y: 1.6 * u)), with: .color(RGB(0.95, 0.62, 0.42).color(0.2)), lineWidth: 0.7 * u)
            rock.stroke(w, with: .color(RGB(1, 0.75, 0.5).color(0.35)), lineWidth: 3 * u)
        }
        Stage.hills(c, env, color: RGB(0.45, 0.38, 0.25), y: hy + 8 * u, amp: 3 * u, freq: 2, phase: 1.2)
    }

    static func meereenForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let size = DragonKit.size(.meereen)
        // The horde, tens of thousands, waiting.
        Crowd.draw(c, env, kind: .riders, count: 46, xRange: 0...env.w, yFar: hy + 6 * u, yNear: hy + 38 * u, sFar: 0.55, sNear: 1.15,
                   speed: 0, far: RGB(0.40, 0.3, 0.2), near: RGB(0.14, 0.09, 0.07), seed: 51, standing: true)
        // Drogon arrives, then hovers over the crowd.
        let arrive = M.easeInOut(M.smoothstep(0, 0.3, p))
        let pos = CGPoint(x: M.lerp(env.w * 1.05, env.w * 0.5, CGFloat(arrive)), y: env.h * 0.36 + CGFloat(sin(t * 1.7)) * 2.5 * u)
        DragonKit.fly(c, at: pos, scale: size * u, climb: 0.04 * (1 - arrive), facing: -1, t: t, palette: .drogon, hz: 1.5)
        let b = DragonKit.back(at: pos, scale: size * u)
        Figure.draw(c, feet: b, h: DragonKit.riderHeight(size * u), style: .dany(.white), facing: -1, t: t, arms: p > 0.3 ? 0.55 + 0.35 * CGFloat(sin(t * 1.6)).magnitude : 0.2)
        if p > 0.45 {
            // The speech: rays of light and rising spears.
            let k = M.smoothstep(0.45, 0.75, p)
            var g = c
            g.blendMode = .plusLighter
            let glowAt = CGPoint(x: b.x, y: b.y - 8 * u)
            g.fill(Ink.circle(glowAt, 46 * u), with: .radialGradient(
                Gradient(colors: [RGB(1, 0.85, 0.55).color(0.32 * k), RGB(1, 0.85, 0.55).color(0)]),
                center: glowAt, startRadius: 0, endRadius: 46 * u))
            var spears = Path()
            for i in 0..<34 {
                let x = env.w * CGFloat(M.rand(i, 61)), y = hy + 12 * u + CGFloat(M.rand(i, 62)) * 26 * u
                let l = (8 + 8 * CGFloat(k)) * u * CGFloat(0.8 + 0.4 * sin(t * 4 + Double(i)))
                spears.move(to: CGPoint(x: x, y: y)); spears.addLine(to: CGPoint(x: x, y: y - l))
            }
            c.stroke(spears, with: .color(RGB(0.08, 0.05, 0.04).color(0.9 * k)), lineWidth: 0.8 * u)
        }
        Stage.hazeDust(c, env, y: hy + 28 * u)
    }

    // MARK: - Chapter 6: the crossing

    static func sailingBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u
        let k = M.smoothstep(0.55, 1, p)
        let sun = RGB.lerp(RGB(1, 0.95, 0.8), RGB(1, 0.6, 0.35), k)
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB.lerp(Backdrop.daySky.0, Backdrop.duskSky.0, k), skyBottom: RGB.lerp(Backdrop.daySky.1, Backdrop.duskSky.1, k),
            sun: (0.78 - 0.1 * CGFloat(p), 0.34 + 0.34 * CGFloat(k), sun, 9), ground: .sea(top: RGB.lerp(RGB(0.28, 0.5, 0.68), RGB(0.5, 0.34, 0.4), k), bottom: RGB(0.05, 0.12, 0.22))))
        // Dragonstone comes closer.
        let grow = CGFloat(M.smoothstep(0.55, 1, p))
        if grow > 0.02 {
            Landscape.dragonstone(c, base: CGPoint(x: env.w * 0.1, y: env.hy + 2 * u), u: u * (0.5 + 1.1 * grow), t: 0, rock: RGB(0.34, 0.3, 0.38))
        }
    }

    static func sailingForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, t = env.t, hy = env.hy
        Landscape.clouds(c, env.size, u: u, t: t, tint: RGB(1, 0.95, 0.9), opacity: 0.8)
        // Glints and waves move across the water.
        for i in 0..<10 {
            let b = pow(max(0, sin(t * 1.7 + Double(i) * 1.9)), 8)
            guard b > 0.02 else { continue }
            c.fill(Ink.sparkle(CGPoint(x: env.w * CGFloat(M.rand(i, 70)), y: hy + (4 + 28 * CGFloat(M.rand(i, 71))) * u), (1 + 1.4 * CGFloat(b)) * u), with: .color(.white.opacity(b)))
        }
        // Daenerys's fleet, 8 ships with horses on deck.
        for i in 0..<8 {
            let row = i % 3
            let x = env.w * (0.93 - 0.105 * CGFloat(i))
            let y = hy + (9 + CGFloat(row) * 8) * u
            Ships.draw(c, at: CGPoint(x: x, y: y), scale: (0.62 + 0.14 * CGFloat(row)) * u, t: t, seed: i, hull: RGB(0.28, 0.16, 0.1),
                       sail: RGB(0.62, 0.12, 0.1), flag: RGB(0.05, 0.05, 0.06), horses: true, dir: -1)
        }
        // Three dragons lead the way.
        let size = DragonKit.size(.sailing) * u
        for (i, d) in Dragon.allCases.enumerated() {
            let a = Double(i) * 1.8
            let pos = CGPoint(x: env.w * (0.46 - 0.12 * CGFloat(i)) + CGFloat(sin(t * 0.5 + a)) * 6 * u,
                              y: env.h * (0.22 + 0.1 * CGFloat(i % 2)) + CGFloat(sin(t * 1.8 + a)) * 3 * u)
            DragonKit.fly(c, at: pos, scale: size * (i == 0 ? 1.15 : 1), climb: 0.04, facing: -1, t: t, palette: .of(d), hz: 1.4, offset: a)
        }
    }

    // MARK: - Chapter 7: the Golden Road

    static func goldenBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, hy = env.hy
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB(0.3, 0.5, 0.78), skyBottom: RGB(0.98, 0.85, 0.6), sun: (0.18, 0.28, RGB(1, 0.92, 0.65), 8),
            ground: .land(far: RGB(0.72, 0.62, 0.32), near: RGB(0.5, 0.4, 0.2))))
        Stage.hills(c, env, color: RGB(0.55, 0.5, 0.28), y: hy - 2 * u, amp: 5 * u, freq: 2.2, phase: 0.2)
        Stage.hills(c, env, color: RGB(0.62, 0.52, 0.26), y: hy + 10 * u, amp: 4 * u, freq: 3, phase: 2)
        // The road.
        c.fill(Path { p in
            p.move(to: CGPoint(x: 0, y: hy + 24 * u)); p.addLine(to: CGPoint(x: env.w, y: hy + 22 * u))
            p.addLine(to: CGPoint(x: env.w, y: hy + 34 * u)); p.addLine(to: CGPoint(x: 0, y: hy + 38 * u)); p.closeSubpath()
        }, with: .color(RGB(0.5, 0.4, 0.28).color()))
    }

    static func goldenForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        if env.calm { goldenRoad(c, env); return }
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let roadY = hy + 30 * u
        let burn = M.smoothstep(0.25, 0.5, p)
        // Wagons and Lannister soldiers walking left.
        for i in 0..<4 {
            let x = env.w * (0.18 + 0.2 * CGFloat(i)) - CGFloat(M.fract(t * 0.01)) * 0
            let bounce = CGFloat(sin(t * 5 + Double(i))) * 0.4 * u
            c.fill(Path(roundedRect: CGRect(x: x - 11 * u, y: roadY - 14 * u + bounce, width: 22 * u, height: 9 * u), cornerRadius: 1.5 * u), with: .color(RGB(0.4, 0.25, 0.14).color()))
            c.fill(Path(CGRect(x: x - 9 * u, y: roadY - 19 * u + bounce, width: 18 * u, height: 5 * u)), with: .color(RGB(0.85, 0.7, 0.3).color()))
            for wx in [x - 7 * u, x + 7 * u] {
                c.fill(Ink.circle(CGPoint(x: wx, y: roadY - 4 * u), 4 * u), with: .color(RGB(0.2, 0.12, 0.08).color()))
                c.stroke(Ink.circle(CGPoint(x: wx, y: roadY - 4 * u), 4 * u), with: .color(.black.opacity(0.4)), lineWidth: 0.6 * u)
            }
            if burn > 0.05 {
                Fire.flames(c, x0: x - 11 * u, x1: x + 11 * u, y: roadY - 12 * u, height: 26 * u, intensity: burn * (0.6 + 0.4 * M.rand(i, 4)), t: t, seed: i + 30, u: u)
            }
        }
        Crowd.draw(c, env, kind: .soldiers, count: 28, xRange: 0...env.w, yFar: roadY - 4 * u, yNear: roadY + 7 * u, sFar: 0.8, sNear: 1,
                   speed: -10, far: RGB(0.55, 0.12, 0.1), near: RGB(0.42, 0.08, 0.08), seed: 71, standing: false)
        // The charge: Dothraki gallop from the right, left across the scene.
        Crowd.draw(c, env, kind: .riders, count: 26, xRange: -30...(env.w + 30), yFar: hy + 16 * u, yNear: hy + 40 * u, sFar: 0.75, sNear: 1.1,
                   speed: -(120 + 80 * CGFloat(M.smoothstep(0, 0.2, p))), far: RGB(0.3, 0.2, 0.14), near: RGB(0.12, 0.07, 0.05), seed: 72)
        // Drogon swoops and burns.
        let sw = M.easeInOut(M.smoothstep(0, 0.85, p))
        let pos = CGPoint(x: M.lerp(env.w * 1.05, env.w * 0.12, CGFloat(sw)), y: env.h * 0.28 + CGFloat(sin(.pi * sw)) * 12 * u + CGFloat(sin(t * 2)) * 2 * u)
        var hit = M.smoothstep(0.78, 0.84, p) * (1 - M.smoothstep(0.9, 1, p))
        hit = max(0, hit)
        DragonKit.fly(c, at: pos, scale: DragonKit.size(.goldenRoad) * u, climb: -0.12, facing: -1, t: t, palette: .drogon, hz: 1.6)
        let b = DragonKit.back(at: pos, scale: DragonKit.size(.goldenRoad) * u, climb: -0.12)
        Figure.draw(c, feet: b, h: DragonKit.riderHeight(DragonKit.size(.goldenRoad) * u), style: .dany(.white), facing: -1, t: t, arms: 0.3)
        if p < 0.78 && p > 0.05 {
            let m = DragonKit.mouth(at: pos, scale: DragonKit.size(.goldenRoad) * u, climb: -0.12)
            Fire.breath(c, from: m, angle: .pi * 0.62, length: 42 * u, t: t, u: u, intensity: 0.95)
        }
        // The scorpion bolt hits Drogon.
        if p > 0.74 && p < 0.86 {
            let k = (p - 0.74) / 0.1
            let from = CGPoint(x: env.w * 0.05, y: roadY - 14 * u)
            let to = pos
            let head = M.lerp(from, to, CGFloat(min(1, k)))
            let tail = M.lerp(from, to, CGFloat(max(0, k - 0.35)))
            c.stroke(Path { $0.move(to: tail); $0.addLine(to: head) }, with: .color(.white), lineWidth: 1.5 * u)
        }
        if hit > 0.01 { Stage.wash(c, env, RGB(1, 0.2, 0.1), 0.18 * hit) }
        Fire.smoke(c, x0: env.w * 0.1, x1: env.w * 0.8, y: roadY - 14 * u, rise: 60 * u, t: t, u: u, opacity: 0.4 * burn, wind: -10)
    }

    // MARK: - Chapter 8: beyond the Wall

    static func wallBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, hy = env.hy
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB(0.03, 0.06, 0.16), skyBottom: RGB(0.2, 0.3, 0.5), stars: 0.9,
            ground: .land(far: RGB(0.55, 0.66, 0.8), near: RGB(0.22, 0.3, 0.45))))
        Stage.mountains(c, env, color: RGB(0.2, 0.28, 0.42), base: hy + 2 * u, height: 46 * u, count: 6, seed: 3, snow: true)
        Stage.mountains(c, env, color: RGB(0.14, 0.2, 0.32), base: hy + 8 * u, height: 26 * u, count: 8, seed: 9, snow: true)
        // Frozen lake with cracks.
        var cracks = Path()
        for i in 0..<8 {
            let x = env.w * CGFloat(M.rand(i, 4))
            cracks.move(to: CGPoint(x: x, y: hy + 14 * u))
            cracks.addLine(to: CGPoint(x: x + CGFloat(M.rand(i, 5) - 0.5) * 60 * u, y: env.h))
        }
        c.stroke(cracks, with: .color(.white.opacity(0.12)), lineWidth: 0.7 * u)
    }

    static func wallForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        if env.calm { wallRoad(c, env); return }
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let gy = hy + 24 * u
        let arrive = M.smoothstep(0.28, 0.5, p)
        let fire = M.smoothstep(0.4, 0.5, p) * (1 - M.smoothstep(0.62, 0.7, p))
        // Wights across the ice.
        let wightX = M.lerp(0.55, 0.38, CGFloat(M.smoothstep(0, 0.4, p)))
        Crowd.draw(c, env, kind: .wights, count: Int(52 - 28 * M.smoothstep(0.45, 0.7, p)), xRange: (env.w * wightX)...(env.w * 1.05), yFar: hy + 14 * u, yNear: hy + 40 * u,
                   sFar: 0.6, sNear: 1.1, speed: -14, far: RGB(0.35, 0.48, 0.62), near: RGB(0.12, 0.18, 0.28), seed: 81)
        if fire > 0.02 {
            Fire.flames(c, x0: env.w * 0.5, x1: env.w * 0.95, y: gy + 8 * u, height: 36 * u, intensity: fire, t: t, seed: 18, u: u)
            Stage.wash(c, env, RGB(1, 0.5, 0.15), 0.1 * fire)
        }
        // Jon and his men on the rock.
        c.fill(Ink.ellipse(CGPoint(x: env.w * 0.2, y: gy + 4 * u), 34 * u, 7 * u), with: .color(RGB(0.2, 0.22, 0.3).color()))
        let party: [FigureStyle] = [.jon, .jorah, FigureStyle(cloth: RGB(0.35, 0.18, 0.12), cloth2: RGB(0.5, 0.3, 0.2), hair: RGB(0.7, 0.3, 0.1), hairKind: .long, prop: .torch), .wight, .jon]
        for (i, s) in party.enumerated() where i < 4 {
            let style = i == 3 ? FigureStyle(cloth: RGB(0.25, 0.22, 0.2), cloth2: RGB(0.4, 0.3, 0.2), hair: RGB(0.2, 0.15, 0.1), hairKind: .hood, prop: .sword) : s
            Figure.draw(c, feet: CGPoint(x: env.w * (0.12 + 0.045 * CGFloat(i)), y: gy + CGFloat(i % 2) * 2 * u), h: 30 * u, style: style, facing: -1, t: t + Double(i), arms: i == 0 ? 0.4 : 0)
        }
        // Three dragons come from the left, then one falls.
        let size = DragonKit.size(.beyondWall) * u
        let fall = M.smoothstep(0.78, 0.97, p)
        for (i, d) in Dragon.allCases.enumerated() {
            let a = Double(i) * 1.7
            let base = CGPoint(x: M.lerp(-30 * u, env.w * (0.34 + 0.12 * CGFloat(i)), CGFloat(arrive)) + CGFloat(sin(t * 0.9 + a)) * 6 * u,
                               y: env.h * (0.2 + 0.1 * CGFloat(i)) + CGFloat(sin(t * 2 + a)) * 3 * u)
            if d == .viserion && fall > 0 {
                var f = c
                f.opacity = 1 - Double(fall) * 0.6
                let pos = CGPoint(x: base.x + CGFloat(fall) * 20 * u, y: base.y + CGFloat(fall) * (gy - base.y + 4 * u))
                DragonKit.fly(f, at: pos, scale: size, climb: -Double(fall) * 1.1, facing: 1, t: t, palette: .viserion, hz: 0.6, offset: a)
                if fall > 0.9 { Stage.splash(c, env, at: CGPoint(x: pos.x, y: gy + 4 * u), strength: (1 - fall) * 10) }
            } else {
                DragonKit.fly(c, at: base, scale: size, climb: 0.02, facing: 1, t: t, palette: .of(d), hz: 1.5, offset: a)
                if fire > 0.02 {
                    let m = DragonKit.mouth(at: base, scale: size, climb: 0.02, facing: 1)
                    Fire.breath(c, from: m, angle: .pi * 0.32, length: 46 * u, t: t + a, u: u, intensity: fire)
                }
            }
        }
        // The Night King's spear.
        if p > 0.66 && p < 0.84 {
            let k = (p - 0.66) / 0.18
            let nk = CGPoint(x: env.w * 0.9, y: gy - 2 * u)
            Figure.draw(c, feet: nk, h: 34 * u, style: .nightKing, facing: -1, t: t, arms: 0.9)
            let target = CGPoint(x: env.w * 0.58, y: env.h * 0.34)
            let head = M.lerp(nk, target, CGFloat(min(1, k * 1.4)))
            var g = c
            g.blendMode = .plusLighter
            g.stroke(Path { $0.move(to: M.lerp(nk, head, 0.5)); $0.addLine(to: head) }, with: .color(RGB(0.6, 0.85, 1).color()), lineWidth: 1.6 * u)
            g.fill(Ink.circle(head, 5 * u), with: .radialGradient(Gradient(colors: [RGB(0.5, 0.8, 1).color(0.6), RGB(0.5, 0.8, 1).color(0)]), center: head, startRadius: 0, endRadius: 5 * u))
        } else if p >= 0.84 {
            Figure.draw(c, feet: CGPoint(x: env.w * 0.9, y: gy - 2 * u), h: 34 * u, style: .nightKing, facing: -1, t: t)
        }
        Stage.snow(c, env)
    }

    // MARK: - Chapter 9: Winterfell

    static func winterfellBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, hy = env.hy
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB(0.02, 0.03, 0.08), skyBottom: RGB(0.12, 0.14, 0.26), stars: 0.5,
            ground: .land(far: RGB(0.38, 0.44, 0.56), near: RGB(0.14, 0.16, 0.24))))
        Buildings.winterfell(c, env)
        Stage.hills(c, env, color: RGB(0.2, 0.24, 0.34), y: hy + 8 * u, amp: 3 * u, freq: 2.4, phase: 1)
    }

    static func winterfellForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        if env.calm { winterfellRoad(c, env); return }
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        // The dead army, a great dark tide.
        Crowd.draw(c, env, kind: .wights, count: 58, xRange: (env.w * 0.3)...(env.w * 1.1), yFar: hy + 8 * u, yNear: hy + 42 * u, sFar: 0.55, sNear: 1.1,
                   speed: -22, far: RGB(0.3, 0.4, 0.54), near: RGB(0.08, 0.11, 0.18), seed: 91)
        let size = DragonKit.size(.winterfell) * u
        // Drogon and Rhaegal burn the dead.
        for (i, d) in [Dragon.drogon, .rhaegal].enumerated() {
            let a = Double(i) * 2.2
            let pos = CGPoint(x: env.w * (0.5 + 0.2 * CGFloat(i)) + CGFloat(sin(t * 0.6 + a)) * 12 * u, y: env.h * (0.25 + 0.12 * CGFloat(i)) + CGFloat(sin(t * 2 + a)) * 3 * u)
            DragonKit.fly(c, at: pos, scale: size, climb: -0.1, facing: -1, t: t, palette: .of(d), hz: 1.5, offset: a)
            let m = DragonKit.mouth(at: pos, scale: size, climb: -0.1)
            Fire.breath(c, from: m, angle: .pi * 0.7, length: 50 * u, t: t + a, u: u, intensity: 0.9)
        }
        Fire.flames(c, x0: env.w * 0.3, x1: env.w * 0.7, y: hy + 36 * u, height: 22 * u, intensity: 0.8, t: t, seed: 33, u: u)
        // The Night King on undead Viserion. At the end the dragon turns to ash.
        let ash = M.smoothstep(0.78, 0.97, p)
        let vp = CGPoint(x: env.w * (0.3 + 0.1 * CGFloat(sin(t * 0.4))), y: env.h * 0.2 + CGFloat(sin(t * 1.8)) * 3 * u)
        var vc = c
        vc.opacity = 1 - Double(ash)
        DragonKit.fly(vc, at: vp, scale: size * 1.05, climb: 0.02, facing: 1, t: t, palette: .undead, hz: 1.3)
        Figure.draw(vc, feet: DragonKit.back(at: vp, scale: size * 1.05, climb: 0.02, facing: 1), h: DragonKit.riderHeight(size * 1.05), style: .nightKing, facing: 1, t: t)
        let m = DragonKit.mouth(at: vp, scale: size * 1.05, climb: 0.02, facing: 1)
        Fire.blueBreath(c, from: m, angle: .pi * 0.28, length: 48 * u, t: t, u: u, intensity: 1 - Double(ash))
        if ash > 0.02 {
            for i in 0..<40 {
                let age = M.fract(t * 0.3 + M.rand(i, 5))
                let q = CGPoint(x: vp.x + CGFloat(M.rand(i, 6) - 0.5) * 60 * u + CGFloat(age) * 12 * u, y: vp.y + CGFloat(M.rand(i, 7) - 0.5) * 20 * u + CGFloat(age) * 60 * u)
                c.fill(Ink.circle(q, (0.5 + M.rand(i, 8)) * u), with: .color(RGB(0.65, 0.75, 0.9).color(Double(ash) * (1 - age))))
            }
        }
        Stage.wash(c, env, RGB(0.3, 0.6, 1), 0.06)
        Stage.snow(c, env)
    }

    // MARK: - Chapter 10: Rhaegal

    static func rhaegalBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let k = M.smoothstep(0.2, 1, env.p)
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB.lerp(Backdrop.duskSky.0, Backdrop.nightSky.0, k), skyBottom: RGB.lerp(Backdrop.duskSky.1, RGB(0.25, 0.16, 0.3), k),
            sun: (0.2, 0.7 + 0.1 * CGFloat(k), RGB(1, 0.5, 0.3), 9), stars: k, ground: .sea(top: RGB.lerp(RGB(0.5, 0.3, 0.38), RGB(0.12, 0.14, 0.26), k), bottom: RGB(0.03, 0.05, 0.12))))
    }

    static func rhaegalForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        if env.calm { rhaegalRoad(c, env); return }
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        // The Iron Fleet closes in from the right.
        let ironSail = RGB(0.1, 0.1, 0.12)
        for i in 0..<5 {
            let x = env.w * (0.95 - 0.13 * CGFloat(i)) - CGFloat(p) * 30 * u
            Ships.draw(c, at: CGPoint(x: x, y: hy + (10 + CGFloat(i % 3) * 8) * u), scale: (0.7 + 0.12 * CGFloat(i % 3)) * u, t: t, seed: i + 5,
                       hull: RGB(0.09, 0.08, 0.09), sail: ironSail, flag: RGB(0.7, 0.55, 0.15), dir: -1)
        }
        // Bolts fly from the ships.
        let size = DragonKit.size(.rhaegal) * u
        let hitA = M.smoothstep(0.45, 0.55, p), fall = M.smoothstep(0.7, 0.95, p)
        let r0 = CGPoint(x: env.w * 0.52, y: env.h * 0.28 + CGFloat(sin(t * 2)) * 3 * u)
        let rpos = CGPoint(x: r0.x - CGFloat(fall) * 16 * u, y: M.lerp(r0.y, hy + 4 * u, CGFloat(fall)))
        if p > 0.4 && p < 0.7 {
            for i in 0..<4 {
                let k = M.fract(t * 1.2 + Double(i) * 0.27)
                let from = CGPoint(x: env.w * (0.66 + 0.06 * CGFloat(i)), y: hy + 6 * u)
                let head = M.lerp(from, rpos, CGFloat(k)), tail = M.lerp(from, rpos, CGFloat(max(0, k - 0.18)))
                c.stroke(Path { $0.move(to: tail); $0.addLine(to: head) }, with: .color(.white.opacity(0.9)), lineWidth: 1.1 * u)
            }
        }
        var rc = c
        rc.opacity = 1 - Double(fall) * 0.5
        DragonKit.fly(rc, at: rpos, scale: size, climb: -Double(fall) * 1.2 + 0.05, facing: -1, t: t, palette: .rhaegal, hz: 1.6 - Double(fall))
        if hitA > 0.01 && fall < 0.5 { Stage.wash(c, env, RGB(1, 0.3, 0.1), 0.12 * hitA * (1 - fall * 2)) }
        if fall > 0.85 { Stage.splash(c, env, at: CGPoint(x: rpos.x, y: hy + 6 * u), strength: (1 - fall) * 12) }
        // Drogon and Daenerys fly on, alone.
        let dpos = CGPoint(x: env.w * 0.28 + CGFloat(p) * 20 * u, y: env.h * 0.2 + CGFloat(sin(t * 1.8)) * 3 * u)
        DragonKit.fly(c, at: dpos, scale: size * 1.15, climb: 0.03, facing: -1, t: t, palette: .drogon, hz: 1.4)
        Figure.draw(c, feet: DragonKit.back(at: dpos, scale: size * 1.15, climb: 0.03), h: DragonKit.riderHeight(size * 1.15), style: .dany(.black), facing: -1, t: t, arms: 0.25)
    }

    // MARK: - Chapter 11: King's Landing

    static func landingBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, hy = env.hy
        let k = env.calm ? 0 : M.smoothstep(0.1, 0.8, p)
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB.lerp(RGB(0.28, 0.14, 0.34), Backdrop.fireSky.0, k), skyBottom: RGB.lerp(RGB(1, 0.58, 0.32), Backdrop.fireSky.1, k),
            sun: nil, ground: .sea(top: RGB.lerp(RGB(0.4, 0.26, 0.34), RGB(0.5, 0.2, 0.1), k), bottom: RGB(0.06, 0.04, 0.08))))
        Landscape.kingsLanding(c, base: CGPoint(x: env.w * 0.68, y: hy + 9 * u), u: 1.0 * u, t: 0, lit: 1 - k, land: RGB(0.34, 0.24, 0.2), extent: 240)
    }

    static func landingForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        if env.calm { landingRoad(c, env); return }
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let burn = M.smoothstep(0.2, 0.85, p)
        // The Iron Fleet burns.
        for i in 0..<4 {
            let x = env.w * (0.12 + 0.13 * CGFloat(i))
            Ships.draw(c, at: CGPoint(x: x, y: hy + (12 + CGFloat(i % 2) * 8) * u), scale: 0.8 * u, t: t, seed: i + 11, hull: RGB(0.09, 0.08, 0.09), sail: RGB(0.1, 0.1, 0.12),
                       dir: 1, burning: M.smoothstep(0.1 + 0.08 * Double(i), 0.35 + 0.08 * Double(i), p))
        }
        // The city catches fire.
        Fire.flames(c, x0: env.w * 0.5, x1: env.w * 0.99, y: hy + 4 * u, height: (20 + 40 * CGFloat(burn)) * u, intensity: burn * 1.2, t: t, seed: 44, u: u)
        Fire.flames(c, x0: env.w * 0.64, x1: env.w * 0.84, y: hy - 12 * u, height: 40 * u * CGFloat(burn), intensity: M.smoothstep(0.45, 0.85, p), t: t + 2, seed: 45, u: u)
        Fire.smoke(c, x0: env.w * 0.5, x1: env.w * 0.98, y: hy - 14 * u, rise: 90 * u, t: t, u: u, opacity: 0.5 * burn, seed: 3, wind: 18)
        Fire.embers(c, env, x0: env.w * 0.5, x1: env.w * 0.98, y: hy - 4 * u, count: 36, rise: 100 * u)
        // Drogon makes passes over the city.
        let size = DragonKit.size(.kingsLanding) * u * 1.25
        let pass = M.fract(p * 5)
        let pos = CGPoint(x: M.lerp(env.w * 1.0, env.w * 0.38, CGFloat(M.easeInOut(pass))), y: env.h * 0.24 + CGFloat(sin(pass * .pi)) * 14 * u)
        DragonKit.fly(c, at: pos, scale: size, climb: -0.14, facing: -1, t: t, palette: .drogon, hz: 1.5)
        Figure.draw(c, feet: DragonKit.back(at: pos, scale: size, climb: -0.14), h: DragonKit.riderHeight(size), style: .dany(.black), facing: -1, t: t, arms: 0.3)
        let m = DragonKit.mouth(at: pos, scale: size, climb: -0.14)
        Fire.breath(c, from: m, angle: .pi * 0.55, length: 56 * u, t: t, u: u, intensity: 1)
        Stage.wash(c, env, RGB(1, 0.35, 0.08), 0.1 + 0.12 * burn)
        Stage.ash(c, env)
    }

    // MARK: - Chapter 12: epilogue

    static func epilogueBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, hy = env.hy
        // Smoky sky, seen through the broken wall.
        c.fill(Path(CGRect(origin: .zero, size: env.size)), with: .linearGradient(
            Gradient(colors: [RGB(0.22, 0.16, 0.18).color(), RGB(0.62, 0.32, 0.18).color()]), startPoint: .zero, endPoint: CGPoint(x: 0, y: env.h * 0.65)))
        // Back wall with a jagged hole where the great window was.
        let center = CGPoint(x: env.w * 0.5, y: env.h * 0.28), r = 34 * u
        var wall = Path()
        wall.addRect(CGRect(x: -2, y: -2, width: env.w + 4, height: env.h + 4))
        var hole = Path()
        for k in 0..<22 {
            let a = Double(k) / 22 * 2 * .pi
            let rr = r * CGFloat(0.78 + 0.38 * M.rand(k, 200))
            let p = CGPoint(x: center.x + CGFloat(cos(a)) * rr * 1.25, y: center.y + CGFloat(sin(a)) * rr)
            if k == 0 { hole.move(to: p) } else { hole.addLine(to: p) }
        }
        hole.closeSubpath()
        wall.addPath(hole)
        c.fill(wall, with: .linearGradient(Gradient(colors: [RGB(0.24, 0.18, 0.17).color(), RGB(0.12, 0.08, 0.08).color()]),
                                           startPoint: .zero, endPoint: CGPoint(x: 0, y: env.h)), style: FillStyle(eoFill: true))
        // Stone courses on the wall.
        var courses = Path()
        var y: CGFloat = 5 * u
        while y < hy + 14 * u { courses.move(to: CGPoint(x: 0, y: y)); courses.addLine(to: CGPoint(x: env.w, y: y)); y += 6 * u }
        var walled = c
        walled.clip(to: wall, style: FillStyle(eoFill: true))
        walled.stroke(courses, with: .color(.black.opacity(0.18)), lineWidth: 0.6 * u)
        // What is left of the window tracery.
        var tracery = Path()
        for k in 0..<7 {
            let a = Double(k) / 7 * 2 * .pi + 0.3
            let len = r * CGFloat(0.35 + 0.5 * M.rand(k, 201))
            tracery.move(to: CGPoint(x: center.x + CGFloat(cos(a)) * r * 1.2, y: center.y + CGFloat(sin(a)) * r * 0.95))
            tracery.addLine(to: CGPoint(x: center.x + CGFloat(cos(a)) * (r * 1.2 - len), y: center.y + CGFloat(sin(a)) * (r * 0.95 - len * 0.8)))
        }
        c.stroke(tracery, with: .color(RGB(0.16, 0.11, 0.11).color()), style: StrokeStyle(lineWidth: 2 * u, lineCap: .round))
        // A shaft of smoky light from the hole onto the floor.
        var g = c
        g.blendMode = .plusLighter
        g.fill(Path { p in
            p.move(to: CGPoint(x: center.x - r, y: center.y)); p.addLine(to: CGPoint(x: center.x + r, y: center.y))
            p.addLine(to: CGPoint(x: center.x + r * 1.8, y: hy + 20 * u)); p.addLine(to: CGPoint(x: center.x - r * 1.4, y: hy + 20 * u)); p.closeSubpath()
        }, with: .linearGradient(Gradient(colors: [RGB(1, 0.7, 0.45).color(0.16), RGB(1, 0.7, 0.45).color(0)]), startPoint: center, endPoint: CGPoint(x: center.x, y: hy + 20 * u)))
        // Columns, two of them broken.
        for i in 0..<6 {
            let x = env.w * (0.02 + 0.19 * CGFloat(i)), cw = 11 * u
            let broken = i == 1 || i == 4
            let top = broken ? (20 + 18 * CGFloat(M.rand(i, 202))) * u : 0
            var col = Path()
            col.move(to: CGPoint(x: x, y: hy + 16 * u))
            col.addLine(to: CGPoint(x: x, y: top + (broken ? 4 * u : 0)))
            if broken {
                col.addLine(to: CGPoint(x: x + cw * 0.3, y: top)); col.addLine(to: CGPoint(x: x + cw * 0.55, y: top + 5 * u)); col.addLine(to: CGPoint(x: x + cw * 0.8, y: top + 1 * u))
            }
            col.addLine(to: CGPoint(x: x + cw, y: top + (broken ? 3 * u : 0)))
            col.addLine(to: CGPoint(x: x + cw, y: hy + 16 * u))
            col.closeSubpath()
            c.fill(col, with: .linearGradient(Gradient(colors: [RGB(0.36, 0.28, 0.26).color(), RGB(0.2, 0.15, 0.14).color(), RGB(0.1, 0.07, 0.07).color()]),
                                              startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + cw, y: 0)))
            var flutes = Path()
            for f in 1..<4 { flutes.move(to: CGPoint(x: x + cw * CGFloat(f) / 4, y: top + 6 * u)); flutes.addLine(to: CGPoint(x: x + cw * CGFloat(f) / 4, y: hy + 14 * u)) }
            c.stroke(flutes, with: .color(.black.opacity(0.22)), lineWidth: 0.5 * u)
            c.fill(Path(CGRect(x: x - 2 * u, y: hy + 13 * u, width: cw + 4 * u, height: 3 * u)), with: .color(RGB(0.3, 0.23, 0.21).color()))
        }
        // Floor with fallen stones.
        c.fill(Path(CGRect(x: 0, y: hy + 16 * u, width: env.w, height: env.h)), with: .linearGradient(
            Gradient(colors: [RGB(0.22, 0.15, 0.13).color(), RGB(0.08, 0.05, 0.05).color()]), startPoint: CGPoint(x: 0, y: hy + 16 * u), endPoint: CGPoint(x: 0, y: env.h)))
        Stage.rocks(c, env, y0: hy + 20 * u, y1: env.h - 2 * u, color: RGB(0.3, 0.23, 0.21), count: 9, seed: 12)
    }

    /// The Iron Throne: steps, a seat, and a high back of a thousand blades. `melt` 0...1 turns it to glowing slag.
    static func ironThrone(_ c: GraphicsContext, at base: CGPoint, u: CGFloat, melt: Double, t: Double) {
        let iron = RGB(0.34, 0.35, 0.40), hot = RGB(1, 0.55, 0.12)
        // Steps.
        for k in 0..<3 {
            let w = (64 - CGFloat(k) * 14) * u, y = base.y - CGFloat(k + 1) * 4 * u
            c.fill(Path(CGRect(x: base.x - w / 2, y: y, width: w, height: 4 * u)), with: .linearGradient(
                Gradient(colors: [RGB(0.34, 0.26, 0.24).color(), RGB(0.16, 0.11, 0.1).color()]), startPoint: CGPoint(x: 0, y: y), endPoint: CGPoint(x: 0, y: y + 4 * u)))
            c.fill(Path(CGRect(x: base.x - w / 2, y: y, width: w, height: 0.8 * u)), with: .color(RGB(0.6, 0.45, 0.38).color(0.4)))
        }
        let seatTop = base.y - 12 * u - 12 * u
        // The back: blades fanning up behind the seat.
        for i in 0..<34 {
            let f = Double(i) / 33
            let a = (f - 0.5) * 2.1 + (M.rand(i, 210) - 0.5) * 0.12
            let shrink = 1 - 0.85 * melt * (0.5 + 0.5 * M.rand(i, 211))
            let len = (26 + 24 * CGFloat(M.rand(i, 212)) * CGFloat(1 - abs(f - 0.5))) * u * CGFloat(shrink)
            let root = CGPoint(x: base.x + CGFloat(f - 0.5) * 16 * u, y: seatTop + 4 * u)
            let tip = CGPoint(x: root.x + CGFloat(sin(a)) * len, y: root.y - CGFloat(cos(a)) * len)
            let col = RGB.lerp(RGB.lerp(iron, RGB(0.55, 0.57, 0.62), M.rand(i, 213)), hot, melt * (0.5 + 0.5 * M.rand(i, 214)))
            c.fill(Ink.tapered([root, tip], 2 * u, 0.3 * u), with: .color(col.color()))
            // Cross-guard near the root.
            let gx = root.x + CGFloat(sin(a)) * 4 * u, gy = root.y - CGFloat(cos(a)) * 4 * u
            c.stroke(Path { $0.move(to: CGPoint(x: gx - CGFloat(cos(a)) * 2 * u, y: gy - CGFloat(sin(a)) * 2 * u)); $0.addLine(to: CGPoint(x: gx + CGFloat(cos(a)) * 2 * u, y: gy + CGFloat(sin(a)) * 2 * u)) },
                     with: .color(shadeColor(col, 0.7)), lineWidth: 0.8 * u)
        }
        // Seat and arms.
        let seat = CGRect(x: base.x - 10 * u, y: seatTop, width: 20 * u, height: 12 * u)
        c.fill(Path(roundedRect: seat, cornerRadius: 1.5 * u), with: .linearGradient(
            Gradient(colors: [RGB.lerp(iron, hot, melt).color(), RGB.lerp(RGB(0.16, 0.16, 0.2), RGB(0.8, 0.3, 0.05), melt).color()]),
            startPoint: CGPoint(x: seat.minX, y: 0), endPoint: CGPoint(x: seat.maxX, y: 0)))
        for side in [CGFloat(-1), 1] {
            for k in 0..<3 {
                let root = CGPoint(x: base.x + side * 10 * u, y: seatTop + (3 + CGFloat(k) * 2.5) * u)
                let tip = CGPoint(x: root.x + side * (7 + 2 * CGFloat(k)) * u * CGFloat(1 - 0.7 * melt), y: root.y - 1.5 * u)
                c.fill(Ink.tapered([root, tip], 1.6 * u, 0.3 * u), with: .color(RGB.lerp(iron, hot, melt).color()))
            }
        }
        if melt > 0.02 {
            var g = c
            g.blendMode = .plusLighter
            let heart = CGPoint(x: base.x, y: seatTop)
            g.fill(Ink.circle(heart, 44 * u), with: .radialGradient(
                Gradient(colors: [hot.color(0.45 * melt), hot.color(0)]), center: heart, startRadius: 0, endRadius: 44 * u))
            // Molten iron spreading over the steps.
            c.fill(Ink.ellipse(CGPoint(x: base.x, y: base.y - 1 * u), CGFloat(10 + 26 * melt) * u, CGFloat(1.5 + 2 * melt) * u),
                   with: .color(RGB(1, 0.5 + 0.2 * sin(t * 3), 0.1).color(0.85 * melt)))
            for i in 0..<6 {
                let age = M.fract(t * 0.5 + M.rand(i, 215))
                c.fill(Ink.ellipse(CGPoint(x: base.x + CGFloat(i - 3) * 6 * u, y: seatTop + 12 * u + CGFloat(age) * 12 * u), 0.9 * u, 1.8 * u),
                       with: .color(hot.color(melt * (1 - age))))
            }
        }
    }

    private static func shadeColor(_ c: RGB, _ k: Double) -> Color { RGB(c.r * k, c.g * k, c.b * k).color() }

    static func epilogueForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let gy = hy + 22 * u
        let cx = env.w * 0.5
        let melt = env.calm ? 0 : M.smoothstep(0.35, 0.78, p)
        ironThrone(c, at: CGPoint(x: cx, y: gy), u: u, melt: melt, t: t)
        // Jon stands to the side with his head down.
        Figure.draw(c, feet: CGPoint(x: env.w * 0.2, y: gy + 2 * u), h: 38 * u, style: .jon, facing: 1, t: t)
        // Drogon enters, burns the throne and leaves with Daenerys.
        let enter = M.smoothstep(0, 0.3, p), leave = env.calm ? 0 : M.smoothstep(0.8, 1, p)
        if !env.calm && leave < 0.02 {
            var body = c
            body.translateBy(x: cx - 34 * u, y: gy - 1 * u)
            body.rotate(by: .degrees(-90))
            Figure.draw(body, feet: .zero, h: 26 * u, style: .dany(.black), facing: 1, t: 0)
        }
        let size = DragonKit.size(.epilogue) * u * 1.4
        let facing: CGFloat = leave > 0.02 ? 1 : -1
        let dpos = CGPoint(x: M.lerp(env.w * 1.12, env.w * 0.74, CGFloat(enter)) + CGFloat(leave) * env.w * 0.5,
                           y: env.h * 0.36 - CGFloat(leave) * 30 * u + CGFloat(sin(t * 1.6)) * 3 * u)
        DragonKit.fly(c, at: dpos, scale: size, climb: 0.12 * Double(leave), facing: facing, t: t, palette: .drogon, hz: 1.3)
        if leave > 0.02 {
            DragonKit.carry(c, at: dpos, scale: size, climb: 0.12 * Double(leave), facing: facing, t: t)
        }
        if !env.calm && p > 0.3 && p < 0.78 {
            let m = DragonKit.mouth(at: dpos, scale: size, climb: 0, facing: -1)
            let target = CGPoint(x: cx, y: gy - 30 * u)
            Fire.breath(c, from: m, angle: atan2(Double(target.y - m.y), Double(target.x - m.x)), length: hypot(target.x - m.x, target.y - m.y),
                        t: t, u: u, intensity: M.smoothstep(0.3, 0.38, p))
        }
        Fire.smoke(c, x0: cx - 20 * u, x1: cx + 20 * u, y: gy - 30 * u, rise: 70 * u, t: t, u: u, opacity: 0.4 * melt)
        Stage.ash(c, env)
        Stage.vignette(c, env, strength: 0.5)
    }
}

extension Stage {
    static func snow(_ c: GraphicsContext, _ env: SceneEnv) {
        for i in 0..<30 {
            let age = M.fract(env.t * (0.1 + 0.08 * M.rand(i, 100)) + M.rand(i, 101))
            let x = env.w * CGFloat(M.fract(M.rand(i, 102) - age * 0.25)) + CGFloat(sin(env.t + Double(i))) * 3 * env.u
            c.fill(Ink.circle(CGPoint(x: x, y: CGFloat(age) * env.h), (0.5 + CGFloat(M.rand(i, 103))) * env.u), with: .color(.white.opacity(0.7)))
        }
    }

    static func ash(_ c: GraphicsContext, _ env: SceneEnv) {
        for i in 0..<26 {
            let age = M.fract(env.t * (0.08 + 0.06 * M.rand(i, 104)) + M.rand(i, 105))
            let x = env.w * CGFloat(M.rand(i, 106)) + CGFloat(sin(env.t * 0.8 + Double(i))) * 6 * env.u
            c.fill(Ink.circle(CGPoint(x: x, y: CGFloat(age) * env.h), (0.5 + 0.8 * CGFloat(M.rand(i, 107))) * env.u), with: .color(RGB(0.75, 0.7, 0.7).color(0.55)))
        }
    }

    static func splash(_ c: GraphicsContext, _ env: SceneEnv, at p: CGPoint, strength: Double) {
        guard strength > 0.02 else { return }
        for i in 0..<14 {
            let a = Double(i) / 13 * .pi + .pi
            let d = CGFloat(strength) * 4 * env.u * CGFloat(0.5 + M.rand(i, 108))
            c.fill(Ink.circle(CGPoint(x: p.x + CGFloat(cos(a)) * d * 1.6, y: p.y + CGFloat(sin(a)) * d * 1.6), 1.2 * env.u), with: .color(.white.opacity(min(1, strength / 6))))
        }
        c.stroke(Ink.ellipse(p, CGFloat(strength) * 4 * env.u, CGFloat(strength) * 1.2 * env.u), with: .color(.white.opacity(0.5)), lineWidth: env.u)
    }
}
