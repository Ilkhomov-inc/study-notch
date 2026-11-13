import SwiftUI
import StudyNookCore

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

    /// Green and bronze.
    static let rhaegal = DragonPalette(
        body: Color(red: 0.20, green: 0.38, blue: 0.20),
        bodyDark: Color(red: 0.07, green: 0.17, blue: 0.10),
        belly: Color(red: 0.72, green: 0.62, blue: 0.30),
        wing: Color(red: 0.26, green: 0.46, blue: 0.24),
        wingFar: Color(red: 0.12, green: 0.26, blue: 0.14),
        wingEdge: Color(red: 0.86, green: 0.66, blue: 0.30),
        eye: Color(red: 1.0, green: 0.78, blue: 0.3),
        horn: Color(red: 0.82, green: 0.66, blue: 0.34),
        glowEye: true
    )

    /// Cream and gold.
    static let viserion = DragonPalette(
        body: Color(red: 0.88, green: 0.82, blue: 0.64),
        bodyDark: Color(red: 0.62, green: 0.54, blue: 0.38),
        belly: Color(red: 0.97, green: 0.92, blue: 0.78),
        wing: Color(red: 0.92, green: 0.84, blue: 0.62),
        wingFar: Color(red: 0.70, green: 0.62, blue: 0.44),
        wingEdge: Color(red: 0.96, green: 0.78, blue: 0.36),
        eye: Color(red: 0.55, green: 0.36, blue: 0.12),
        horn: Color(red: 0.96, green: 0.8, blue: 0.4),
        glowEye: false
    )

    /// Undead Viserion: ice-white with blue eyes.
    static let undead = DragonPalette(
        body: Color(red: 0.66, green: 0.78, blue: 0.88),
        bodyDark: Color(red: 0.30, green: 0.42, blue: 0.55),
        belly: Color(red: 0.82, green: 0.9, blue: 0.96),
        wing: Color(red: 0.55, green: 0.70, blue: 0.84),
        wingFar: Color(red: 0.34, green: 0.46, blue: 0.62),
        wingEdge: Color(red: 0.7, green: 0.9, blue: 1.0),
        eye: Color(red: 0.4, green: 0.8, blue: 1.0),
        horn: Color(red: 0.8, green: 0.92, blue: 1.0),
        glowEye: true
    )

    /// A memory of a fallen dragon: translucent and pale.
    static func ghost(_ d: Dragon) -> DragonPalette {
        let tint = Color(red: 0.75, green: 0.85, blue: 1.0)
        let base = d == .viserion ? DragonPalette.viserion : DragonPalette.rhaegal
        return DragonPalette(body: tint.opacity(0.42), bodyDark: tint.opacity(0.3), belly: tint.opacity(0.5),
                             wing: tint.opacity(0.32), wingFar: tint.opacity(0.2), wingEdge: base.wingEdge.opacity(0.5),
                             eye: tint.opacity(0.8), horn: tint.opacity(0.6), glowEye: false)
    }

    static func of(_ d: Dragon) -> DragonPalette {
        switch d {
        case .drogon: .drogon
        case .rhaegal: .rhaegal
        case .viserion: .viserion
        }
    }

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
    static let flyHeadBase = CGPoint(x: 31, y: -22)
    static let flyHeadAngle = 0.2
    static let mouthLocal = CGPoint(x: 18.5, y: 0.9)
    static let nostrilLocal = CGPoint(x: 16, y: -1.1)

    /// World position of the mouth of a flying dragon (fire comes out of here).
    static func mouth(_ pose: DragonPose) -> CGPoint {
        let head = CGAffineTransform(translationX: flyHeadBase.x, y: flyHeadBase.y).rotated(by: flyHeadAngle)
        return pose.world(mouthLocal.applying(head))
    }

    // MARK: - Shared geometry (facing right, origin in the middle of the body, y down)

    /// Thick chest in front, slimmer hips behind.
    static func bodyPath() -> Path {
        var b = Path()
        b.move(to: CGPoint(x: -22, y: -1))
        b.addQuadCurve(to: CGPoint(x: -2, y: -10), control: CGPoint(x: -14, y: -9))
        b.addQuadCurve(to: CGPoint(x: 17, y: -7), control: CGPoint(x: 9, y: -12.5))
        b.addQuadCurve(to: CGPoint(x: 19, y: 4), control: CGPoint(x: 24, y: -2))
        b.addQuadCurve(to: CGPoint(x: 0, y: 9.5), control: CGPoint(x: 12, y: 10.5))
        b.addQuadCurve(to: CGPoint(x: -22, y: 3), control: CGPoint(x: -13, y: 8.5))
        b.closeSubpath()
        return b
    }

    /// The neck rises in an S toward the head, so the head is carried high like a horse's, not in line like a lizard's.
    static func neckPoints() -> [CGPoint] {
        Ink.cubic(CGPoint(x: 13, y: -4), CGPoint(x: 23, y: -7), CGPoint(x: 23, y: -19), flyHeadBase, steps: 14)
    }

    static func tailPoints(t: Double) -> [CGPoint] {
        let sway = sin(t * 3.1)
        return Ink.cubic(CGPoint(x: -18, y: 0), CGPoint(x: -34, y: 5),
                         CGPoint(x: -46, y: -5 + 3 * sway), CGPoint(x: -60, y: -1 + 4 * sin(t * 3.1 - 0.9)), steps: 18)
    }

    /// Wing membrane in wing space: shoulder at the origin, the open wing reaching up (negative y) and back.
    static let wingElbow = CGPoint(x: 12, y: -14)
    static let wingWrist = CGPoint(x: 4, y: -31)
    static let wingTips = [CGPoint(x: -10, y: -50), CGPoint(x: -27, y: -45), CGPoint(x: -39, y: -32), CGPoint(x: -45, y: -16)]

    static func wingPath() -> Path {
        var m = Path()
        m.move(to: .zero)
        m.addQuadCurve(to: wingElbow, control: CGPoint(x: 8, y: -4))
        m.addQuadCurve(to: wingWrist, control: CGPoint(x: 13, y: -25))
        m.addLine(to: wingTips[0])
        m.addQuadCurve(to: wingTips[1], control: CGPoint(x: -16, y: -39))
        m.addQuadCurve(to: wingTips[2], control: CGPoint(x: -28, y: -33))
        m.addQuadCurve(to: wingTips[3], control: CGPoint(x: -34, y: -21))
        m.addQuadCurve(to: CGPoint(x: -22, y: 1), control: CGPoint(x: -30, y: -6))
        m.closeSubpath()
        return m
    }

    /// How open the wing is in the stroke: 1 fully up, about -0.7 fully down.
    /// It moves quickly through the flat middle position, so the wing almost never reads as a thin line.
    static func wingLift(_ phase: Double) -> CGFloat {
        let f = sin(phase)
        let s = (f < 0 ? -1.0 : 1.0) * pow(abs(f), 0.55)
        return CGFloat(s >= 0 ? s : s * 0.7)
    }

    static func wingTransform(shoulder: CGPoint, lift s: CGFloat, size k: CGFloat) -> CGAffineTransform {
        let sy = s >= 0 ? max(0.16, s) : min(-0.16, s)
        return CGAffineTransform(translationX: shoulder.x, y: shoulder.y)
            .rotated(by: -0.18 * Double(s))
            .scaledBy(x: k, y: sy * k)
    }

    // MARK: - Tiny silhouette

    /// One flat color, a single fill, no gradients: cheap enough for the collapsed island.
    static func drawSilhouette(_ c: GraphicsContext, pose: DragonPose, flapPhase: Double, color: Color) {
        var g = c
        g.concatenate(pose.transform)
        let s = wingLift(flapPhase)
        var p = bodyPath()
        p.addPath(Ink.tapered(tailPoints(t: 0), 9, 1.5))
        p.addPath(Ink.tapered(neckPoints(), 11, 6.5))
        p.addEllipse(in: CGRect(x: flyHeadBase.x - 2, y: flyHeadBase.y - 4.5, width: 19, height: 8))
        p.addPath(wingPath().applying(wingTransform(shoulder: CGPoint(x: 3, y: -7), lift: s, size: 1)))
        p.addPath(wingPath().applying(wingTransform(shoulder: CGPoint(x: -3, y: -8), lift: wingLift(flapPhase - 0.45), size: 0.9)))
        g.fill(p, with: .color(color))
    }

    // MARK: - Flying

    /// Dragon in flight, about 110 units from snout to tail, wingspan larger than the body.
    static func drawFlying(_ base: GraphicsContext, pose: DragonPose, flapPhase: Double, t: Double, palette pal: DragonPalette) {
        var c = base
        c.concatenate(pose.transform)

        // Far wing, behind everything, a little late in the stroke.
        drawWing(c, shoulder: CGPoint(x: -3, y: -8), lift: wingLift(flapPhase - 0.45), size: 0.9,
                 fill: pal.wingFar, edge: pal.wingFar, bone: pal.bodyDark)

        // Tail with spikes and a spade.
        let tail = tailPoints(t: t)
        c.fill(Ink.tapered(tail, 9.5, 1.2), with: .linearGradient(
            Gradient(colors: [pal.bodyDark, pal.body]), startPoint: CGPoint(x: -30, y: -6), endPoint: CGPoint(x: -30, y: 6)))
        var tailSpikes = Path()
        for k in stride(from: 2, to: tail.count - 4, by: 3) {
            let a = tail[k], b = tail[k + 1]
            let w = 3.6 * (1 - CGFloat(k) / CGFloat(tail.count))
            tailSpikes.move(to: CGPoint(x: a.x - 1, y: a.y - 2.2))
            tailSpikes.addLine(to: CGPoint(x: (a.x + b.x) / 2 - 0.6, y: a.y - 2.4 - w - 1.2))
            tailSpikes.addLine(to: CGPoint(x: b.x + 0.6, y: b.y - 2.2))
            tailSpikes.closeSubpath()
        }
        c.fill(tailSpikes, with: .color(pal.bodyDark))
        spade(c, tail, color: pal.bodyDark)

        // Hind leg: a strong thigh, the shin tucked back, claws.
        c.fill(Ink.ellipse(CGPoint(x: -12, y: 3), 7, 5.5), with: .linearGradient(
            Gradient(colors: [pal.body, pal.bodyDark]), startPoint: CGPoint(x: -12, y: -2), endPoint: CGPoint(x: -12, y: 8)))
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: -14, y: 6), CGPoint(x: -18, y: 10), CGPoint(x: -23, y: 9.5)), 4.4, 2), with: .color(pal.bodyDark))
        claws(c, at: CGPoint(x: -23, y: 9.5), color: pal.horn)

        // Body.
        let body = bodyPath()
        c.fill(body, with: .linearGradient(
            Gradient(colors: [pal.bodyDark, pal.body, pal.belly]),
            startPoint: CGPoint(x: 0, y: -11), endPoint: CGPoint(x: 0, y: 10)))
        c.stroke(body, with: .color(pal.bodyDark.opacity(0.7)), lineWidth: 0.6)
        var shine = c
        shine.blendMode = .plusLighter
        shine.fill(Ink.ellipse(CGPoint(x: 3, y: -6.5), 9, 2.2), with: .color(.white.opacity(0.1)))
        // Spikes along the back.
        var spikes = Path()
        let back1 = QuadCurve(p0: CGPoint(x: -22, y: -1), c: CGPoint(x: -14, y: -9), p1: CGPoint(x: -2, y: -10))
        let back2 = QuadCurve(p0: CGPoint(x: -2, y: -10), c: CGPoint(x: 9, y: -12.5), p1: CGPoint(x: 17, y: -7))
        for q in [back1.point(0.35), back1.point(0.65), back1.point(0.95), back2.point(0.3), back2.point(0.6)] {
            spikes.move(to: CGPoint(x: q.x - 1.8, y: q.y + 0.8))
            spikes.addLine(to: CGPoint(x: q.x - 0.8, y: q.y - 3.4))
            spikes.addLine(to: CGPoint(x: q.x + 1.8, y: q.y + 0.8))
            spikes.closeSubpath()
        }
        c.fill(spikes, with: .color(pal.bodyDark))
        // Belly plates, scales, a rim of light along the back.
        var plates = Path()
        for i in 0..<7 {
            let x = -14 + CGFloat(i) * 4.4
            plates.move(to: CGPoint(x: x, y: 3.5))
            plates.addQuadCurve(to: CGPoint(x: x + 2, y: 8.2), control: CGPoint(x: x + 2.6, y: 5.6))
        }
        c.stroke(plates, with: .color(pal.bodyDark.opacity(0.5)), lineWidth: 0.55)
        var scales = Path()
        for r in 0..<3 {
            for k in 0..<8 {
                let x = -16 + CGFloat(k) * 4.2 + (r % 2 == 0 ? 0 : 2.1), y = -6 + CGFloat(r) * 3
                scales.move(to: CGPoint(x: x - 1.3, y: y))
                scales.addQuadCurve(to: CGPoint(x: x + 1.3, y: y), control: CGPoint(x: x, y: y + 1.6))
            }
        }
        var bodyClip = c
        bodyClip.clip(to: body)
        bodyClip.stroke(scales, with: .color(pal.bodyDark.opacity(0.35)), lineWidth: 0.45)
        var rim = Path()
        rim.move(to: CGPoint(x: -20, y: -2))
        rim.addQuadCurve(to: CGPoint(x: 16, y: -7.5), control: CGPoint(x: 0, y: -13.5))
        c.stroke(rim, with: .color(pal.wingEdge.opacity(0.5)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))

        // Front leg tucked under the chest.
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: 11, y: 5), CGPoint(x: 14, y: 10), CGPoint(x: 17, y: 10)), 4.2, 1.8), with: .color(pal.bodyDark))
        claws(c, at: CGPoint(x: 17, y: 10), color: pal.horn)

        // Neck with a crest of small spikes, then the head.
        let neck = neckPoints()
        c.fill(Ink.tapered(neck, 11.5, 6.5), with: .linearGradient(
            Gradient(colors: [pal.bodyDark, pal.body, pal.belly]),
            startPoint: CGPoint(x: 26, y: -20), endPoint: CGPoint(x: 14, y: 2)))
        c.stroke(Ink.tapered(neck, 11.5, 6.5), with: .color(pal.bodyDark.opacity(0.6)), lineWidth: 0.5)
        var throat = Path()
        for k in stride(from: 3, to: neck.count - 1, by: 2) {
            let a = neck[k]
            throat.move(to: CGPoint(x: a.x + 1.4, y: a.y + 2.9))
            throat.addLine(to: CGPoint(x: a.x + 3.4, y: a.y + 1.2))
        }
        c.stroke(throat, with: .color(pal.bodyDark.opacity(0.45)), lineWidth: 0.45)
        var crest = Path()
        for k in stride(from: 2, to: neck.count - 2, by: 3) {
            let a = neck[k]
            crest.move(to: CGPoint(x: a.x - 3.2, y: a.y - 2.2))
            crest.addLine(to: CGPoint(x: a.x - 4.8, y: a.y - 5))
            crest.addLine(to: CGPoint(x: a.x - 1.2, y: a.y - 3.6))
            crest.closeSubpath()
        }
        c.fill(crest, with: .color(pal.bodyDark))
        drawHead(c, at: flyHeadBase, angle: flyHeadAngle, palette: pal, eyeClosed: false)

        // Near wing on top.
        drawWing(c, shoulder: CGPoint(x: 3, y: -7), lift: wingLift(flapPhase), size: 1,
                 fill: pal.wing, edge: pal.wingEdge, bone: pal.bodyDark)
    }

    private static func claws(_ c: GraphicsContext, at foot: CGPoint, color: Color) {
        var p = Path()
        for k in 0..<3 {
            let x = foot.x - 1.2 + CGFloat(k) * 1.3
            p.move(to: CGPoint(x: x, y: foot.y))
            p.addQuadCurve(to: CGPoint(x: x - 1, y: foot.y + 3), control: CGPoint(x: x + 0.6, y: foot.y + 2))
            p.addLine(to: CGPoint(x: x + 0.8, y: foot.y))
        }
        c.fill(p, with: .color(color))
    }

    /// A bat-like wing. `lift` 1 = fully up, negative = below the body.
    static func drawWing(_ base: GraphicsContext, shoulder: CGPoint, lift s: CGFloat, size k: CGFloat,
                         fill: Color, edge: Color, bone: Color) {
        var c = base
        c.concatenate(wingTransform(shoulder: shoulder, lift: s, size: k))
        let m = wingPath()
        // The underside shows on the downstroke: a little darker.
        let top = s >= 0 ? fill : fill.opacity(0.82)
        c.fill(m, with: .linearGradient(Gradient(colors: [top, fill.opacity(0.72)]),
                                        startPoint: wingWrist, endPoint: CGPoint(x: -36, y: -24)))
        var veins = Path()
        for i in 0..<(wingTips.count - 1) {
            let a = wingTips[i], b = wingTips[i + 1]
            let start = CGPoint(x: wingWrist.x + (a.x - wingWrist.x) * 0.5, y: wingWrist.y + (a.y - wingWrist.y) * 0.5)
            let end = CGPoint(x: (a.x + b.x) / 2 + 2.5, y: (a.y + b.y) / 2 + 3.5)
            veins.move(to: start)
            veins.addQuadCurve(to: end, control: CGPoint(x: (start.x + end.x) / 2 - 2, y: (start.y + end.y) / 2 + 1))
            let start2 = CGPoint(x: wingWrist.x + (b.x - wingWrist.x) * 0.7, y: wingWrist.y + (b.y - wingWrist.y) * 0.7)
            veins.move(to: start2)
            veins.addLine(to: CGPoint(x: (start2.x + end.x) / 2, y: (start2.y + end.y) / 2 + 1))
        }
        c.stroke(veins, with: .color(bone.opacity(0.28)), lineWidth: 0.45)
        c.stroke(m, with: .color(edge.opacity(0.22)), lineWidth: 1.6)
        c.stroke(m, with: .color(bone.opacity(0.6)), lineWidth: 0.5)
        // Fingers with a soft glow, the arm bone, joints.
        var fingers = Path()
        for tip in wingTips {
            fingers.move(to: wingWrist)
            fingers.addQuadCurve(to: tip, control: CGPoint(x: (wingWrist.x + tip.x) / 2 + 2, y: (wingWrist.y + tip.y) / 2 + 3))
        }
        c.stroke(fingers, with: .color(edge.opacity(0.18)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        c.stroke(fingers, with: .color(bone), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
        var arm = Path()
        arm.move(to: .zero)
        arm.addQuadCurve(to: wingElbow, control: CGPoint(x: 8, y: -4))
        arm.addQuadCurve(to: wingWrist, control: CGPoint(x: 13, y: -25))
        c.stroke(arm, with: .color(bone), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
        c.stroke(arm, with: .color(edge.opacity(0.7)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        for joint in [wingElbow, wingWrist] { c.fill(Ink.circle(joint, 1.4), with: .color(bone)) }
        // Claw on the wrist.
        var claw = Path()
        claw.move(to: CGPoint(x: wingWrist.x - 1.2, y: wingWrist.y))
        claw.addQuadCurve(to: CGPoint(x: wingWrist.x + 4, y: wingWrist.y - 4.6), control: CGPoint(x: wingWrist.x + 1.8, y: wingWrist.y - 4.4))
        claw.addLine(to: CGPoint(x: wingWrist.x + 1.4, y: wingWrist.y + 0.8))
        claw.closeSubpath()
        c.fill(claw, with: .color(bone))
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

        var rings = Path()
        let hornPts = Ink.quad(CGPoint(x: 1, y: -3.5), CGPoint(x: -4, y: -7), CGPoint(x: -9, y: -8))
        for f in [0.25, 0.45, 0.65] as [CGFloat] {
            let p0 = hornPts[Int(f * CGFloat(hornPts.count - 1))]
            rings.move(to: CGPoint(x: p0.x - 0.5, y: p0.y - 0.9)); rings.addLine(to: CGPoint(x: p0.x + 0.5, y: p0.y + 0.9))
        }
        c.stroke(rings, with: .color(pal.bodyDark.opacity(0.5)), lineWidth: 0.35)
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

        c.stroke(head, with: .color(pal.bodyDark.opacity(0.7)), lineWidth: 0.5)
        var cheek = Path()
        for (x, y) in [(2.0, 0.5), (4.5, 1.3), (1.0, -1.6), (3.5, -1.0)] as [(CGFloat, CGFloat)] {
            cheek.move(to: CGPoint(x: x - 0.9, y: y)); cheek.addQuadCurve(to: CGPoint(x: x + 0.9, y: y), control: CGPoint(x: x, y: y + 1))
        }
        c.stroke(cheek, with: .color(pal.bodyDark.opacity(0.4)), lineWidth: 0.35)
        var jaw = Path()
        jaw.move(to: CGPoint(x: 18, y: 1))
        jaw.addQuadCurve(to: CGPoint(x: 7, y: 1.8), control: CGPoint(x: 12, y: 2.1))
        c.stroke(jaw, with: .color(pal.bodyDark), lineWidth: 0.6)
        c.stroke(jaw, with: .color(.white.opacity(0.6)), style: StrokeStyle(lineWidth: 0.5, dash: [0.5, 1.1]))
        var brow = Path()
        brow.move(to: CGPoint(x: 4.5, y: -3.4))
        brow.addQuadCurve(to: CGPoint(x: 11, y: -3.6), control: CGPoint(x: 8, y: -5.9))
        c.stroke(brow, with: .color(pal.bodyDark), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
        c.fill(Path { $0.move(to: CGPoint(x: -1, y: 2)); $0.addLine(to: CGPoint(x: -6.5, y: 5.8)); $0.addLine(to: CGPoint(x: 1.5, y: 4)); $0.closeSubpath() }, with: .color(pal.horn))

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
            c.fill(Ink.ellipse(eye, 0.3, 0.9), with: .color(.black.opacity(0.85)))
        }
        c.fill(Ink.ellipse(nostrilLocal, 0.6, 0.4), with: .color(pal.bodyDark))
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
        // Spikes along the back.
        var spikes = Path()
        for k in 0..<7 {
            let x = -13 + CGFloat(k) * 4.4
            let y = -8 - 8.5 * sqrt(max(0, 1 - (x / 17) * (x / 17)))
            spikes.move(to: CGPoint(x: x - 1.5, y: y + 0.8))
            spikes.addLine(to: CGPoint(x: x + 0.2, y: y - 3.6))
            spikes.addLine(to: CGPoint(x: x + 1.7, y: y + 0.8))
            spikes.closeSubpath()
        }
        bodyCtx.fill(spikes, with: .color(pal.bodyDark))
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
    init(base: CGPoint, scale: CGFloat, t: Double, lift: Double, mirrored: Bool = false) {
        pose = DragonPose(position: base, angle: 0, scale: scale, flip: mirrored ? 1 : -1)
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
        // The tiny dragon in the collapsed island runs at 6 fps: it is the only thing animating there.
        TimelineView(.animation(minimumInterval: 1.0 / 6.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 86_400)
            Canvas { c, size in
                let bob = CGFloat(sin(t * 2 * .pi * 0.9)) * 0.8
                let pose = DragonPose(
                    position: CGPoint(x: size.width * 0.46, y: size.height * 0.66 + bob),
                    angle: 0, scale: size.width / 120, flip: -1
                )
                DragonPainter.drawSilhouette(c, pose: pose, flapPhase: t * 2 * .pi * (paused ? 0.6 : 1.4), color: color)
            }
        }
        .frame(width: 36, height: 22)
    }
}
