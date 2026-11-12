import SwiftUI
import StudyNookCore

enum HairKind { case none, short, long, braids, topknot, helmet, spikedCrown, hood }
enum Prop { case none, spear, sword, torch, staff, whip, banner(RGB) }

struct FigureStyle {
    var skin = RGB(0.95, 0.80, 0.68)
    var cloth: RGB
    var cloth2: RGB
    var hair: RGB = RGB(0.15, 0.1, 0.08)
    var hairKind: HairKind = .short
    var cape: RGB?
    var prop: Prop = .none
    var dress = false
    var eyeGlow: RGB?

    // Characters.
    static let drogo = FigureStyle(skin: RGB(0.74, 0.54, 0.38), cloth: RGB(0.42, 0.26, 0.16), cloth2: RGB(0.85, 0.62, 0.25),
                                   hair: RGB(0.05, 0.04, 0.04), hairKind: .braids, prop: .none)
    static let jon = FigureStyle(cloth: RGB(0.14, 0.14, 0.17), cloth2: RGB(0.45, 0.45, 0.5),
                                 hair: RGB(0.12, 0.09, 0.08), hairKind: .short, cape: RGB(0.1, 0.1, 0.12), prop: .sword)
    static let jorah = FigureStyle(skin: RGB(0.9, 0.74, 0.62), cloth: RGB(0.30, 0.23, 0.16), cloth2: RGB(0.50, 0.40, 0.28),
                                   hair: RGB(0.35, 0.25, 0.15), hairKind: .short, cape: RGB(0.22, 0.18, 0.12), prop: .sword)
    static let nightKing = FigureStyle(skin: RGB(0.72, 0.82, 0.9), cloth: RGB(0.08, 0.10, 0.16), cloth2: RGB(0.38, 0.55, 0.75),
                                       hair: RGB(0.5, 0.6, 0.7), hairKind: .spikedCrown, cape: RGB(0.07, 0.08, 0.13),
                                       prop: .none, eyeGlow: RGB(0.4, 0.75, 1))
    static let kraznys = FigureStyle(skin: RGB(0.9, 0.78, 0.6), cloth: RGB(0.92, 0.82, 0.42), cloth2: RGB(0.7, 0.45, 0.2),
                                     hair: RGB(0.1, 0.08, 0.06), hairKind: .none, prop: .whip)
    static let lannister = FigureStyle(cloth: RGB(0.70, 0.12, 0.12), cloth2: RGB(0.9, 0.7, 0.2),
                                       hair: RGB(0.3, 0.3, 0.32), hairKind: .helmet, prop: .spear)
    static let unsullied = FigureStyle(skin: RGB(0.7, 0.55, 0.42), cloth: RGB(0.40, 0.42, 0.46), cloth2: RGB(0.75, 0.62, 0.38),
                                       hair: RGB(0.7, 0.6, 0.4), hairKind: .helmet, prop: .spear)
    static let dothrakiRider = FigureStyle(skin: RGB(0.72, 0.52, 0.38), cloth: RGB(0.32, 0.2, 0.13), cloth2: RGB(0.8, 0.58, 0.25),
                                           hair: RGB(0.04, 0.03, 0.03), hairKind: .braids)
    static let wight = FigureStyle(skin: RGB(0.55, 0.68, 0.78), cloth: RGB(0.18, 0.22, 0.28), cloth2: RGB(0.35, 0.45, 0.55),
                                   hair: RGB(0.3, 0.35, 0.4), hairKind: .short, eyeGlow: RGB(0.4, 0.75, 1))

    static func dany(_ o: DanyOutfit, prop: Prop = .none) -> FigureStyle {
        FigureStyle(skin: RGB(0.97, 0.85, 0.76), cloth: o.dressLight, cloth2: o.dressDark,
                    hair: RGB(0.94, 0.93, 0.98), hairKind: .braids, prop: prop, dress: true)
    }
}

struct DanyOutfit {
    var dressLight: RGB
    var dressDark: RGB
    var sleeve: RGB

    static let blue = DanyOutfit(dressLight: RGB(0.36, 0.50, 0.82), dressDark: RGB(0.17, 0.24, 0.46), sleeve: RGB(0.42, 0.56, 0.88))
    static let wedding = DanyOutfit(dressLight: RGB(0.88, 0.84, 0.76), dressDark: RGB(0.55, 0.5, 0.45), sleeve: RGB(0.9, 0.86, 0.8))
    static let dothraki = DanyOutfit(dressLight: RGB(0.58, 0.40, 0.26), dressDark: RGB(0.30, 0.19, 0.12), sleeve: RGB(0.62, 0.44, 0.3))
    static let pyre = DanyOutfit(dressLight: RGB(1.0, 0.78, 0.55), dressDark: RGB(0.9, 0.45, 0.2), sleeve: RGB(1.0, 0.8, 0.6))
    static let white = DanyOutfit(dressLight: RGB(0.93, 0.91, 0.87), dressDark: RGB(0.62, 0.6, 0.62), sleeve: RGB(0.95, 0.93, 0.9))
    static let black = DanyOutfit(dressLight: RGB(0.20, 0.20, 0.25), dressDark: RGB(0.07, 0.07, 0.10), sleeve: RGB(0.26, 0.26, 0.32))

    /// Outfit of Daenerys at the end of the chapter.
    static func of(_ ch: Chapter) -> DanyOutfit {
        switch ch {
        case .birth: .dothraki
        case .qarth: .dothraki
        case .astapor, .vaesDothrak: .blue
        case .meereen: .white
        case .sailing, .goldenRoad: .white
        case .beyondWall, .winterfell: .black
        case .rhaegal, .kingsLanding, .epilogue: .black
        }
    }
}

/// A person: feet at `feet`, `h` points tall. `walk` 0 = stands, 1 = walks. `arms` 0 = down, 1 = raised.
enum Figure {
    static func draw(_ base: GraphicsContext, feet: CGPoint, h: CGFloat, style s: FigureStyle,
                     facing: CGFloat = 1, t: Double, walk: Double = 0, arms: Double = 0, sit: Bool = false) {
        var c = base
        let k = h / 20
        c.translateBy(x: feet.x, y: feet.y)
        c.scaleBy(x: facing, y: 1)
        let swing = CGFloat(sin(t * 7)) * CGFloat(walk)
        let bob = CGFloat(abs(sin(t * 7))) * 0.5 * k * CGFloat(walk)
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: (y * k) - bob) }

        // Cape behind.
        if let cape = s.cape {
            var p = Path()
            let wave = CGFloat(sin(t * 2.4)) * 0.8 + swing * 0.6
            p.move(to: P(-0.6, -16.4))
            p.addQuadCurve(to: P(-5.4 + wave, -4.5), control: P(-4.5, -12))
            p.addLine(to: P(-1.0 + wave * 0.4, -3.6))
            p.addLine(to: P(1.4, -15))
            p.closeSubpath()
            c.fill(p, with: .color(cape.color()))
        }

        // Legs or dress.
        if s.dress {
            var skirt = Path()
            skirt.move(to: P(-2.2, -9.5))
            skirt.addQuadCurve(to: P(-3.7 + swing * 0.5, 0), control: P(-3.4, -4))
            skirt.addLine(to: P(3.7 + swing * 0.5, 0))
            skirt.addQuadCurve(to: P(2.2, -9.5), control: P(3.4, -4))
            skirt.closeSubpath()
            c.fill(skirt, with: .linearGradient(Gradient(colors: [s.cloth.color(), s.cloth2.color()]),
                                                startPoint: P(0, -10), endPoint: P(0, 0)))
        } else {
            for (i, side) in [(-1.0, CGFloat(-1)), (1.0, 1)].enumerated() {
                let dx = CGFloat(side.0) * 0.9 + side.1 * swing * 2.4
                let leg = [P(CGFloat(side.0) * 0.7, -9), P(dx, -0.4)]
                c.stroke(Path { $0.move(to: leg[0]); $0.addLine(to: leg[1]) },
                         with: .color((i == 0 ? s.cloth2 : s.cloth2).color()), style: StrokeStyle(lineWidth: 1.9 * k, lineCap: .round))
            }
        }

        // Torso.
        c.fill(Ink.tapered([P(0, -9.2), P(0, -16)], 4.6 * k, 5.2 * k), with: .color(s.cloth.color()))
        c.fill(Path(CGRect(x: -2.4 * k, y: (-10.4 * k) - bob, width: 4.8 * k, height: 0.9 * k)), with: .color(s.cloth2.color()))

        // Head and hair.
        let hc = P(0.2, -18.5)
        switch s.hairKind {
        case .long, .braids:
            c.fill(Ink.tapered([P(-0.6, -19), P(-2.4, -15), P(-2.2, -11.5)], 3.2 * k, 1.2 * k), with: .color(s.hair.color()))
        default: break
        }
        c.fill(Ink.circle(hc, 2.0 * k), with: .color(s.skin.color()))
        switch s.hairKind {
        case .none: break
        case .short, .long, .braids:
            var hair = Path()
            hair.addArc(center: hc, radius: 2.15 * k, startAngle: .degrees(150), endAngle: .degrees(-20), clockwise: false)
            hair.closeSubpath()
            c.fill(hair, with: .color(s.hair.color()))
        case .topknot:
            c.fill(Ink.circle(P(-0.2, -21.1), 1.0 * k), with: .color(s.hair.color()))
        case .helmet:
            var hel = Path()
            hel.addArc(center: hc, radius: 2.25 * k, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            hel.closeSubpath()
            c.fill(hel, with: .color(s.cloth2.color()))
            c.fill(Path { $0.move(to: P(-0.4, -20.6)); $0.addLine(to: P(0.2, -23.2)); $0.addLine(to: P(0.8, -20.6)); $0.closeSubpath() },
                   with: .color(s.cloth2.color()))
        case .spikedCrown:
            for i in 0..<5 {
                let a = Double(i) / 4 * .pi - .pi
                let b = CGPoint(x: hc.x + CGFloat(cos(a)) * 2 * k, y: hc.y + CGFloat(sin(a)) * 2 * k)
                var sp = Path()
                sp.move(to: CGPoint(x: b.x - 0.35 * k, y: b.y + 0.3 * k))
                sp.addLine(to: CGPoint(x: b.x + CGFloat(cos(a)) * 1.9 * k, y: b.y + CGFloat(sin(a)) * 1.9 * k))
                sp.addLine(to: CGPoint(x: b.x + 0.35 * k, y: b.y + 0.3 * k))
                sp.closeSubpath()
                c.fill(sp, with: .color(s.hair.color()))
            }
        case .hood:
            c.fill(Ink.circle(hc, 2.3 * k), with: .color(s.cloth.color()))
            c.fill(Ink.circle(CGPoint(x: hc.x + 0.5 * k, y: hc.y + 0.2 * k), 1.5 * k), with: .color(s.skin.color()))
        }
        if let glow = s.eyeGlow {
            var g = c
            g.blendMode = .plusLighter
            g.fill(Ink.circle(P(1.1, -18.8), 1.4 * k), with: .radialGradient(
                Gradient(colors: [glow.color(0.9), glow.color(0)]), center: P(1.1, -18.8), startRadius: 0, endRadius: 1.4 * k))
        }

        // Arm and prop.
        let shoulder = P(0.6, -15.6)
        let down = P(2.2, -9.6), up = P(2.6, -22.5), mid = P(3.6, -15.6)
        let a = CGFloat(M.clamp01(arms))
        let hand = a < 0.5 ? M.lerp(down, mid, a * 2) : M.lerp(mid, up, (a - 0.5) * 2)
        c.stroke(Path { $0.move(to: shoulder); $0.addLine(to: hand) },
                 with: .color((s.dress ? s.cloth : s.cloth2).color()), style: StrokeStyle(lineWidth: 1.6 * k, lineCap: .round))
        c.fill(Ink.circle(hand, 0.95 * k), with: .color(s.skin.color()))
        switch s.prop {
        case .none: break
        case .spear:
            c.stroke(Path { $0.move(to: CGPoint(x: hand.x, y: hand.y + 6 * k)); $0.addLine(to: CGPoint(x: hand.x, y: hand.y - 11 * k)) },
                     with: .color(RGB(0.5, 0.38, 0.25).color()), lineWidth: 0.7 * k)
            c.fill(Path { $0.move(to: CGPoint(x: hand.x - 0.7 * k, y: hand.y - 11 * k)); $0.addLine(to: CGPoint(x: hand.x, y: hand.y - 14 * k)); $0.addLine(to: CGPoint(x: hand.x + 0.7 * k, y: hand.y - 11 * k)); $0.closeSubpath() },
                   with: .color(RGB(0.8, 0.82, 0.88).color()))
        case .sword:
            c.stroke(Path { $0.move(to: hand); $0.addLine(to: CGPoint(x: hand.x + 1.5 * k, y: hand.y - 7 * k)) },
                     with: .color(RGB(0.8, 0.84, 0.92).color()), lineWidth: 0.7 * k)
        case .torch:
            c.stroke(Path { $0.move(to: hand); $0.addLine(to: CGPoint(x: hand.x + 0.5 * k, y: hand.y - 4 * k)) },
                     with: .color(RGB(0.4, 0.28, 0.18).color()), lineWidth: 0.7 * k)
            Fire.torch(c, at: CGPoint(x: hand.x + 0.5 * k, y: hand.y - 4 * k), size: 2.4 * k, t: t, seed: 3)
        case .staff:
            c.stroke(Path { $0.move(to: CGPoint(x: hand.x, y: hand.y + 8 * k)); $0.addLine(to: CGPoint(x: hand.x, y: hand.y - 6 * k)) },
                     with: .color(RGB(0.45, 0.3, 0.2).color()), lineWidth: 0.7 * k)
        case .whip:
            var w = Path()
            w.move(to: hand)
            w.addQuadCurve(to: CGPoint(x: hand.x + 7 * k, y: hand.y + 3 * k), control: CGPoint(x: hand.x + 4 * k, y: hand.y - 5 * k + CGFloat(sin(t * 5)) * k))
            c.stroke(w, with: .color(RGB(0.2, 0.1, 0.05).color()), lineWidth: 0.5 * k)
        case let .banner(color):
            c.stroke(Path { $0.move(to: CGPoint(x: hand.x, y: hand.y + 6 * k)); $0.addLine(to: CGPoint(x: hand.x, y: hand.y - 13 * k)) },
                     with: .color(RGB(0.4, 0.3, 0.2).color()), lineWidth: 0.6 * k)
            var f = Path()
            let wave = CGFloat(sin(t * 4)) * 0.8 * k
            f.move(to: CGPoint(x: hand.x, y: hand.y - 13 * k))
            f.addQuadCurve(to: CGPoint(x: hand.x + 7 * k, y: hand.y - 11.5 * k + wave), control: CGPoint(x: hand.x + 3.5 * k, y: hand.y - 14.5 * k))
            f.addLine(to: CGPoint(x: hand.x, y: hand.y - 8.5 * k))
            f.closeSubpath()
            c.fill(f, with: .color(color.color()))
        }
    }
}
