import SwiftUI
import StudyNookCore

/// Calm road versions of the chapters: while the timer runs, the army marches, ships sail and dragons fly.
/// The action (fire, battles, falling dragons) plays during the rest instead.
extension JourneyLate {
    // MARK: - Chapter 4: the horde rides to Vaes Dothrak

    static func vaesRoad(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        let gy = hy + 24 * u
        // The sacred city grows on the horizon.
        let k = CGFloat(0.55 + 0.45 * M.smoothstep(0, 1, p))
        Buildings.dothrakiHall(c, cx: env.w * 0.8, base: hy + 4 * u, k: k, u: u, glow: 0.4, t: t)
        // The horde rides right, toward the city.
        Crowd.draw(c, env, kind: .riders, count: 26, xRange: -30...(env.w + 30), yFar: hy + 12 * u, yNear: hy + 40 * u, sFar: 0.6, sNear: 1.1,
                   speed: 60, far: RGB(0.40, 0.24, 0.2), near: RGB(0.14, 0.08, 0.07), seed: 61)
        let frame = Int(t * 6) & 3
        let dany = CGPoint(x: env.w * 0.45, y: hy + 36 * u)
        let hs = 1.25 * u
        c.fill(Stamps.horse[frame].applying(CGAffineTransform(translationX: dany.x, y: dany.y).scaledBy(x: hs, y: hs)), with: .color(RGB(0.9, 0.9, 0.94).color()))
        Figure.draw(c, feet: CGPoint(x: dany.x + u, y: dany.y - 12.5 * hs), h: 20 * u, style: .dany(.blue), facing: 1, t: t, arms: 0.1)
        // The three dragons fly above.
        let size = DragonKit.size(.vaesDothrak) * u
        for (i, d) in Dragon.allCases.enumerated() {
            let a = Double(i) * 2.0
            DragonKit.fly(c, at: CGPoint(x: env.w * (0.3 + 0.17 * CGFloat(i)) + CGFloat(sin(t * 0.5 + a)) * 6 * u, y: env.h * (0.2 + 0.1 * CGFloat(i % 2)) + CGFloat(sin(t * 2 + a)) * 3 * u),
                          scale: size, climb: 0.04, facing: 1, t: t, palette: .of(d), hz: 1.6, offset: a)
        }
        Stage.hazeDust(c, env, y: gy + 8 * u)
        Fire.embers(c, env, x0: env.w * 0.74, x1: env.w * 0.86, y: hy, count: 6, rise: 30 * u)
    }

    // MARK: - Chapter 7: the Golden Road

    static func goldenRoad(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        // Dothraki ride along the road in a long column, Daenerys on Drogon overhead.
        Crowd.draw(c, env, kind: .riders, count: 34, xRange: -30...(env.w + 30), yFar: hy + 22 * u, yNear: hy + 42 * u, sFar: 0.8, sNear: 1.1,
                   speed: 90, far: RGB(0.34, 0.22, 0.14), near: RGB(0.14, 0.08, 0.06), seed: 72)
        let size = DragonKit.size(.goldenRoad) * u
        for (i, d) in Dragon.allCases.enumerated() {
            let a = Double(i) * 1.9
            let pos = CGPoint(x: env.w * (0.28 + 0.2 * CGFloat(i)) + CGFloat(sin(t * 0.4 + a)) * 8 * u + CGFloat(p) * 20 * u,
                              y: env.h * (0.2 + 0.09 * CGFloat(i % 2)) + CGFloat(sin(t * 2 + a)) * 3 * u)
            DragonKit.fly(c, at: pos, scale: size * (i == 0 ? 1.15 : 1), climb: 0.03, facing: 1, t: t, palette: .of(d), hz: 1.5, offset: a)
            if i == 0 {
                Figure.draw(c, feet: DragonKit.back(at: pos, scale: size * 1.15, climb: 0.03, facing: 1), h: DragonKit.riderHeight(size * 1.15), style: .dany(.white), facing: 1, t: t, arms: 0.25)
            }
        }
        Stage.hazeDust(c, env, y: hy + 36 * u)
    }

    // MARK: - Chapter 8: flying north

    static func wallRoad(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t
        let size = DragonKit.size(.beyondWall) * u
        for (i, d) in Dragon.allCases.enumerated() {
            let a = Double(i) * 1.7
            let pos = CGPoint(x: env.w * (0.22 + 0.2 * CGFloat(i)) + CGFloat(sin(t * 0.4 + a)) * 8 * u + CGFloat(p) * 30 * u,
                              y: env.h * (0.2 + 0.1 * CGFloat(i)) + CGFloat(sin(t * 2 + a)) * 3 * u)
            DragonKit.fly(c, at: pos, scale: size * (i == 0 ? 1.15 : 1), climb: 0.03, facing: 1, t: t, palette: .of(d), hz: 1.4, offset: a)
            if i == 0 {
                Figure.draw(c, feet: DragonKit.back(at: pos, scale: size * 1.15, climb: 0.03, facing: 1), h: DragonKit.riderHeight(size * 1.15), style: .dany(.black), facing: 1, t: t, arms: 0.2)
            }
        }
        Stage.snow(c, env)
    }

    // MARK: - Chapter 9: to Winterfell

    static func winterfellRoad(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        // The army camps below the walls: Dothraki and Unsullied by their fires.
        Crowd.draw(c, env, kind: .soldiers, count: 26, xRange: (env.w * 0.45)...env.w, yFar: hy + 14 * u, yNear: hy + 40 * u, sFar: 0.7, sNear: 1.05,
                   speed: -12, far: RGB(0.2, 0.22, 0.3), near: RGB(0.08, 0.09, 0.14), seed: 91)
        for i in 0..<3 {
            Fire.torch(c, at: CGPoint(x: env.w * (0.55 + 0.17 * CGFloat(i)), y: hy + 34 * u), size: 3.4 * u, t: t, seed: i + 5)
        }
        let size = DragonKit.size(.winterfell) * u
        for (i, d) in [Dragon.drogon, .rhaegal].enumerated() {
            let a = Double(i) * 2.2
            let pos = CGPoint(x: env.w * (0.3 + 0.25 * CGFloat(i)) + CGFloat(p) * 30 * u + CGFloat(sin(t * 0.5 + a)) * 8 * u, y: env.h * (0.22 + 0.1 * CGFloat(i)) + CGFloat(sin(t * 2 + a)) * 3 * u)
            DragonKit.fly(c, at: pos, scale: size, climb: 0.02, facing: -1, t: t, palette: .of(d), hz: 1.4, offset: a)
            if i == 0 {
                Figure.draw(c, feet: DragonKit.back(at: pos, scale: size, climb: 0.02), h: DragonKit.riderHeight(size), style: .dany(.black), facing: -1, t: t, arms: 0.2)
            }
        }
        Stage.snow(c, env)
    }

    // MARK: - Chapter 10: the fleet sails south

    static func rhaegalRoad(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        for i in 0..<6 {
            let row = i % 3
            Ships.draw(c, at: CGPoint(x: env.w * (0.9 - 0.12 * CGFloat(i)), y: hy + (9 + CGFloat(row) * 8) * u), scale: (0.62 + 0.14 * CGFloat(row)) * u, t: t, seed: i + 20,
                       hull: RGB(0.28, 0.16, 0.1), sail: RGB(0.62, 0.12, 0.1), flag: RGB(0.05, 0.05, 0.06), horses: true, dir: -1)
        }
        let size = DragonKit.size(.rhaegal) * u
        for (i, d) in [Dragon.drogon, .rhaegal].enumerated() {
            let a = Double(i) * 2.0
            let pos = CGPoint(x: env.w * (0.28 + 0.2 * CGFloat(i)) + CGFloat(p) * 20 * u + CGFloat(sin(t * 0.5 + a)) * 6 * u, y: env.h * (0.2 + 0.1 * CGFloat(i)) + CGFloat(sin(t * 2 + a)) * 3 * u)
            DragonKit.fly(c, at: pos, scale: size * (i == 0 ? 1.15 : 1), climb: 0.03, facing: -1, t: t, palette: .of(d), hz: 1.4, offset: a)
            if i == 0 {
                Figure.draw(c, feet: DragonKit.back(at: pos, scale: size * 1.15, climb: 0.03), h: DragonKit.riderHeight(size * 1.15), style: .dany(.black), facing: -1, t: t, arms: 0.25)
            }
        }
    }

    // MARK: - Chapter 11: Drogon flies to King's Landing

    static func landingRoad(_ c: GraphicsContext, _ env: SceneEnv) {
        let p = env.p, u = env.u, t = env.t, hy = env.hy
        // The Iron Fleet rides at anchor, untouched.
        for i in 0..<4 {
            Ships.draw(c, at: CGPoint(x: env.w * (0.12 + 0.13 * CGFloat(i)), y: hy + (12 + CGFloat(i % 2) * 8) * u), scale: 0.8 * u, t: t, seed: i + 11,
                       hull: RGB(0.09, 0.08, 0.09), sail: RGB(0.1, 0.1, 0.12), dir: 1)
        }
        // Drogon and Daenerys approach the city.
        let size = DragonKit.size(.kingsLanding) * u * 1.25
        let x = M.lerp(env.w * 1.04, env.w * 0.52, CGFloat(M.easeInOut(p)))
        let pos = CGPoint(x: x, y: env.h * 0.26 + CGFloat(sin(t * 1.7)) * 3 * u)
        DragonKit.fly(c, at: pos, scale: size, climb: 0.02, facing: -1, t: t, palette: .drogon, hz: 1.3)
        Figure.draw(c, feet: DragonKit.back(at: pos, scale: size, climb: 0.02), h: DragonKit.riderHeight(size), style: .dany(.black), facing: -1, t: t, arms: 0.2)
        Landscape.clouds(c, env.size, u: u, t: t, tint: RGB(1, 0.8, 0.7), opacity: 0.6)
    }
}

extension JourneyEarly {
    /// Dusk on the steppe for the ride to Vaes Dothrak.
    static func vaesRoadBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, hy = env.hy
        let k = M.smoothstep(0, 1, env.p)
        Stage.paintBackdrop(c, env, Backdrop(skyTop: RGB.lerp(RGB(0.3, 0.4, 0.7), RGB(0.12, 0.08, 0.25), k), skyBottom: RGB.lerp(RGB(1, 0.8, 0.55), RGB(1, 0.5, 0.3), k),
            sun: (0.65, 0.42 + 0.22 * CGFloat(k), RGB(1, 0.8, 0.5), 10), stars: k * 0.5, ground: .land(far: RGB(0.55, 0.45, 0.28), near: RGB(0.3, 0.24, 0.16))))
        Stage.hills(c, env, color: RGB(0.4, 0.32, 0.2), y: hy + 2 * u, amp: 3 * u, freq: 2, phase: 0.8, haze: RGB(1, 0.8, 0.6), hazeAmount: 0.4, tufts: true)
    }
}

// MARK: - The burning of King's Landing (final rest): only the city, no sea, no ships

extension JourneyLate {
    static func landingBurnBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, hy = env.hy
        Stage.paintBackdrop(c, env, Backdrop(skyTop: Backdrop.fireSky.0, skyBottom: Backdrop.fireSky.1, sun: nil,
            ground: .land(far: RGB(0.3, 0.14, 0.1), near: RGB(0.12, 0.06, 0.05))))
        // Smoke-dark hills behind the city.
        Stage.hills(c, env, color: RGB(0.2, 0.09, 0.08), y: hy - 6 * u, amp: 5 * u, freq: 2.4, phase: 0.6, haze: RGB(0.9, 0.35, 0.12), hazeAmount: 0.5)
        // The whole city, centred on the Red Keep, spreading to both edges.
        Landscape.kingsLanding(c, base: CGPoint(x: env.w * 0.5 - 6 * u, y: hy + 4 * u), u: 1.0 * u, t: 0, lit: 0, land: RGB(0.36, 0.22, 0.18), extent: 340, shoreline: false)
    }

    static func landingBurnForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, t = env.t, hy = env.hy
        // The fire never stops and rises over the first minutes.
        let rise = M.smoothstep(0, 0.35, env.p)
        let burn = 0.55 + 0.6 * rise
        // Separate blazes on the slopes, so the city stays visible between them.
        for k in 0..<9 {
            let cx = env.w * (0.04 + 0.115 * CGFloat(k)) + CGFloat(M.rand(k, 12) - 0.5) * 14 * u
            let y = hy + (26 - CGFloat(k * 5 % 3) * 13) * u
            Fire.flames(c, x0: cx - 15 * u, x1: cx + 15 * u, y: y, height: (12 + 12 * CGFloat(M.rand(k, 3))) * u * CGFloat(0.6 + 0.4 * rise),
                        intensity: burn * (0.65 + 0.35 * M.rand(k, 4)), t: t + Double(k) * 0.7, seed: 40 + k, u: u)
        }
        // The Red Keep burns from its towers.
        Fire.flames(c, x0: env.w * 0.45, x1: env.w * 0.56, y: hy - 14 * u, height: (26 + 10 * rise) * u, intensity: burn, t: t + 0.7, seed: 51, u: u)
        Fire.smoke(c, x0: 0, x1: env.w, y: hy - 10 * u, rise: 80 * u, t: t, u: u, opacity: 0.5, seed: 3, wind: 20)
        Fire.smoke(c, x0: env.w * 0.1, x1: env.w * 0.9, y: hy - 22 * u, rise: 70 * u, t: t + 3, u: u, opacity: 0.45, seed: 8, wind: 14)
        Fire.embers(c, env, x0: 0, x1: env.w, y: hy + 10 * u, count: 40, rise: 110 * u)
        // Drogon makes slow passes over the city and burns it.
        let size = DragonKit.size(.kingsLanding) * u * 1.25
        let pass = M.fract(t / 18)
        let x = M.lerp(env.w * 1.06, env.w * -0.06, CGFloat(M.easeInOut(pass)))
        let pos = CGPoint(x: x, y: env.h * 0.22 + CGFloat(sin(pass * .pi)) * 10 * u + CGFloat(sin(t * 1.7)) * 2 * u)
        DragonKit.fly(c, at: pos, scale: size, climb: -0.12, facing: -1, t: t, palette: .drogon, hz: 1.5)
        Figure.draw(c, feet: DragonKit.back(at: pos, scale: size, climb: -0.12), h: DragonKit.riderHeight(size), style: .dany(.black), facing: -1, t: t, arms: 0.3)
        let m = DragonKit.mouth(at: pos, scale: size, climb: -0.12)
        Fire.breath(c, from: m, angle: .pi * 0.58, length: 60 * u, t: t, u: u, intensity: 1)
        Stage.wash(c, env, RGB(1, 0.3, 0.06), 0.1 + 0.06 * sin(t * 6))
        Stage.ash(c, env)
        Stage.vignette(c, env, strength: 0.45)
    }
}

// MARK: - The House of the Undying (rest after chapter 2)

extension JourneyEarly {
    static func undyingBackground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, w = env.w, h = env.h
        let vanish = CGPoint(x: w * 0.5, y: h * 0.46)
        // Walls and floor converge on a glowing round door.
        c.fill(Path(CGRect(origin: .zero, size: env.size)), with: .linearGradient(
            Gradient(colors: [RGB(0.04, 0.06, 0.12).color(), RGB(0.08, 0.14, 0.2).color()]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        var floor = Path()
        floor.move(to: CGPoint(x: 0, y: h)); floor.addLine(to: CGPoint(x: vanish.x - 40 * u, y: vanish.y + 12 * u))
        floor.addLine(to: CGPoint(x: vanish.x + 40 * u, y: vanish.y + 12 * u)); floor.addLine(to: CGPoint(x: w, y: h)); floor.closeSubpath()
        c.fill(floor, with: .linearGradient(Gradient(colors: [RGB(0.1, 0.16, 0.22).color(), RGB(0.16, 0.22, 0.28).color()]), startPoint: CGPoint(x: 0, y: vanish.y), endPoint: CGPoint(x: 0, y: h)))
        // Floor tiles in perspective.
        var tiles = Path()
        for i in 0...10 {
            let f = CGFloat(i) / 10
            tiles.move(to: CGPoint(x: vanish.x - 40 * u + f * 80 * u, y: vanish.y + 12 * u)); tiles.addLine(to: CGPoint(x: f * w, y: h))
        }
        for k in 1..<6 {
            let f = pow(CGFloat(k) / 6, 1.6)
            let y = vanish.y + 12 * u + (h - vanish.y - 12 * u) * f
            tiles.move(to: CGPoint(x: (vanish.x - 40 * u) * (1 - f), y: y)); tiles.addLine(to: CGPoint(x: (vanish.x + 40 * u) + (w - vanish.x - 40 * u) * f, y: y))
        }
        c.stroke(tiles, with: .color(RGB(0.4, 0.7, 0.9).color(0.12)), lineWidth: 0.6 * u)
        // Receding arches on both sides.
        for k in 0..<5 {
            let f = CGFloat(k) / 5
            let depth = 1 - f * 0.78
            for side in [CGFloat(-1), 1] {
                let x = vanish.x + side * (w * 0.5 * depth - 10 * u)
                let pw = 12 * u * depth, top = vanish.y - 52 * u * depth, bottom = vanish.y + 12 * u + (h - vanish.y - 12 * u) * (1 - pow(f, 0.6) * 0.0) * depth
                let col = RGB.lerp(RGB(0.2, 0.28, 0.36), RGB(0.08, 0.12, 0.18), Double(f))
                c.fill(Path(CGRect(x: x - pw / 2, y: top, width: pw, height: bottom - top)), with: .linearGradient(
                    Gradient(colors: [col.color(), RGB(col.r * 0.5, col.g * 0.5, col.b * 0.55).color()]), startPoint: CGPoint(x: x - side * pw / 2, y: 0), endPoint: CGPoint(x: x + side * pw / 2, y: 0)))
                var arch = Path()
                arch.move(to: CGPoint(x: x, y: top))
                arch.addQuadCurve(to: CGPoint(x: x - side * 22 * u * depth, y: top), control: CGPoint(x: x - side * 11 * u * depth, y: top - 14 * u * depth))
                c.stroke(arch, with: .color(col.color()), lineWidth: 3 * u * depth)
                // A candle at the foot of each pillar.
                let cpt = CGPoint(x: x + side * -pw * 0.9, y: bottom - 2 * u * depth)
                c.fill(Path(CGRect(x: cpt.x - 0.7 * u * depth, y: cpt.y - 4 * u * depth, width: 1.4 * u * depth, height: 4 * u * depth)), with: .color(RGB(0.9, 0.88, 0.8).color()))
            }
        }
        // The door of blue light.
        let door = CGPoint(x: vanish.x, y: vanish.y - 6 * u)
        c.fill(Ink.ellipse(door, 16 * u, 20 * u), with: .radialGradient(
            Gradient(colors: [RGB(0.7, 0.9, 1).color(), RGB(0.25, 0.5, 0.85).color(0.7), RGB(0.1, 0.2, 0.4).color(0)]), center: door, startRadius: 0, endRadius: 22 * u))
        c.stroke(Ink.ellipse(door, 17 * u, 21 * u), with: .color(RGB(0.3, 0.45, 0.6).color()), lineWidth: 2 * u)
    }

    static func undyingForeground(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, t = env.t, w = env.w, h = env.h
        let q = M.clamp01((env.p - 0.8) / 0.2)
        let gy = h * 0.86
        let chained = M.smoothstep(0.2, 0.35, q)
        let dracarys = M.smoothstep(0.58, 0.64, q)
        let free = M.smoothstep(0.66, 0.75, q)

        // Candle flames.
        let vanish = CGPoint(x: w * 0.5, y: h * 0.46)
        for k in 0..<5 {
            let depth = 1 - CGFloat(k) / 5 * 0.78
            for side in [CGFloat(-1), 1] {
                let x = vanish.x + side * (w * 0.5 * depth - 10 * u) + side * -12 * u * depth * 0.9
                let bottom = vanish.y + 12 * u + (h - vanish.y - 12 * u) * depth
                Fire.torch(c, at: CGPoint(x: x, y: bottom - 6 * u * depth), size: 1.6 * u * depth, t: t, seed: k)
            }
        }

        // The dragons on a stone pedestal, chained until "Dracarys".
        let ped = CGPoint(x: w * 0.56, y: gy - 6 * u)
        c.fill(Path(roundedRect: CGRect(x: ped.x - 16 * u, y: ped.y, width: 32 * u, height: 8 * u), cornerRadius: 1.5 * u), with: .linearGradient(
            Gradient(colors: [RGB(0.34, 0.4, 0.48).color(), RGB(0.14, 0.18, 0.24).color()]), startPoint: CGPoint(x: 0, y: ped.y), endPoint: CGPoint(x: 0, y: ped.y + 8 * u)))
        for (i, d) in Dragon.allCases.enumerated() {
            let base = CGPoint(x: ped.x - 9 * u + CGFloat(i) * 9 * u, y: ped.y)
            if free > 0.5 && d == .drogon {
                continue // Drogon is in the air, breathing fire.
            }
            DragonKit.sitting(c, base: base, scale: 0.17 * u, t: t + Double(i), palette: .of(d), facing: -1)
            if free < 0.9 {
                var chain = Path()
                chain.move(to: CGPoint(x: base.x - 2 * u, y: base.y - 3 * u)); chain.addLine(to: CGPoint(x: base.x - 2 * u, y: ped.y + 8 * u))
                c.stroke(chain, with: .color(RGB(0.6, 0.62, 0.66).color(1 - free)), style: StrokeStyle(lineWidth: 0.7 * u, dash: [1 * u, 0.6 * u]))
            }
        }

        // Daenerys walks in, then chains snap shut on her wrists.
        let walkIn = M.smoothstep(0, 0.2, q)
        let dany = CGPoint(x: M.lerp(w * 0.12, w * 0.32, CGFloat(walkIn)), y: gy)
        Figure.draw(c, feet: dany, h: 36 * u, style: .dany(.blue), facing: 1, t: t, walk: walkIn < 0.98 ? 1 : 0, arms: chained > 0.1 ? 0.55 : 0.15)
        if chained > 0.01 && free < 0.95 {
            var chains = Path()
            for side in [CGFloat(-1), 1] {
                chains.move(to: CGPoint(x: dany.x + 2.5 * u, y: dany.y - 22 * u)); chains.addLine(to: CGPoint(x: dany.x + side * 40 * u + 10 * u, y: dany.y - 60 * u))
            }
            c.stroke(chains, with: .color(RGB(0.62, 0.64, 0.7).color(chained * (1 - free))), style: StrokeStyle(lineWidth: 0.9 * u, dash: [1.4 * u, 0.7 * u]))
        }

        // Pyat Pree and his illusions.
        let pyat = CGPoint(x: w * 0.8, y: gy)
        let warlock = FigureStyle(skin: RGB(0.62, 0.72, 0.82), cloth: RGB(0.36, 0.22, 0.56), cloth2: RGB(0.7, 0.6, 0.88), hair: RGB(0.2, 0.2, 0.25), hairKind: .hood)
        let illusions = 1 - dracarys
        for (i, dx) in [CGFloat(-60), -36, 18].enumerated() where illusions > 0.02 {
            var ghost = c
            ghost.opacity = 0.35 * illusions * (0.7 + 0.3 * sin(t * 2 + Double(i)))
            Figure.draw(ghost, feet: CGPoint(x: pyat.x + dx * u, y: gy - CGFloat(i % 2) * 3 * u), h: 34 * u, style: warlock, facing: -1, t: t, arms: 0.4)
        }
        Figure.draw(c, feet: pyat, h: 36 * u, style: warlock, facing: -1, t: t, arms: 0.45)

        // Dracarys.
        if free > 0.01 {
            let dpos = CGPoint(x: ped.x - 4 * u, y: gy - 46 * u + CGFloat(sin(t * 2.4)) * 2 * u)
            DragonKit.fly(c, at: dpos, scale: 0.22 * u, climb: -0.1, facing: 1, t: t, palette: .drogon, hz: 2.6)
            let m = DragonKit.mouth(at: dpos, scale: 0.22 * u, climb: -0.1, facing: 1)
            let target = CGPoint(x: pyat.x, y: pyat.y - 18 * u)
            Fire.breath(c, from: m, angle: atan2(Double(target.y - m.y), Double(target.x - m.x)), length: hypot(target.x - m.x, target.y - m.y), t: t, u: u, intensity: free)
            Fire.flames(c, x0: pyat.x - 8 * u, x1: pyat.x + 8 * u, y: pyat.y, height: 40 * u * CGFloat(free), intensity: free, t: t, seed: 4, u: u)
            Stage.wash(c, env, RGB(1, 0.5, 0.2), 0.14 * free)
        }
        if dracarys > 0.01 && q < 0.82 {
            let k = min(1, (q - 0.58) / 0.06)
            var tc = c
            tc.opacity = min(1, k * 2) * (1 - M.smoothstep(0.76, 0.82, q))
            tc.translateBy(x: w * 0.5, y: h * 0.2)
            let s = CGFloat(M.easeOutBack(M.clamp01(k)))
            tc.scaleBy(x: s, y: s)
            tc.addFilter(.shadow(color: Theme.focus.opacity(0.9), radius: 6 * u))
            tc.draw(Text("Дракарис!").font(.system(size: 18 * u, weight: .heavy, design: .rounded)).foregroundStyle(Color.white), at: .zero, anchor: .center)
        }
        Stage.wash(c, env, RGB(0.3, 0.5, 1), 0.07 * (1 - free))
        Stage.vignette(c, env, strength: 0.5)
        let d = abs(env.p - 0.8), half = 0.75 / env.total
        if d < half { Stage.wash(c, env, RGB(0, 0, 0), 1 - d / half) }
    }
}
