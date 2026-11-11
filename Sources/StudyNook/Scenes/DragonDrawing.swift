import SwiftUI

struct DragonPalette {
    var body: Color
    var bodyDark: Color
    var belly: Color
    var wing: Color
    var wingFar: Color
    var wingEdge: Color
    var eye: Color
    var horn: Color
    var glowEye: Bool

    /// Black and red, like Drogon.
    static let drogon = DragonPalette(
        body: Color(red: 0.42, green: 0.10, blue: 0.08),
        bodyDark: Color(red: 0.15, green: 0.04, blue: 0.05),
        belly: Color(red: 0.80, green: 0.38, blue: 0.18),
        wing: Color(red: 0.55, green: 0.14, blue: 0.10),
        wingFar: Color(red: 0.28, green: 0.07, blue: 0.07),
        wingEdge: Color(red: 0.98, green: 0.50, blue: 0.26),
        eye: Color(red: 1.0, green: 0.84, blue: 0.34),
        horn: Color(red: 0.90, green: 0.82, blue: 0.68),
        glowEye: true
    )

    /// One color: for the tiny dragon in the collapsed island.
    static func mono(_ c: Color) -> DragonPalette {
        DragonPalette(body: c, bodyDark: c, belly: c, wing: c, wingFar: c.opacity(0.5),
                      wingEdge: c, eye: .black, horn: c, glowEye: false)
    }
}

/// Where and how the dragon is placed. The dragon is drawn facing right;
/// `flip` = -1 mirrors it to face left, values near 0 squash it (a turn).
struct DragonPose {
    var position: CGPoint
    var angle: Double
    var scale: CGFloat
    var flip: CGFloat = 1

    var transform: CGAffineTransform {
        let f = flip < 0 ? min(-0.15, flip) : max(0.15, flip)
        return CGAffineTransform(translationX: position.x, y: position.y)
            .rotated(by: angle)
            .scaledBy(x: scale * f, y: scale)
    }

    func world(_ p: CGPoint) -> CGPoint { p.applying(transform) }
}

enum DragonPainter {
    static let flyHeadBase = CGPoint(x: 32, y: -12)
    static let flyHeadAngle = 0.1
    static let mouthLocal = CGPoint(x: 18.5, y: 0.9)
    static let nostrilLocal = CGPoint(x: 16, y: -1.1)

    /// World position of the mouth of a flying dragon (fire comes out of here).
    static func mouth(_ pose: DragonPose) -> CGPoint {
        let head = CGAffineTransform(translationX: flyHeadBase.x, y: flyHeadBase.y).rotated(by: flyHeadAngle)
        return pose.world(mouthLocal.applying(head))
    }

    // MARK: - Flying

    /// Dragon in flight. Local size: about 115 × 60 units, origin at the middle of the body.
    static func drawFlying(_ base: GraphicsContext, pose: DragonPose, flapPhase: Double, t: Double, palette pal: DragonPalette) {
        var c = base
        c.concatenate(pose.transform)

        // Far wing, behind the body, slightly late.
        drawWing(c, shoulder: CGPoint(x: -2, y: -7), flap: sin(flapPhase - 0.5), size: 0.86,
                 fill: pal.wingFar, edge: pal.wingFar, bone: pal.bodyDark)

        // Tail sways.
        let sway = sin(t * 3.1)
        let tail = Ink.cubic(
            CGPoint(x: -14, y: 1), CGPoint(x: -32, y: 5),
            CGPoint(x: -46, y: -4 + 3 * sway), CGPoint(x: -62, y: -1 + 4 * sin(t * 3.1 - 0.9)),
            steps: 18
        )
        c.fill(Ink.tapered(tail, 8, 1.2), with: .color(pal.body))
        spade(c, tail, color: pal.bodyDark)

        // Tucked legs.
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: -10, y: 4), CGPoint(x: -15, y: 10), CGPoint(x: -21, y: 9)), 5, 2),
               with: .color(pal.bodyDark))
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: 9, y: 4), CGPoint(x: 12, y: 10), CGPoint(x: 16, y: 9)), 4, 1.6),
               with: .color(pal.bodyDark))

        // Body with a lighter belly.
        let body = Path(ellipseIn: CGRect(x: -21, y: -8.5, width: 42, height: 17))
        c.fill(body, with: .linearGradient(
            Gradient(colors: [pal.bodyDark, pal.body, pal.belly]),
            startPoint: CGPoint(x: 0, y: -8.5), endPoint: CGPoint(x: 0, y: 9)
        ))
        ridges(c, color: pal.bodyDark)

        // Neck and head.
        let neck = Ink.cubic(CGPoint(x: 14, y: -2), CGPoint(x: 21, y: -6), CGPoint(x: 26, y: -11), flyHeadBase, steps: 12)
        c.fill(Ink.tapered(neck, 11, 6.5), with: .linearGradient(
            Gradient(colors: [pal.bodyDark, pal.body]),
            startPoint: CGPoint(x: 20, y: -15), endPoint: CGPoint(x: 20, y: 0)
        ))
        drawHead(c, at: flyHeadBase, angle: flyHeadAngle, palette: pal, eyeClosed: false)

        // Near wing on top.
        drawWing(c, shoulder: CGPoint(x: 3, y: -6), flap: sin(flapPhase), size: 1,
                 fill: pal.wing, edge: pal.wingEdge, bone: pal.bodyDark)
    }

    /// Bat-like wing. flap = 1: fully up, -1: down below the body.
    static func drawWing(_ base: GraphicsContext, shoulder: CGPoint, flap f: Double, size k: CGFloat,
                         fill: Color, edge: Color, bone: Color) {
        var c = base
        c.translateBy(x: shoulder.x, y: shoulder.y)
        c.rotate(by: .degrees(-8 * f))
        let s = CGFloat(-0.55 + (f + 1) / 2 * 1.55)
        c.scaleBy(x: k, y: s * k)

        let wrist = CGPoint(x: 10, y: -22)
        let tips = [CGPoint(x: -2, y: -40), CGPoint(x: -14, y: -35), CGPoint(x: -24, y: -25), CGPoint(x: -28, y: -13)]
        let root = CGPoint(x: -14, y: -1)

        var m = Path()
        m.move(to: .zero)
        m.addQuadCurve(to: wrist, control: CGPoint(x: 9, y: -9))
        m.addLine(to: tips[0])
        m.addQuadCurve(to: tips[1], control: CGPoint(x: -5, y: -30))
        m.addQuadCurve(to: tips[2], control: CGPoint(x: -14, y: -25))
        m.addQuadCurve(to: tips[3], control: CGPoint(x: -20, y: -17))
        m.addQuadCurve(to: root, control: CGPoint(x: -18, y: -7))
        m.closeSubpath()
        c.fill(m, with: .linearGradient(
            Gradient(colors: [fill, fill.opacity(0.8)]),
            startPoint: .zero, endPoint: CGPoint(x: -12, y: -38)
        ))

        var bones = Path()
        for tip in tips {
            bones.move(to: wrist)
            bones.addLine(to: tip)
        }
        c.stroke(bones, with: .color(bone), lineWidth: 1.0)

        var lead = Path()
        lead.move(to: .zero)
        lead.addQuadCurve(to: wrist, control: CGPoint(x: 9, y: -9))
        lead.addLine(to: tips[0])
        c.stroke(lead, with: .color(bone), lineWidth: 2.2)
        c.stroke(lead, with: .color(edge.opacity(0.75)), lineWidth: 0.8)
    }

    /// Head facing right; `at` is where the neck joins.
    static func drawHead(_ base: GraphicsContext, at n: CGPoint, angle: Double, palette pal: DragonPalette, eyeClosed: Bool) {
        var c = base
        c.translateBy(x: n.x, y: n.y)
        c.rotate(by: .radians(angle))

        // Horns.
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: 1, y: -3.5), CGPoint(x: -4, y: -7), CGPoint(x: -9, y: -8)), 2.6, 0.4),
               with: .color(pal.horn))
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: 3.5, y: -4.2), CGPoint(x: 0, y: -9), CGPoint(x: -5, y: -11)), 2.2, 0.4),
               with: .color(pal.horn.opacity(0.85)))

        var head = Path()
        head.move(to: CGPoint(x: -2, y: -3.5))
        head.addQuadCurve(to: CGPoint(x: 8, y: -4.6), control: CGPoint(x: 3, y: -6))
        head.addQuadCurve(to: CGPoint(x: 17, y: -1.6), control: CGPoint(x: 13, y: -4))
        head.addQuadCurve(to: CGPoint(x: 18.5, y: 0.9), control: CGPoint(x: 19.2, y: -0.8))
        head.addQuadCurve(to: CGPoint(x: 8, y: 3.4), control: CGPoint(x: 14, y: 3))
        head.addQuadCurve(to: CGPoint(x: -2, y: 3.5), control: CGPoint(x: 2, y: 4.6))
        head.closeSubpath()
        c.fill(head, with: .linearGradient(
            Gradient(colors: [pal.bodyDark, pal.body]),
            startPoint: CGPoint(x: 0, y: -5), endPoint: CGPoint(x: 0, y: 4)
        ))

        var jaw = Path()
        jaw.move(to: CGPoint(x: 18, y: 1))
        jaw.addQuadCurve(to: CGPoint(x: 7, y: 1.8), control: CGPoint(x: 12, y: 2.1))
        c.stroke(jaw, with: .color(pal.bodyDark), lineWidth: 0.6)

        let eye = CGPoint(x: 8, y: -1.8)
        if eyeClosed {
            // Happy closed eye.
            var arc = Path()
            arc.move(to: CGPoint(x: eye.x - 1.7, y: eye.y + 0.2))
            arc.addQuadCurve(to: CGPoint(x: eye.x + 1.7, y: eye.y + 0.2), control: CGPoint(x: eye.x, y: eye.y - 1.6))
            c.stroke(arc, with: .color(pal.eye), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        } else {
            if pal.glowEye {
                c.fill(Ink.circle(eye, 3.2), with: .radialGradient(
                    Gradient(colors: [pal.eye.opacity(0.6), pal.eye.opacity(0)]),
                    center: eye, startRadius: 0, endRadius: 3.2
                ))
            }
            c.fill(Ink.ellipse(eye, 1.4, 1.0), with: .color(pal.eye))
        }
        c.fill(Ink.ellipse(nostrilLocal, 0.6, 0.4), with: .color(pal.bodyDark))
    }

    /// Spikes along the back.
    private static func ridges(_ c: GraphicsContext, color: Color) {
        var p = Path()
        for x in stride(from: -15.0, through: 9.0, by: 6.0) {
            let y0 = -8.5 * sqrt(max(0, 1 - (x / 21) * (x / 21)))
            p.move(to: CGPoint(x: x - 1.8, y: y0 + 0.8))
            p.addLine(to: CGPoint(x: x - 0.6, y: y0 - 3))
            p.addLine(to: CGPoint(x: x + 1.8, y: y0 + 0.8))
            p.closeSubpath()
        }
        c.fill(p, with: .color(color))
    }

    /// Spade at the end of the tail.
    static func spade(_ c: GraphicsContext, _ pts: [CGPoint], color: Color, size: CGFloat = 1) {
        guard pts.count > 3, let tip = pts.last else { return }
        let prev = pts[pts.count - 3]
        let angle = atan2(tip.y - prev.y, tip.x - prev.x)
        var s = Path()
        s.move(to: CGPoint(x: 6, y: 0))
        s.addLine(to: CGPoint(x: -1.5, y: 3.6))
        s.addLine(to: CGPoint(x: 0.5, y: 0))
        s.addLine(to: CGPoint(x: -1.5, y: -3.6))
        s.closeSubpath()
        let tr = CGAffineTransform(translationX: tip.x, y: tip.y).rotated(by: angle).scaledBy(x: size, y: size)
        c.fill(s.applying(tr), with: .color(color))
    }

    // MARK: - Resting

    /// Lying dragon (rest scene). Local origin: ground under the middle of the body.
    static func drawResting(_ base: GraphicsContext, rig: RestDragonRig, t: Double, eyesClosed: Bool, palette pal: DragonPalette) {
        var c = base
        c.concatenate(rig.pose.transform)
        let br = rig.breath

        // Body breathes: it grows upward from the ground.
        var bodyCtx = c
        bodyCtx.scaleBy(x: 1, y: 1 + 0.035 * br)
        bodyCtx.fill(Path(ellipseIn: CGRect(x: -17, y: -16.5, width: 34, height: 17)), with: .linearGradient(
            Gradient(colors: [pal.bodyDark, pal.body, pal.belly]),
            startPoint: CGPoint(x: 0, y: -16), endPoint: CGPoint(x: 0, y: 1)
        ))
        // Haunch and hind foot.
        bodyCtx.fill(Ink.ellipse(CGPoint(x: -9, y: -6), 7, 6), with: .linearGradient(
            Gradient(colors: [pal.body, pal.bodyDark]),
            startPoint: CGPoint(x: -9, y: -12), endPoint: CGPoint(x: -9, y: 0)
        ))
        c.fill(Ink.ellipse(CGPoint(x: -4, y: -0.9), 2.6, 1.2), with: .color(pal.bodyDark))

        // Tail curls along the ground in front.
        let tail = Ink.cubic(
            CGPoint(x: -15, y: -5), CGPoint(x: -33, y: -6),
            CGPoint(x: -29, y: 3.5), CGPoint(x: -6 + 2 * sin(t * 0.9), y: 3 + 0.4 * sin(t * 0.9 + 1)),
            steps: 20
        )
        c.fill(Ink.tapered(tail, 7, 1.4), with: .color(pal.body))
        spade(c, tail, color: pal.bodyDark, size: 0.8)

        // Front leg.
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: 11, y: -6), CGPoint(x: 14, y: -3), CGPoint(x: 16, y: -0.8)), 5, 3.4),
               with: .color(pal.bodyDark))
        c.fill(Ink.ellipse(CGPoint(x: 17, y: -1), 2.6, 1.3), with: .color(pal.bodyDark))

        // Folded wing on the back.
        let lift = CGFloat(br) * 0.8
        var wing = Path()
        wing.move(to: CGPoint(x: 10, y: -13))
        wing.addQuadCurve(to: CGPoint(x: -3, y: -27 - lift), control: CGPoint(x: 4, y: -25 - lift))
        wing.addQuadCurve(to: CGPoint(x: -21, y: -12), control: CGPoint(x: -14, y: -22 - lift))
        wing.addQuadCurve(to: CGPoint(x: -12, y: -11), control: CGPoint(x: -15, y: -15))
        wing.addQuadCurve(to: CGPoint(x: -4, y: -10), control: CGPoint(x: -7, y: -14))
        wing.addQuadCurve(to: CGPoint(x: 6, y: -10), control: CGPoint(x: 2, y: -13))
        wing.closeSubpath()
        c.fill(wing, with: .linearGradient(
            Gradient(colors: [pal.wing, pal.wingFar]),
            startPoint: CGPoint(x: -3, y: -27), endPoint: CGPoint(x: -3, y: -10)
        ))
        var wingBones = Path()
        wingBones.move(to: CGPoint(x: -3, y: -27 - lift)); wingBones.addLine(to: CGPoint(x: -12, y: -11))
        wingBones.move(to: CGPoint(x: -3, y: -27 - lift)); wingBones.addLine(to: CGPoint(x: -4, y: -10))
        c.stroke(wingBones, with: .color(pal.bodyDark.opacity(0.8)), lineWidth: 0.7)
        var wingEdge = Path()
        wingEdge.move(to: CGPoint(x: 10, y: -13))
        wingEdge.addQuadCurve(to: CGPoint(x: -3, y: -27 - lift), control: CGPoint(x: 4, y: -25 - lift))
        c.stroke(wingEdge, with: .color(pal.wingEdge.opacity(0.6)), lineWidth: 0.8)

        // Neck rises to the head.
        let neck = Ink.cubic(CGPoint(x: 10, y: -12), CGPoint(x: 15, y: -17), CGPoint(x: 16, y: -21), rig.headBase, steps: 12)
        c.fill(Ink.tapered(neck, 9.5, 6.2), with: .linearGradient(
            Gradient(colors: [pal.bodyDark, pal.body]),
            startPoint: CGPoint(x: 18, y: -26), endPoint: CGPoint(x: 10, y: -10)
        ))
        drawHead(c, at: rig.headBase, angle: rig.headAngle, palette: pal, eyeClosed: eyesClosed)
    }
}

/// Lying dragon "skeleton": where the head is, so Daenerys's hand can find it.
struct RestDragonRig {
    let pose: DragonPose
    let breath: Double
    let headBase: CGPoint
    let headAngle: Double

    /// lift 0...1: how much the dragon pushes its head up into the hand.
    init(base: CGPoint, scale: CGFloat, t: Double, lift: Double) {
        pose = DragonPose(position: base, angle: 0, scale: scale, flip: -1)
        breath = sin(t * 2 * .pi / 3.3)
        headBase = CGPoint(x: 15 + 0.6 * lift, y: -25 - 1.2 * lift)
        headAngle = 0.34 - 0.16 * lift
    }

    /// Point in head coordinates → screen.
    func headWorld(_ p: CGPoint) -> CGPoint {
        let head = CGAffineTransform(translationX: headBase.x, y: headBase.y).rotated(by: headAngle)
        return pose.world(p.applying(head))
    }
}

/// Tiny flying dragon in the collapsed island.
struct MiniDragonView: View {
    let color: Color
    let paused: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 86_400)
            Canvas { c, size in
                let bob = CGFloat(sin(t * 2 * .pi * 0.9)) * 0.8
                let pose = DragonPose(
                    position: CGPoint(x: size.width * 0.46, y: size.height * 0.66 + bob),
                    angle: 0, scale: size.width / 120, flip: -1
                )
                DragonPainter.drawFlying(c, pose: pose, flapPhase: t * 2 * .pi * (paused ? 0.6 : 1.6), t: t,
                                         palette: .mono(color))
            }
        }
        .frame(width: 36, height: 22)
    }
}
