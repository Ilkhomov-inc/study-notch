import SwiftUI
import StudyNookCore

/// Shortcuts for placing dragons in scenes.
enum DragonKit {
    /// Size of a flying dragon in the scene, by chapter (they grow through the story).
    static func size(_ ch: Chapter) -> CGFloat {
        switch ch {
        case .birth: 0.12
        case .qarth: 0.16
        case .astapor: 0.22
        case .vaesDothrak: 0.30
        case .meereen: 0.40
        case .sailing: 0.44
        case .goldenRoad: 0.48
        case .beyondWall, .winterfell, .rhaegal, .kingsLanding, .epilogue: 0.52
        }
    }

    /// `climb` > 0 = nose up, in radians.
    static func fly(_ c: GraphicsContext, at p: CGPoint, scale: CGFloat, climb: Double = 0, facing: CGFloat = -1,
                    t: Double, palette: DragonPalette, hz: Double = 1.7, offset: Double = 0) {
        let angle = facing < 0 ? climb : -climb
        let pose = DragonPose(position: p, angle: angle, scale: scale, flip: facing)
        DragonPainter.drawFlying(c, pose: pose, flapPhase: t * 2 * .pi * hz + offset, t: t + offset, palette: palette)
    }

    /// A dragon in the air with a gentle hover, from a base point.
    static func hover(_ c: GraphicsContext, _ env: SceneEnv, at p: CGPoint, scale: CGFloat, facing: CGFloat = -1,
                      palette: DragonPalette, offset: Double = 0, climb: Double = 0) -> CGPoint {
        let q = CGPoint(x: p.x + CGFloat(sin(env.t * 0.7 + offset)) * 2.5 * env.u,
                        y: p.y + CGFloat(sin(env.t * 2 * .pi * 0.8 + offset)) * 2.2 * env.u)
        fly(c, at: q, scale: scale, climb: climb + sin(env.t * 0.7 + offset) * 0.05, facing: facing, t: env.t, palette: palette, offset: offset)
        return q
    }

    /// World point of the mouth of a flying dragon at `p`.
    static func mouth(at p: CGPoint, scale: CGFloat, climb: Double = 0, facing: CGFloat = -1) -> CGPoint {
        let angle = facing < 0 ? climb : -climb
        return DragonPainter.mouth(DragonPose(position: p, angle: angle, scale: scale, flip: facing))
    }

    /// A rider standing on the dragon's back.
    static func back(at p: CGPoint, scale: CGFloat, climb: Double = 0, facing: CGFloat = -1) -> CGPoint {
        let angle = facing < 0 ? climb : -climb
        return DragonPose(position: p, angle: angle, scale: scale, flip: facing).world(CGPoint(x: 6, y: -8))
    }

    /// Three eggs in a row: black-red, green-bronze, cream-gold.
    static func eggs(_ c: GraphicsContext, at p: CGPoint, u: CGFloat, t: Double, glow: Double = 0.4) {
        let cols: [(RGB, RGB)] = [
            (RGB(0.30, 0.07, 0.07), RGB(0.9, 0.35, 0.15)),
            (RGB(0.12, 0.30, 0.18), RGB(0.78, 0.62, 0.28)),
            (RGB(0.78, 0.70, 0.50), RGB(0.97, 0.84, 0.45)),
        ]
        for (i, col) in cols.enumerated() {
            let x = p.x + CGFloat(i - 1) * 8 * u
            let rect = CGRect(x: x - 3.2 * u, y: p.y - 9 * u, width: 6.4 * u, height: 9 * u)
            let shape = EggShape().path(in: rect)
            if glow > 0 {
                var g = c
                g.blendMode = .plusLighter
                g.fill(Ink.circle(CGPoint(x: x, y: p.y - 4.5 * u), 9 * u), with: .radialGradient(
                    Gradient(colors: [col.1.color(glow * (0.7 + 0.3 * sin(t * 1.5 + Double(i)))), col.1.color(0)]),
                    center: CGPoint(x: x, y: p.y - 4.5 * u), startRadius: 0, endRadius: 9 * u))
            }
            c.fill(shape, with: .linearGradient(Gradient(colors: [col.1.color(), col.0.color()]),
                                                startPoint: CGPoint(x: x - 2 * u, y: p.y - 9 * u), endPoint: CGPoint(x: x + 2 * u, y: p.y)))
            var scales = c
            scales.clip(to: shape)
            var arcs = Path()
            for row in 0..<4 {
                let y = p.y - 8 * u + CGFloat(row) * 2.1 * u
                for col in -1...1 {
                    let x2 = x + (CGFloat(col) * 2.2 + (row % 2 == 0 ? 0 : 1.1)) * u
                    arcs.move(to: CGPoint(x: x2 - 1.1 * u, y: y))
                    arcs.addQuadCurve(to: CGPoint(x: x2 + 1.1 * u, y: y), control: CGPoint(x: x2, y: y + 1.5 * u))
                }
            }
            scales.stroke(arcs, with: .color(.white.opacity(0.25)), lineWidth: 0.4 * u)
        }
    }

    /// A tiny sitting dragon (baby), used on shoulders and laps.
    static func sitting(_ c: GraphicsContext, base: CGPoint, scale: CGFloat, t: Double, palette: DragonPalette, facing: CGFloat = -1, eyesClosed: Bool = false) {
        var rig = RestDragonRig(base: base, scale: scale, t: t, lift: 0)
        if facing > 0 {
            rig = RestDragonRig(base: base, scale: scale, t: t, lift: 0, mirrored: true)
        }
        DragonPainter.drawResting(c, rig: rig, t: t, eyesClosed: eyesClosed, palette: palette)
    }
}
