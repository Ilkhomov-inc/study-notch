import SwiftUI
import StudyNookCore

/// The road during the timer: the party really travels from one place to the next, left to right,
/// with a dotted route ahead, a glowing trail behind and a pulsing mark on the destination.
/// No battles here: everything dramatic plays during the rest.
enum Travel {
    enum Ground { case steppe, desert, sea, snow, ash }
    enum Landmark { case pentos, lhazar, qarth, astapor, dothrakiSea, vaesDothrak, meereen, dragonstone, goldenRoad, eastwatch, beyondWall, whiteHarbor, winterfell, kingsLanding, ruins }
    enum Army { case none, riders(Int), caravan(Int), soldiers(Int), fleet(Int) }

    struct Plan {
        var from: String, to: String
        var origin: Landmark, dest: Landmark
        var ground: Ground
        var skyStart: (RGB, RGB), skyEnd: (RGB, RGB)
        var sun = true, night = false
        var army: Army = .none
        /// Daenerys rides a horse at the head of the army (early chapters).
        var heroHorse: DanyOutfit?
        var drogo = false, eggs = false
        /// Dragons fly along the route; the first one carries Daenerys if `rider` is set.
        var dragons: [Dragon] = []
        var rider: DanyOutfit?
        var jonOnRhaegal = false
        /// Tiny dragons fly around Daenerys instead of along the route (chapter 2).
        var babies = false
        var jonWalks = false
    }

    // MARK: - Chapters

    static func plan(_ ch: Chapter) -> Plan {
        switch ch {
        case .birth:
            return Plan(from: "Пентос", to: "Лхазар", origin: .pentos, dest: .lhazar, ground: .steppe,
                        skyStart: Backdrop.dawnSky, skyEnd: Backdrop.duskSky, army: .riders(16), heroHorse: .dothraki, drogo: true, eggs: true)
        case .qarth:
            return Plan(from: "Лхазар", to: "Кварт", origin: .lhazar, dest: .qarth, ground: .desert,
                        skyStart: (RGB(0.3, 0.45, 0.75), RGB(0.98, 0.84, 0.62)), skyEnd: Backdrop.duskSky, army: .caravan(8), heroHorse: .dothraki,
                        dragons: [.drogon, .rhaegal, .viserion], babies: true)
        case .astapor:
            return Plan(from: "Кварт", to: "Астапор", origin: .qarth, dest: .astapor, ground: .sea,
                        skyStart: Backdrop.daySky, skyEnd: Backdrop.duskSky, army: .fleet(3), dragons: [.drogon, .rhaegal, .viserion])
        case .vaesDothrak:
            return Plan(from: "Дотракийское море", to: "Ваэс Дотрак", origin: .dothrakiSea, dest: .vaesDothrak, ground: .steppe,
                        skyStart: Backdrop.daySky, skyEnd: Backdrop.duskSky, army: .riders(20), heroHorse: .blue)
        case .meereen:
            return Plan(from: "Ваэс Дотрак", to: "Миэрин", origin: .vaesDothrak, dest: .meereen, ground: .steppe,
                        skyStart: Backdrop.dawnSky, skyEnd: Backdrop.daySky, army: .riders(26), dragons: [.drogon], rider: .white)
        case .sailing:
            return Plan(from: "Миэрин", to: "Драконий Камень", origin: .meereen, dest: .dragonstone, ground: .sea,
                        skyStart: Backdrop.daySky, skyEnd: Backdrop.duskSky, army: .fleet(7), dragons: [.drogon, .rhaegal, .viserion], rider: .white)
        case .goldenRoad:
            return Plan(from: "Драконий Камень", to: "Золотая дорога", origin: .dragonstone, dest: .goldenRoad, ground: .steppe,
                        skyStart: Backdrop.daySky, skyEnd: (RGB(0.3, 0.45, 0.75), RGB(0.98, 0.85, 0.6)), army: .riders(24), dragons: [.drogon], rider: .white)
        case .beyondWall:
            return Plan(from: "Восточный Дозор", to: "За Стеной", origin: .eastwatch, dest: .beyondWall, ground: .snow,
                        skyStart: (RGB(0.2, 0.28, 0.45), RGB(0.6, 0.66, 0.78)), skyEnd: Backdrop.nightSky, sun: false, night: true,
                        dragons: [.drogon, .rhaegal, .viserion], rider: .black)
        case .winterfell:
            return Plan(from: "Белая Гавань", to: "Винтерфелл", origin: .whiteHarbor, dest: .winterfell, ground: .snow,
                        skyStart: (RGB(0.3, 0.36, 0.5), RGB(0.7, 0.72, 0.8)), skyEnd: (RGB(0.12, 0.14, 0.26), RGB(0.42, 0.42, 0.55)), sun: false,
                        army: .soldiers(22), dragons: [.drogon, .rhaegal], rider: .black, jonOnRhaegal: true)
        case .rhaegal:
            return Plan(from: "Винтерфелл", to: "Драконий Камень", origin: .whiteHarbor, dest: .dragonstone, ground: .sea,
                        skyStart: Backdrop.daySky, skyEnd: Backdrop.duskSky, army: .fleet(6), dragons: [.drogon, .rhaegal], rider: .black)
        case .kingsLanding:
            return Plan(from: "Драконий Камень", to: "Королевская Гавань", origin: .dragonstone, dest: .kingsLanding, ground: .sea,
                        skyStart: Backdrop.dawnSky, skyEnd: Backdrop.duskSky, dragons: [.drogon], rider: .black)
        case .epilogue:
            return Plan(from: "Ворота", to: "Тронный зал", origin: .ruins, dest: .ruins, ground: .ash,
                        skyStart: (RGB(0.25, 0.2, 0.22), RGB(0.6, 0.45, 0.4)), skyEnd: (RGB(0.2, 0.17, 0.2), RGB(0.55, 0.38, 0.32)), sun: false,
                        army: .soldiers(14), dragons: [.drogon], jonWalks: true)
        }
    }

    // MARK: - Geometry

    struct Layout {
        let env: SceneEnv
        let originX: CGFloat, destX: CGFloat
        let air: QuadCurve, road: QuadCurve
        init(_ env: SceneEnv, _ plan: Plan) {
            self.env = env
            let u = env.u, hy = env.hy, w = env.w
            originX = w * 0.08
            destX = w * 0.9
            air = QuadCurve(p0: CGPoint(x: originX + 18 * u, y: hy - 30 * u), c: CGPoint(x: w * 0.5, y: hy - 52 * u), p1: CGPoint(x: destX - 12 * u, y: hy - 30 * u))
            let roadY: CGFloat = plan.ground == .sea ? hy + 12 * u : hy + 26 * u
            road = QuadCurve(p0: CGPoint(x: originX + 18 * u, y: roadY + 2 * u), c: CGPoint(x: w * 0.5, y: roadY + 8 * u), p1: CGPoint(x: destX - 22 * u, y: roadY - 2 * u))
        }
    }

    static func sky(_ plan: Plan, _ p: Double) -> (RGB, RGB) {
        (RGB.lerp(plan.skyStart.0, plan.skyEnd.0, p), RGB.lerp(plan.skyStart.1, plan.skyEnd.1, p))
    }

    // MARK: - Background (slow layer)

    static func background(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
        let plan = plan(ch)
        let L = Layout(env, plan)
        let u = env.u, hy = env.hy, p = env.p
        let (top, bottom) = sky(plan, p)
        let sunColor = RGB.lerp(RGB(1, 0.92, 0.75), RGB(1, 0.6, 0.32), abs(p - 0.5) * 2)
        let ground: GroundKind
        switch plan.ground {
        case .steppe: ground = .land(far: RGB(0.52, 0.55, 0.32), near: RGB(0.3, 0.34, 0.18))
        case .desert: ground = .land(far: RGB(0.88, 0.64, 0.42), near: RGB(0.62, 0.38, 0.24))
        case .sea: ground = .sea(top: RGB.lerp(RGB(0.3, 0.5, 0.68), RGB(0.5, 0.34, 0.4), p), bottom: RGB(0.05, 0.12, 0.22))
        case .snow: ground = .land(far: RGB(0.75, 0.8, 0.9), near: RGB(0.45, 0.52, 0.65))
        case .ash: ground = .land(far: RGB(0.3, 0.26, 0.26), near: RGB(0.14, 0.11, 0.11))
        }
        Stage.paintBackdrop(c, env, Backdrop(
            skyTop: top, skyBottom: bottom,
            sun: plan.sun ? (0.7 - 0.4 * CGFloat(p), 0.3 + 0.32 * CGFloat(p), sunColor, 8) : nil,
            moon: plan.night ? CGPoint(x: 0.24, y: 0.24) : nil,
            stars: plan.night ? M.smoothstep(0.3, 1, p) : 0, ground: ground))

        // Terrain between the two places.
        switch plan.ground {
        case .steppe:
            Stage.hills(c, env, color: RGB(0.46, 0.5, 0.3), y: hy - 1 * u, amp: 4 * u, freq: 2.2, phase: 0.4, scroll: CGFloat(p) * env.w * 0.6, haze: bottom, hazeAmount: 0.45)
            Stage.hills(c, env, color: RGB(0.38, 0.44, 0.24), y: hy + 12 * u, amp: 3 * u, freq: 3, phase: 1.6, scroll: CGFloat(p) * env.w * 1.2, tufts: true)
        case .desert:
            Stage.hills(c, env, color: RGB(0.82, 0.56, 0.36), y: hy - 1 * u, amp: 5 * u, freq: 2.4, phase: 1, scroll: CGFloat(p) * env.w * 0.6, haze: bottom, hazeAmount: 0.4)
            Stage.hills(c, env, color: RGB(0.72, 0.46, 0.3), y: hy + 13 * u, amp: 4 * u, freq: 3.2, phase: 2.2, scroll: CGFloat(p) * env.w * 1.2)
            Stage.rocks(c, env, y0: hy + 16 * u, y1: env.h - 3 * u, color: RGB(0.6, 0.4, 0.28), count: 6, seed: 4)
        case .snow:
            Stage.mountains(c, env, color: RGB(0.28, 0.34, 0.5), base: hy + 2 * u, height: 40 * u, count: 6, seed: 3, snow: true)
            Stage.hills(c, env, color: RGB(0.7, 0.76, 0.88), y: hy + 12 * u, amp: 3 * u, freq: 2.5, phase: 0.5, scroll: CGFloat(p) * env.w * 1.2)
        case .ash:
            Stage.hills(c, env, color: RGB(0.24, 0.2, 0.2), y: hy + 4 * u, amp: 3 * u, freq: 2, phase: 0.6, haze: bottom, hazeAmount: 0.4)
            Stage.rocks(c, env, y0: hy + 14 * u, y1: env.h - 2 * u, color: RGB(0.3, 0.25, 0.24), count: 10, seed: 9)
        case .sea:
            break
        }

        landmark(c, env, plan.origin, x: L.originX, side: -1)
        landmark(c, env, plan.dest, x: L.destX, side: 1)
    }

    // MARK: - Foreground (fast layer): water, route, the moving party

    static func foreground(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
        let plan = plan(ch)
        let L = Layout(env, plan)
        let u = env.u, t = env.t, hy = env.hy
        let p = env.p
        let tp = CGFloat(M.clamp01(p))

        if plan.ground == .sea {
            let sunX = env.w * (0.7 - 0.4 * CGFloat(p))
            Landscape.sea(c, env.size, horizon: hy, u: u, t: t, top: RGB.lerp(RGB(0.3, 0.5, 0.68), RGB(0.5, 0.34, 0.4), p), bottom: RGB(0.05, 0.12, 0.22),
                          glint: plan.sun ? RGB(1, 0.8, 0.55) : nil, glintX: sunX)
            // Islands and coasts are drawn again on top of the animated water.
            landmark(c, env, plan.origin, x: L.originX, side: -1, waterOnly: true)
            landmark(c, env, plan.dest, x: L.destX, side: 1, waterOnly: true)
        }
        if !plan.night { Landscape.clouds(c, env.size, u: u, t: t, tint: RGB(1, 0.94, 0.88), opacity: 0.55) }

        passingBy(c, env, ground: plan.ground)

        // The route: dots ahead, a glow behind, a pulse on the destination.
        let route = plan.dragons.isEmpty || plan.babies ? L.road : L.air
        c.stroke(route.path(from: tp, to: 1), with: .color(.white.opacity(0.6)),
                 style: StrokeStyle(lineWidth: 1.3 * u, lineCap: .round, dash: [0.1, 4.6 * u]))
        var glow = c
        glow.addFilter(.blur(radius: 1.5 * u))
        glow.stroke(route.path(from: 0, to: tp), with: .color(Theme.focus.opacity(0.5)), lineWidth: 1.6 * u)
        let pulse = M.fract(t * 0.6)
        c.stroke(Ink.circle(route.p1, (2 + 6 * CGFloat(pulse)) * u), with: .color(Theme.focus.opacity(0.75 * (1 - pulse))), lineWidth: 1.1 * u)
        c.fill(Ink.circle(route.p1, 1.6 * u), with: .color(Theme.focus))

        // The party on the ground or the sea.
        let lead = L.road.point(tp)
        switch plan.army {
        case .none: break
        case let .riders(n): column(c, env, lead: lead, count: n, kind: .riders, t: t)
        case let .caravan(n): column(c, env, lead: lead, count: n, kind: .caravan, t: t)
        case let .soldiers(n): column(c, env, lead: lead, count: n, kind: .soldiers, t: t)
        case let .fleet(n):
            for i in (0..<n).reversed() {
                let row = i % 3
                let pos = CGPoint(x: lead.x - CGFloat(i) * 26 * u - CGFloat(row) * 6 * u, y: lead.y + CGFloat(row - 1) * 6 * u)
                Ships.draw(c, at: pos, scale: (0.62 + 0.1 * CGFloat(row)) * u, t: t, seed: i, hull: RGB(0.3, 0.17, 0.1), sail: RGB(0.64, 0.12, 0.1),
                           flag: RGB(0.05, 0.05, 0.06), horses: i % 2 == 0, dir: 1)
            }
        }
        if plan.jonWalks {
            Figure.draw(c, feet: CGPoint(x: lead.x + 10 * u, y: lead.y), h: 30 * u, style: .jon, facing: 1, t: t, walk: 1)
        }
        if let outfit = plan.heroHorse {
            if plan.drogo {
                Horse.ridden(c, at: CGPoint(x: lead.x + 22 * u, y: lead.y - 1 * u), scale: 1.25 * u, coat: .black, rider: .drogo, phase: t * 7, t: t, arms: 0.25)
            }
            Horse.ridden(c, at: lead, scale: 1.25 * u, coat: .silver, rider: .dany(outfit), phase: t * 7 + 1.3, saddle: RGB(0.45, 0.18, 0.2), t: t)
            if plan.eggs {
                DragonKit.eggs(c, at: CGPoint(x: lead.x - 9 * u, y: lead.y - 14 * u), u: 0.5 * u, t: t, glow: 0.5)
            }
            dust(c, env, behind: lead)
        }

        // Dragons.
        // Travelling dragons are drawn a bit larger than in the battle scenes, so their detail shows.
        let size = DragonKit.size(ch) * u * (plan.babies ? 1 : 1.18)
        if plan.babies {
            for (i, d) in plan.dragons.enumerated() {
                let a = Double(i) * 2.1
                let pos = CGPoint(x: lead.x + CGFloat(i - 1) * 22 * u + CGFloat(sin(t * 0.9 + a)) * 5 * u,
                                  y: lead.y - 40 * u - CGFloat(i % 2) * 8 * u + CGFloat(sin(t * 2.6 + a)) * 3 * u)
                DragonKit.fly(c, at: pos, scale: size, climb: 0.05, facing: 1, t: t, palette: .of(d), hz: 2.4, offset: a)
            }
        } else {
            for (i, d) in plan.dragons.enumerated().reversed() {
                let a = Double(i) * 1.9
                // Spread out in a loose echelon, so no dragon hides another.
                let back = CGFloat(i) * 0.2
                let q = max(0, tp - back)
                var pos = L.air.point(q)
                pos.x -= CGFloat(i) * 22 * u
                pos.y += CGFloat(i % 2 == 0 ? -0.6 : 1) * CGFloat(i) * 17 * u + CGFloat(sin(t * 2 * .pi * 0.8 + a)) * 2 * u
                let d1 = L.air.derivative(q)
                // Every few seconds a dragon stops beating its wings and glides, banking gently.
                let cycle = M.fract(t / 11 + Double(i) * 0.37)
                let glide = M.smoothstep(0.5, 0.6, cycle) * (1 - M.smoothstep(0.88, 0.98, cycle))
                let bank = sin(t * 0.45 + a) * 0.12 - glide * 0.08
                let climb = max(-0.4, min(0.4, Double(atan2(-d1.y, d1.x)) * 0.6 + bank))
                let s = size * (i == 0 ? 1.12 : 1)
                trail(c, env, along: L.air, at: q, u: u, t: t, seed: i)
                DragonKit.fly(c, at: pos, scale: s, climb: climb, facing: 1, t: t, palette: .of(d), hz: 1.6, offset: a, glide: glide)
                if i == 0, let outfit = plan.rider {
                    Figure.draw(c, feet: DragonKit.back(at: pos, scale: s, climb: climb, facing: 1), h: DragonKit.riderHeight(s), style: .dany(outfit), facing: 1, t: t, arms: 0.2)
                }
                if d == .rhaegal && plan.jonOnRhaegal {
                    Figure.draw(c, feet: DragonKit.back(at: pos, scale: s, climb: climb, facing: 1), h: DragonKit.riderHeight(s), style: .jon, facing: 1, t: t, arms: 0.1)
                }
            }
        }

        switch plan.ground {
        case .snow: Stage.snow(c, env)
        case .ash: Stage.ash(c, env)
        default: break
        }

        // Where we come from and where we are going, on plates above everything.
        tag(c, plan.from, at: CGPoint(x: 8 * u, y: env.h - 9 * u), u: u, alignRight: false)
        tag(c, "→ " + plan.to, at: CGPoint(x: env.w - 8 * u, y: env.h - 9 * u), u: u, alignRight: true)
    }

    private static func tag(_ c: GraphicsContext, _ text: String, at p: CGPoint, u: CGFloat, alignRight: Bool) {
        let resolved = c.resolve(Text(text).font(.system(size: 8.5 * u, weight: .semibold, design: .rounded)).foregroundStyle(Color.white))
        let size = resolved.measure(in: CGSize(width: 400, height: 40))
        let w = size.width + 10 * u, h = size.height + 4 * u
        let rect = CGRect(x: alignRight ? p.x - w : p.x, y: p.y - h / 2, width: w, height: h)
        c.fill(Path(roundedRect: rect, cornerRadius: h / 2), with: .color(.black.opacity(0.45)))
        c.draw(resolved, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }

    // MARK: - Pieces

    private enum ColumnKind { case riders, caravan, soldiers }

    /// An army marching behind its leader: far ranks are cheap silhouettes, the nearest are drawn in full.
    private static func column(_ c: GraphicsContext, _ env: SceneEnv, lead: CGPoint, count: Int, kind: ColumnKind, t: Double) {
        let u = env.u
        struct Member { var x: CGFloat; var y: CGFloat; var z: Double; var i: Int }
        var members: [Member] = []
        for i in 0..<count {
            let z = M.rand(i, 300)
            let spacing: CGFloat = kind == .soldiers ? 9 : 13
            let x = lead.x - (14 + CGFloat(i) * spacing * 0.75 + CGFloat(M.rand(i, 301)) * 6) * u
            let y = lead.y + CGFloat(z - 0.5) * 16 * u
            members.append(Member(x: x, y: y, z: z, i: i))
        }
        members.sort { $0.y < $1.y }
        for m in members {
            let s = (0.8 + 0.35 * CGFloat(m.z)) * u
            let phase = t * 7 + Double(m.i) * 0.9
            let near = m.z > 0.62 && m.i < 10
            switch kind {
            case .riders, .caravan:
                if near {
                    Horse.ridden(c, at: CGPoint(x: m.x, y: m.y), scale: s, coat: .random(m.i), rider: .dothrakiRider, phase: phase, saddle: RGB(0.4, 0.25, 0.15), t: t + Double(m.i), arms: 0.2)
                } else {
                    let frame = Int(phase / (2 * .pi) * 4) & 3
                    let col = RGB.lerp(RGB(0.42, 0.28, 0.2), RGB(0.18, 0.1, 0.07), m.z)
                    c.fill(Stamps.rider[frame].applying(CGAffineTransform(translationX: m.x, y: m.y).scaledBy(x: s, y: s)), with: .color(col.color()))
                }
            case .soldiers:
                if near {
                    Figure.draw(c, feet: CGPoint(x: m.x, y: m.y), h: 22 * s / u * u, style: .unsullied, facing: 1, t: t + Double(m.i) * 0.3, walk: 1)
                } else {
                    let frame = Int(phase / (2 * .pi) * 4) & 3
                    let col = RGB.lerp(RGB(0.3, 0.3, 0.36), RGB(0.12, 0.12, 0.16), m.z)
                    c.fill(Stamps.unsullied[frame].applying(CGAffineTransform(translationX: m.x, y: m.y).scaledBy(x: s, y: s)), with: .color(col.color()))
                }
            }
        }
    }

    private static func dust(_ c: GraphicsContext, _ env: SceneEnv, behind p: CGPoint) {
        let u = env.u
        for i in 0..<12 {
            let a = M.fract(env.t * 0.6 + M.rand(i, 310))
            let q = CGPoint(x: p.x - 16 * u - CGFloat(a) * 60 * u - CGFloat(M.rand(i, 311)) * 30 * u, y: p.y - CGFloat(M.rand(i, 312)) * 5 * u - CGFloat(a) * 4 * u)
            c.fill(Ink.circle(q, (2 + CGFloat(a) * 5) * u), with: .color(RGB(0.85, 0.68, 0.48).color(0.22 * (1 - a))))
        }
    }

    /// Embers trailing a dragon along its route.
    private static func trail(_ c: GraphicsContext, _ env: SceneEnv, along route: QuadCurve, at q: CGFloat, u: CGFloat, t: Double, seed: Int) {
        guard q > 0.02 else { return }
        var e = c
        e.blendMode = .plusLighter
        for i in 0..<10 {
            let age = M.fract(t * 0.9 + M.rand(i + seed * 20, 320))
            var pt = route.point(max(0, q - CGFloat(0.05 + age * 0.06)))
            pt.y += CGFloat(M.rand(i, 321) - 0.3) * 8 * u * CGFloat(age)
            e.fill(Ink.circle(pt, (1.3 - CGFloat(age)) * u), with: .color(RGB.lerp(RGB(1, 0.85, 0.45), RGB(0.95, 0.3, 0.1), age).color((1 - age) * 0.6)))
        }
    }

    // MARK: - Landmarks

    /// Draws a place at `x`. `side` -1 = origin on the left, 1 = destination on the right.
    /// `waterOnly`: on sea maps the coast/island is drawn again over the animated water.
    static func landmark(_ c: GraphicsContext, _ env: SceneEnv, _ kind: Landmark, x: CGFloat, side: CGFloat, waterOnly: Bool = false) {
        let u = env.u, hy = env.hy
        let isWater: Bool = {
            switch kind { case .dragonstone, .kingsLanding, .qarth, .astapor, .meereen, .whiteHarbor: return true
            default: return false }
        }()
        if waterOnly && !isWater { return }
        switch kind {
        case .pentos:
            Buildings.house(c, x: x - 22 * u, base: hy + 6 * u, w: 22 * u, h: 13 * u, wall: RGB(0.95, 0.9, 0.82), roof: RGB(0.82, 0.42, 0.26), u: u, lit: 0.2, seed: 1)
            Buildings.house(c, x: x + 2 * u, base: hy + 7 * u, w: 18 * u, h: 11 * u, wall: RGB(0.93, 0.88, 0.8), roof: RGB(0.78, 0.4, 0.24), u: u, lit: 0.2, seed: 2)
            Buildings.tower(c, x: x - 4 * u, base: hy + 6 * u, w: 6 * u, h: 34 * u, stone: RGB(0.95, 0.9, 0.82), roof: RGB(0.82, 0.42, 0.26), u: u * 0.7, lit: 0, seed: 3)
        case .lhazar:
            for i in 0..<4 {
                let cx = x - 22 * u + CGFloat(i) * 14 * u, base = hy + (5 + CGFloat(i % 2) * 3) * u
                var hut = Path()
                hut.move(to: CGPoint(x: cx - 6 * u, y: base))
                hut.addQuadCurve(to: CGPoint(x: cx + 6 * u, y: base), control: CGPoint(x: cx, y: base - 15 * u))
                hut.closeSubpath()
                c.fill(hut, with: .linearGradient(Gradient(colors: [RGB(0.7, 0.55, 0.38).color(), RGB(0.42, 0.3, 0.2).color()]), startPoint: CGPoint(x: cx - 6 * u, y: 0), endPoint: CGPoint(x: cx + 6 * u, y: 0)))
                c.fill(Path(roundedRect: CGRect(x: cx - 1.5 * u, y: base - 4 * u, width: 3 * u, height: 4 * u), cornerRadius: 1.5 * u), with: .color(RGB(0.15, 0.1, 0.07).color()))
            }
        case .qarth:
            Buildings.qarth(c, env, x0: side > 0 ? x - 72 * u : x - 30 * u, scale: 0.75)
        case .astapor:
            for (i, sz) in [CGFloat(0.55), 0.8, 0.6].enumerated() {
                pyramid(c, cx: x - 22 * u + CGFloat(i) * 22 * u, base: hy + 3 * u, w: 46 * u * sz, steps: 5, color: RGB(0.74, 0.32, 0.22), u: u)
            }
        case .meereen:
            pyramid(c, cx: x - 26 * u, base: hy + 3 * u, w: 34 * u, steps: 5, color: RGB(0.8, 0.6, 0.45), u: u)
            pyramid(c, cx: x + 4 * u, base: hy + 3 * u, w: 56 * u, steps: 7, color: RGB(0.86, 0.68, 0.5), u: u)
            // The bronze harpy on top of the Great Pyramid.
            let top = CGPoint(x: x + 4 * u, y: hy + 3 * u - 7 * 6 * u)
            c.fill(Path { p in p.move(to: CGPoint(x: top.x, y: top.y - 1 * u)); p.addLine(to: CGPoint(x: top.x - 6 * u, y: top.y - 7 * u)); p.addLine(to: CGPoint(x: top.x - 1 * u, y: top.y - 4 * u)); p.addLine(to: CGPoint(x: top.x, y: top.y - 9 * u)); p.addLine(to: CGPoint(x: top.x + 1 * u, y: top.y - 4 * u)); p.addLine(to: CGPoint(x: top.x + 6 * u, y: top.y - 7 * u)); p.closeSubpath() },
                   with: .color(RGB(0.75, 0.55, 0.22).color()))
        case .dothrakiSea:
            for i in 0..<5 {
                let gx = x - 26 * u + CGFloat(i) * 12 * u
                var grass = Path()
                for k in 0..<6 { let bx = gx + CGFloat(k) * 1.6 * u; grass.move(to: CGPoint(x: bx, y: hy + 8 * u)); grass.addLine(to: CGPoint(x: bx + 2 * u, y: hy - 4 * u - CGFloat(k % 3) * 2 * u)) }
                c.stroke(grass, with: .color(RGB(0.62, 0.62, 0.34).color()), lineWidth: 0.8 * u)
            }
        case .vaesDothrak:
            Buildings.dothrakiHall(c, cx: x - 30 * u, base: hy + 5 * u, k: 0.5, u: u, glow: 0.3, t: 0)
            // The Horse Gate: two rearing stone horses.
            horseGate(c, cx: x + 8 * u, base: hy + 9 * u, k: 1.0, u: u)
        case .dragonstone:
            Buildings.dragonstone(c, base: CGPoint(x: x + side * 4 * u, y: hy + 3 * u), u: u * 1.15, t: 0, rock: RGB(0.32, 0.31, 0.38))
        case .goldenRoad:
            for i in 0..<3 {
                let wx = x - 24 * u + CGFloat(i) * 18 * u
                c.fill(Path(roundedRect: CGRect(x: wx - 7 * u, y: hy + 1 * u, width: 14 * u, height: 6 * u), cornerRadius: 1 * u), with: .color(RGB(0.42, 0.26, 0.15).color()))
                c.fill(Path(CGRect(x: wx - 6 * u, y: hy - 3 * u, width: 12 * u, height: 4 * u)), with: .color(RGB(0.88, 0.75, 0.38).color()))
                for wh in [wx - 4 * u, wx + 4 * u] { c.fill(Ink.circle(CGPoint(x: wh, y: hy + 7 * u), 2.4 * u), with: .color(RGB(0.2, 0.12, 0.08).color())) }
            }
            c.stroke(Path { $0.move(to: CGPoint(x: x + 30 * u, y: hy + 8 * u)); $0.addLine(to: CGPoint(x: x + 30 * u, y: hy - 18 * u)) }, with: .color(RGB(0.3, 0.2, 0.12).color()), lineWidth: 0.8 * u)
            c.fill(Path(CGRect(x: x + 30 * u, y: hy - 18 * u, width: 9 * u, height: 7 * u)), with: .color(RGB(0.72, 0.1, 0.1).color()))
            c.fill(Ink.circle(CGPoint(x: x + 34.5 * u, y: hy - 14.5 * u), 1.6 * u), with: .color(RGB(0.95, 0.78, 0.25).color()))
        case .eastwatch:
            // The Wall: a cliff of ice with Eastwatch on top.
            let top = hy - 34 * u
            c.fill(Path(CGRect(x: -2, y: top, width: x + 20 * u, height: env.h - top)), with: .linearGradient(
                Gradient(colors: [RGB(0.86, 0.92, 1).color(), RGB(0.55, 0.66, 0.82).color(), RGB(0.32, 0.4, 0.56).color()]),
                startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: env.h)))
            var cracks = Path()
            for i in 0..<9 { let cx = CGFloat(M.rand(i, 330)) * (x + 18 * u); cracks.move(to: CGPoint(x: cx, y: top + 3 * u)); cracks.addLine(to: CGPoint(x: cx + 3 * u, y: top + CGFloat(10 + 20 * M.rand(i, 331)) * u)) }
            c.stroke(cracks, with: .color(.white.opacity(0.35)), lineWidth: 0.6 * u)
            Buildings.tower(c, x: x - 6 * u, base: top + 1 * u, w: 7 * u, h: 14 * u, stone: RGB(0.25, 0.25, 0.3), roof: RGB(0.2, 0.2, 0.25), u: u * 0.6, lit: 0.9, seed: 40, crenel: true)
        case .beyondWall:
            var peak = Path()
            peak.move(to: CGPoint(x: x - 34 * u, y: hy + 4 * u)); peak.addLine(to: CGPoint(x: x - 6 * u, y: hy - 38 * u)); peak.addLine(to: CGPoint(x: x + 4 * u, y: hy - 30 * u)); peak.addLine(to: CGPoint(x: x + 30 * u, y: hy + 4 * u)); peak.closeSubpath()
            c.fill(peak, with: .linearGradient(Gradient(colors: [RGB(0.9, 0.94, 1).color(), RGB(0.35, 0.42, 0.58).color()]), startPoint: CGPoint(x: x, y: hy - 38 * u), endPoint: CGPoint(x: x, y: hy + 4 * u)))
            // A frozen lake with a lonely rock.
            c.fill(Ink.ellipse(CGPoint(x: x - 4 * u, y: hy + 12 * u), 30 * u, 4 * u), with: .color(RGB(0.8, 0.88, 0.96).color(0.8)))
            c.fill(Ink.ellipse(CGPoint(x: x - 4 * u, y: hy + 10 * u), 6 * u, 3 * u), with: .color(RGB(0.25, 0.28, 0.34).color()))
        case .whiteHarbor:
            for i in 0..<5 {
                Buildings.house(c, x: x - 30 * u + CGFloat(i) * 11 * u, base: hy + 3 * u, w: 10 * u, h: (8 + 4 * CGFloat(i % 2)) * u, wall: RGB(0.85, 0.85, 0.88), roof: RGB(0.35, 0.4, 0.5), u: u * 0.8, lit: 0.6, seed: i + 50, snow: true)
            }
        case .winterfell:
            let stone = RGB(0.26, 0.28, 0.34)
            Buildings.wall(c, x0: x - 30 * u, x1: x + 30 * u, base: hy + 5 * u, h: 12 * u, stone: stone, u: u * 0.8, gate: x, lit: 0.9)
            for (i, dx) in [CGFloat(-26), -10, 6, 22].enumerated() {
                Buildings.tower(c, x: x + dx * u - 4 * u, base: hy + 4 * u, w: 8 * u, h: (24 + 10 * CGFloat(i % 2)) * u, stone: stone, roof: RGB(0.2, 0.2, 0.27), u: u * 0.7, lit: 0.9, seed: i + 60, crenel: i % 2 == 1)
            }
        case .kingsLanding:
            Buildings.kingsLanding(c, base: CGPoint(x: x + 20 * u, y: hy + 6 * u), u: 0.62 * u, t: 0, lit: 0.6, land: RGB(0.4, 0.3, 0.24), extent: 140)
        case .ruins:
            let base = hy + 6 * u
            for i in 0..<5 {
                let bx = (side > 0 ? x - 34 * u : x - 20 * u) + CGFloat(i) * 12 * u
                let h = (8 + 10 * CGFloat(M.rand(i, 340))) * u
                var r = Path()
                r.move(to: CGPoint(x: bx, y: base)); r.addLine(to: CGPoint(x: bx, y: base - h)); r.addLine(to: CGPoint(x: bx + 4 * u, y: base - h + 3 * u))
                r.addLine(to: CGPoint(x: bx + 7 * u, y: base - h * 0.7)); r.addLine(to: CGPoint(x: bx + 10 * u, y: base)); r.closeSubpath()
                c.fill(r, with: .color(RGB(0.2, 0.15, 0.14).color()))
            }
            if side > 0 {
                // What is left of the Red Keep.
                Buildings.tower(c, x: x - 6 * u, base: base, w: 9 * u, h: 32 * u, stone: RGB(0.42, 0.18, 0.14), roof: nil, u: u * 0.7, lit: 0, seed: 70, crenel: true)
                Buildings.tower(c, x: x + 6 * u, base: base, w: 7 * u, h: 22 * u, stone: RGB(0.38, 0.16, 0.12), roof: nil, u: u * 0.7, lit: 0, seed: 71)
            }
        }
    }

    static func pyramid(_ c: GraphicsContext, cx: CGFloat, base: CGFloat, w: CGFloat, steps: Int, color: RGB, u: CGFloat) {
        let sh = w / CGFloat(steps) * 0.7
        for s in 0..<steps {
            let ww = w * (1 - CGFloat(s) / CGFloat(steps) * 0.85)
            let rx = cx - ww / 2, ry = base - CGFloat(s + 1) * sh
            c.fill(Path(CGRect(x: rx, y: ry, width: ww, height: sh)), with: .linearGradient(
                Gradient(colors: [RGB(min(1, color.r * 1.2), min(1, color.g * 1.2), min(1, color.b * 1.2)).color(), RGB(color.r * 0.7, color.g * 0.7, color.b * 0.7).color()]),
                startPoint: CGPoint(x: rx, y: 0), endPoint: CGPoint(x: rx + ww, y: 0)))
            c.fill(Path(CGRect(x: rx, y: ry, width: ww, height: 0.8 * u)), with: .color(RGB(1, 0.85, 0.65).color(0.45)))
        }
    }
}

extension Travel {
    /// The Horse Gate of Vaes Dothrak: two bronze stallions rearing toward each other, hooves meeting over the road.
    static func horseGate(_ c: GraphicsContext, cx: CGFloat, base: CGFloat, k: CGFloat, u: CGFloat) {
        let bronze = Horse.Coat(body: RGB(0.66, 0.45, 0.24), mane: RGB(0.42, 0.27, 0.13))
        for side in [CGFloat(-1), 1] {
            let pivot = CGPoint(x: cx + side * 9 * u * k, y: base - 6 * u * k)
            // Stone pedestal.
            c.fill(Path(CGRect(x: pivot.x - 8 * u * k, y: pivot.y, width: 16 * u * k, height: 6 * u * k)), with: .linearGradient(
                Gradient(colors: [RGB(0.55, 0.5, 0.42).color(), RGB(0.32, 0.28, 0.24).color()]), startPoint: CGPoint(x: pivot.x - 8 * u * k, y: 0), endPoint: CGPoint(x: pivot.x + 8 * u * k, y: 0)))
            c.fill(Path(CGRect(x: pivot.x - 9 * u * k, y: pivot.y - 1 * u * k, width: 18 * u * k, height: 1.6 * u * k)), with: .color(RGB(0.62, 0.57, 0.5).color()))
            // The horse, rotated up on its hind legs.
            var g = c
            g.translateBy(x: pivot.x, y: pivot.y)
            g.rotate(by: .degrees(Double(side) * 50))
            let facing = -side
            Horse.draw(g, at: CGPoint(x: 7 * u * k * facing, y: 0), scale: u * k, coat: bronze, phase: 2.6, facing: facing, moving: true)
        }
        // A green patina glint on the bronze.
        var shine = c
        shine.blendMode = .plusLighter
        shine.fill(Ink.ellipse(CGPoint(x: cx, y: base - 26 * u * k), 18 * u * k, 10 * u * k), with: .radialGradient(
            Gradient(colors: [RGB(1, 0.8, 0.5).color(0.12), RGB(1, 0.8, 0.5).color(0)]), center: CGPoint(x: cx, y: base - 26 * u * k), startRadius: 0, endRadius: 18 * u * k))
    }

    /// Things passing by close to the viewer, scrolling left: tufts and bushes, rocks, snow mounds, rubble, whitecaps.
    /// They keep moving even on long timers, so the journey always feels like motion.
    static func passingBy(_ c: GraphicsContext, _ env: SceneEnv, ground: Ground) {
        let u = env.u, t = env.t, hy = env.hy
        let span = env.w + 60 * u
        let speed: Double = ground == .sea ? 16 : 11
        for i in 0..<16 {
            let z = M.rand(i, 400)
            let v = speed * (0.6 + 0.8 * z) * Double(u)
            let x = CGFloat(M.fract(M.rand(i, 401) - t * v / Double(span))) * span - 30 * u
            let y = hy + (ground == .sea ? 6 : 20) * u + CGFloat(z) * (ground == .sea ? 26 : 14) * u
            let s = (0.7 + 0.8 * CGFloat(z)) * u
            switch ground {
            case .steppe:
                var g = Path()
                for k in 0..<5 { let bx = x + CGFloat(k) * 1.4 * s; g.move(to: CGPoint(x: bx, y: y)); g.addLine(to: CGPoint(x: bx + (CGFloat(k) - 2) * 0.8 * s, y: y - (4 + CGFloat(k % 2) * 2.5) * s)) }
                c.stroke(g, with: .color(RGB(0.52, 0.58, 0.3).color(0.85)), lineWidth: 0.7 * s)
                if i % 4 == 0 { c.fill(Ink.ellipse(CGPoint(x: x + 3 * s, y: y - 2 * s), 4 * s, 2.6 * s), with: .color(RGB(0.3, 0.4, 0.2).color())) }
            case .desert:
                if i % 3 == 0 {
                    var shrub = Path()
                    for k in 0..<6 { let a = Double(k) / 5 * .pi; shrub.move(to: CGPoint(x: x, y: y)); shrub.addLine(to: CGPoint(x: x - CGFloat(cos(a)) * 4 * s, y: y - CGFloat(sin(a)) * 4 * s)) }
                    c.stroke(shrub, with: .color(RGB(0.45, 0.32, 0.2).color()), lineWidth: 0.5 * s)
                } else {
                    c.fill(Ink.ellipse(CGPoint(x: x, y: y), 2.6 * s, 1.2 * s), with: .color(RGB(0.6, 0.42, 0.3).color()))
                    c.fill(Ink.ellipse(CGPoint(x: x - 0.6 * s, y: y - 0.5 * s), 1.6 * s, 0.6 * s), with: .color(RGB(0.85, 0.66, 0.48).color()))
                }
            case .snow:
                c.fill(Ink.ellipse(CGPoint(x: x, y: y), 6 * s, 1.8 * s), with: .color(RGB(0.9, 0.94, 1).color(0.9)))
                if i % 5 == 0 {
                    var twig = Path()
                    twig.move(to: CGPoint(x: x, y: y)); twig.addLine(to: CGPoint(x: x + 1 * s, y: y - 9 * s))
                    twig.move(to: CGPoint(x: x + 0.6 * s, y: y - 5 * s)); twig.addLine(to: CGPoint(x: x + 3 * s, y: y - 7 * s))
                    c.stroke(twig, with: .color(RGB(0.25, 0.22, 0.24).color()), lineWidth: 0.6 * s)
                }
            case .ash:
                c.fill(Path { p in p.move(to: CGPoint(x: x - 3 * s, y: y)); p.addLine(to: CGPoint(x: x - 1 * s, y: y - 2.6 * s)); p.addLine(to: CGPoint(x: x + 2.5 * s, y: y - 1.6 * s)); p.addLine(to: CGPoint(x: x + 3 * s, y: y)); p.closeSubpath() },
                       with: .color(RGB(0.28, 0.22, 0.21).color()))
            case .sea:
                var cap = Path()
                cap.move(to: CGPoint(x: x, y: y)); cap.addQuadCurve(to: CGPoint(x: x + 7 * s, y: y), control: CGPoint(x: x + 3.5 * s, y: y - 1.6 * s))
                c.stroke(cap, with: .color(.white.opacity(0.35 + 0.3 * z)), lineWidth: 0.7 * s)
            }
        }
    }
}
