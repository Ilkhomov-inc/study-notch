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
        let cx = env.w * 0.8
        var hall = Path()
        hall.move(to: CGPoint(x: cx - 36 * u * k, y: hy + 3 * u))
        hall.addLine(to: CGPoint(x: cx - 36 * u * k, y: hy - 20 * u * k))
        hall.addLine(to: CGPoint(x: cx, y: hy - 46 * u * k))
        hall.addLine(to: CGPoint(x: cx + 36 * u * k, y: hy - 20 * u * k))
        hall.addLine(to: CGPoint(x: cx + 36 * u * k, y: hy + 3 * u))
        hall.closeSubpath()
        c.fill(hall, with: .linearGradient(Gradient(colors: [RGB(0.25, 0.14, 0.1).color(), RGB(0.12, 0.07, 0.06).color()]), startPoint: CGPoint(x: cx, y: hy - 46 * u * k), endPoint: CGPoint(x: cx, y: hy)))
        for i in 0..<5 {
            let x = cx - 28 * u * k + CGFloat(i) * 14 * u * k
            c.fill(Path(CGRect(x: x, y: hy - 16 * u * k, width: 2 * u * k, height: 19 * u * k)), with: .color(RGB(0.08, 0.05, 0.04).color()))
        }
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
                Figure.draw(c, feet: DragonKit.back(at: pos, scale: size * 1.15, climb: 0.03, facing: 1), h: 20 * u, style: .dany(.white), facing: 1, t: t, arms: 0.25)
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
                Figure.draw(c, feet: DragonKit.back(at: pos, scale: size * 1.15, climb: 0.03, facing: 1), h: 20 * u, style: .dany(.black), facing: 1, t: t, arms: 0.2)
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
                Figure.draw(c, feet: DragonKit.back(at: pos, scale: size, climb: 0.02), h: 20 * u, style: .dany(.black), facing: -1, t: t, arms: 0.2)
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
                Figure.draw(c, feet: DragonKit.back(at: pos, scale: size * 1.15, climb: 0.03), h: 20 * u, style: .dany(.black), facing: -1, t: t, arms: 0.25)
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
        Figure.draw(c, feet: DragonKit.back(at: pos, scale: size, climb: 0.02), h: 20 * u, style: .dany(.black), facing: -1, t: t, arms: 0.2)
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
