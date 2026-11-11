import SwiftUI

/// Rest scene: a hill at sunset, Daenerys sits next to the dragon and strokes its head.
/// The sun sets during the rest; stars come out at the end.
enum RestPainter {
    /// One stroke of the hand, in seconds.
    static let petPeriod = 2.8

    static func draw(_ c: GraphicsContext, size: CGSize, progress p: Double, t: Double) {
        let w = size.width, h = size.height, u = h / 118, hy = h * 0.72

        let top = RGB.lerp(RGB(0.38, 0.20, 0.50), RGB(0.06, 0.06, 0.18), p)
        let bottom = RGB.lerp(RGB(1.0, 0.62, 0.38), RGB(0.40, 0.24, 0.44), p)
        Landscape.sky(c, size, top: top, bottom: bottom, horizon: hy)
        Landscape.stars(c, size, u: u, t: t, opacity: M.smoothstep(0.55, 1, p), maxY: hy * 0.8, count: 34)

        let sunColor = RGB.lerp(RGB(1, 0.78, 0.45), RGB(1, 0.45, 0.30), p)
        let sun = CGPoint(x: w * 0.80, y: M.lerp(h * 0.40, h * 0.82, CGFloat(p)))
        Landscape.sun(c, at: sun, radius: 13 * u, color: sunColor, glow: 1 - 0.6 * p)
        Landscape.sea(c, size, horizon: hy, u: u, t: t,
                      top: RGB.lerp(RGB(0.62, 0.36, 0.42), RGB(0.18, 0.14, 0.30), p),
                      bottom: RGB(0.06, 0.06, 0.16),
                      glint: sun.y < hy + 8 * u ? sunColor : nil, glintX: sun.x)
        Landscape.dragonstone(c, base: CGPoint(x: w * 0.94, y: hy + 1 * u), u: u * 0.45, t: t,
                              rock: RGB.lerp(RGB(0.30, 0.20, 0.32), RGB(0.12, 0.10, 0.20), p))

        // Hill.
        let B = CGPoint(x: w * 0.36, y: h * 0.69)
        let cx = B.x + 22 * u
        func ground(_ x: CGFloat) -> CGFloat { B.y + pow((x - cx) / (w * 0.5), 2) * h * 0.5 }
        var hill = Path()
        var ridge = Path()
        hill.move(to: CGPoint(x: 0, y: h))
        for x in stride(from: CGFloat(0), through: w, by: 4) {
            let y = min(h + 2, ground(x))
            hill.addLine(to: CGPoint(x: x, y: y))
            if x == 0 { ridge.move(to: CGPoint(x: x, y: y)) } else { ridge.addLine(to: CGPoint(x: x, y: y)) }
        }
        hill.addLine(to: CGPoint(x: w, y: h))
        hill.closeSubpath()
        c.fill(hill, with: .linearGradient(
            Gradient(colors: [RGB(0.17, 0.10, 0.18).color(), RGB(0.07, 0.04, 0.09).color()]),
            startPoint: CGPoint(x: 0, y: B.y), endPoint: CGPoint(x: 0, y: h)
        ))
        c.stroke(ridge, with: .color(RGB(1, 0.62, 0.42).color(0.35 * (1 - 0.6 * p))), lineWidth: 1 * u)

        // Grass that moves in the wind.
        var grass = Path()
        for i in 0..<22 {
            let x = CGFloat(M.rand(i, 80)) * w
            let y = ground(x)
            guard y < h - 2 * u else { continue }
            let bend = CGFloat(sin(t * 1.3 + Double(i))) * 1.2 * u
            let hgt = (2 + CGFloat(M.rand(i, 81)) * 2.5) * u
            grass.move(to: CGPoint(x: x, y: y + 0.5 * u))
            grass.addQuadCurve(to: CGPoint(x: x + bend, y: y - hgt), control: CGPoint(x: x, y: y - hgt * 0.5))
        }
        c.stroke(grass, with: .color(RGB(0.25, 0.16, 0.26).color()), lineWidth: 0.7 * u)

        // Petting rhythm: the hand strokes the head (0...0.62), then lifts and comes back.
        let phi = M.fract(t / petPeriod)
        let lift = phi < 0.62 ? sin(.pi * phi / 0.62) : 0
        let rig = RestDragonRig(base: CGPoint(x: B.x + 42 * u, y: B.y), scale: 0.9 * u, t: t, lift: lift)
        let eyesClosed = phi > 0.04 && phi < 0.74
        DragonPainter.drawResting(c, rig: rig, t: t, eyesClosed: eyesClosed, palette: .drogon)

        let front = rig.headWorld(CGPoint(x: 11, y: -5.4))
        let back = rig.headWorld(CGPoint(x: 2, y: -6.3))
        var hand: CGPoint
        if phi < 0.62 {
            hand = M.lerp(front, back, CGFloat(M.easeInOut(phi / 0.62)))
        } else {
            let k = (phi - 0.62) / 0.38
            hand = M.lerp(back, front, CGFloat(M.easeInOut(k)))
            hand.y -= CGFloat(sin(.pi * k)) * 4 * u
        }
        Daenerys.draw(c, base: B, u: u, hand: hand, t: t, rim: sunColor.color(0.35 * (1 - 0.5 * p)))

        // Smoke rings from the nostrils.
        let nostril = rig.headWorld(DragonPainter.nostrilLocal)
        for k in 0..<3 {
            let a = M.fract(t / 3.3 + Double(k) / 3)
            let q = CGPoint(x: nostril.x - CGFloat(a) * 8 * u, y: nostril.y - CGFloat(a) * 9 * u)
            let alpha = 0.35 * (1 - a) * M.smoothstep(0, 0.15, a)
            c.stroke(Ink.circle(q, (0.8 + CGFloat(a) * 2.6) * u), with: .color(.white.opacity(alpha)), lineWidth: 0.7 * u)
        }

        // Hearts rise from the dragon's head.
        let heartBase = rig.headWorld(CGPoint(x: 5, y: -9))
        for k in 0..<2 {
            let a = M.fract(t / 3.6 + Double(k) * 0.5)
            let q = CGPoint(x: heartBase.x + CGFloat(sin(a * 5 + Double(k) * 2)) * 2.5 * u + CGFloat(k) * 5 * u,
                            y: heartBase.y - CGFloat(a) * 26 * u)
            c.fill(Ink.heart(q, (3.5 + 3 * CGFloat(a)) * u), with: .color(RGB(1, 0.42, 0.55).color(sin(.pi * a) * 0.9)))
        }

        // Fireflies, more of them as it gets dark.
        var g = c
        g.blendMode = .plusLighter
        for i in 0..<12 {
            let bx = CGFloat(M.rand(i, 70)) * w
            let by = h * CGFloat(0.35 + 0.5 * M.rand(i, 71))
            let q = CGPoint(x: bx + CGFloat(sin(t * 0.45 + Double(i))) * 9 * u,
                            y: by + CGFloat(cos(t * 0.6 + Double(i) * 1.3)) * 5 * u)
            let blink = pow(0.5 + 0.5 * sin(t * 1.6 + Double(i) * 2.1), 3) * (0.35 + 0.65 * p)
            g.fill(Ink.circle(q, 4 * u), with: .radialGradient(
                Gradient(colors: [RGB(1, 0.95, 0.55).color(0.5 * blink), RGB(1, 0.95, 0.55).color(0)]),
                center: q, startRadius: 0, endRadius: 4 * u
            ))
            g.fill(Ink.circle(q, 0.8 * u), with: .color(RGB(1, 0.98, 0.7).color(blink)))
        }
    }
}

/// Daenerys sitting on the ground, facing right, silver braids and a blue dress.
/// `base`: point on the ground under her hips. The near arm reaches `hand` (2-bone IK).
enum Daenerys {
    static let dressLight = RGB(0.36, 0.50, 0.82)
    static let dressDark = RGB(0.17, 0.24, 0.46)
    static let sleeve = RGB(0.42, 0.56, 0.88)
    static let skin = RGB(0.97, 0.85, 0.76)
    static let hair = RGB(0.94, 0.93, 0.98)
    static let hairShade = RGB(0.70, 0.70, 0.82)

    static func draw(_ c: GraphicsContext, base B: CGPoint, u: CGFloat, hand: CGPoint, t: Double, rim: Color) {
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: B.x + x * u, y: B.y + y * u) }
        let breath = CGFloat(sin(t * 2 * .pi / 4)) * 0.25
        let dress = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [dressLight.color(), dressDark.color()]),
            startPoint: P(0, -29), endPoint: P(0, 1)
        )

        // Far arm rests on the knees.
        var farArm = Path()
        farArm.move(to: P(2, -26 + breath))
        farArm.addQuadCurve(to: P(11, -10), control: P(1, -16))
        c.stroke(farArm, with: .color(dressDark.color()), style: StrokeStyle(lineWidth: 2.6 * u, lineCap: .round))

        // Skirt, knees forward.
        var skirt = Path()
        skirt.move(to: P(-2, -16))
        skirt.addQuadCurve(to: P(-13, 0.5), control: P(-10, -9))
        skirt.addLine(to: P(16, 0.5))
        skirt.addQuadCurve(to: P(13, -8), control: P(18, -5))
        skirt.addQuadCurve(to: P(4, -16), control: P(8, -13))
        skirt.closeSubpath()
        c.fill(skirt, with: dress)
        c.stroke(skirt, with: .color(rim), lineWidth: 0.6 * u)

        // Torso, leaning a little towards the dragon.
        var torso = Path()
        torso.move(to: P(-3.5, -15.5))
        torso.addLine(to: P(4.5, -15.5))
        torso.addQuadCurve(to: P(7, -28 + breath), control: P(6.5, -21))
        torso.addQuadCurve(to: P(0, -29 + breath), control: P(3.5, -30.5 + breath))
        torso.addQuadCurve(to: P(-3.5, -15.5), control: P(-4, -22))
        torso.closeSubpath()
        c.fill(torso, with: dress)
        c.stroke(torso, with: .color(rim), lineWidth: 0.5 * u)

        // Neck.
        c.fill(Path(roundedRect: CGRect(x: B.x + 2.2 * u, y: B.y + (-33 + breath) * u, width: 2.6 * u, height: 5 * u),
                    cornerRadius: 1 * u), with: .color(skin.color()))

        let H = P(4.2, -36 + breath)
        func Q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: H.x + x * u, y: H.y + y * u) }

        // Long braid down the back.
        for i in 0..<8 {
            let f = CGFloat(i) / 7
            let sway = CGFloat(sin(t * 0.9 + Double(i) * 0.5)) * 0.3
            let q = Q(-4.2 - f * 4.5 + sway, 2 + f * 17)
            let r = (2.3 - CGFloat(i) * 0.16) * u
            let side: CGFloat = i % 2 == 0 ? -0.4 : 0.4
            let link = Ink.ellipse(CGPoint(x: q.x + side * u, y: q.y), r * 0.62, r * 0.5)
            c.fill(link, with: .color(hair.color()))
            c.stroke(link, with: .color(hairShade.color()), lineWidth: 0.35 * u)
        }

        // Hair, face, fringe.
        c.fill(Ink.ellipse(Q(-0.6, -0.6), 5.8 * u, 5.7 * u), with: .color(hair.color()))
        c.fill(Ink.ellipse(Q(1.6, 0.6), 3.9 * u, 4.3 * u), with: .color(skin.color()))
        var fringe = Path()
        fringe.move(to: Q(-3, -3))
        fringe.addQuadCurve(to: Q(5.4, -1.6), control: Q(2, -6.8))
        fringe.addQuadCurve(to: Q(-3, -3), control: Q(1, -3.6))
        c.fill(fringe, with: .color(hair.color()))
        var crown = Path()
        crown.move(to: Q(-5, -1))
        crown.addQuadCurve(to: Q(3, -5.4), control: Q(-3, -6.6))
        c.stroke(crown, with: .color(hairShade.color()),
                 style: StrokeStyle(lineWidth: 1.0 * u, lineCap: .round, dash: [1.2 * u, 0.8 * u]))

        // Calm closed eye and a hint of a smile.
        var eye = Path()
        eye.move(to: Q(2.6, 0))
        eye.addQuadCurve(to: Q(4.3, 0), control: Q(3.45, 0.9))
        c.stroke(eye, with: .color(.black.opacity(0.65)), style: StrokeStyle(lineWidth: 0.55 * u, lineCap: .round))
        var smile = Path()
        smile.move(to: Q(3.3, 2.6))
        smile.addQuadCurve(to: Q(4.6, 2.3), control: Q(4.1, 3.1))
        c.stroke(smile, with: .color(RGB(0.75, 0.40, 0.40).color(0.8)), style: StrokeStyle(lineWidth: 0.45 * u, lineCap: .round))

        // Near arm strokes the dragon.
        let shoulder = P(5.5, -26.5 + breath)
        let (elbow, wrist) = IK.solve(shoulder: shoulder, target: hand, upper: 10.5 * u, lower: 10.5 * u, bendDown: true)
        var arm = Path()
        arm.move(to: shoulder)
        arm.addLine(to: elbow)
        arm.addLine(to: wrist)
        c.stroke(arm, with: .color(sleeve.color()), style: StrokeStyle(lineWidth: 2.8 * u, lineCap: .round, lineJoin: .round))
        c.fill(Ink.ellipse(wrist, 1.8 * u, 1.35 * u), with: .color(skin.color()))
    }
}
