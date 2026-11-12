import SwiftUI

/// Pre-built silhouettes, built once. Facing right, origin at the feet, y goes up as negative.
/// Crowds draw these with one fill per figure, which keeps armies cheap.
enum Stamps {
    private static func leg(_ x: CGFloat, hipY: CGFloat, swing: CGFloat, width: CGFloat) -> Path {
        Ink.tapered([CGPoint(x: x, y: hipY), CGPoint(x: x + swing * 5, y: -0.5)], width, width * 0.7)
    }

    /// Horse with a rider, 4 gallop frames.
    static let rider: [Path] = (0..<4).map { makeHorse($0, withRider: true) }
    /// Riderless horse (for a hero rider drawn on top).
    static let horse: [Path] = (0..<4).map { makeHorse($0, withRider: false) }

    private static func makeHorse(_ f: Int, withRider: Bool) -> Path {
        let ph = Double(f) / 4 * 2 * .pi
        var p = Path()
        p.addPath(Path(ellipseIn: CGRect(x: -9.5, y: -15.5, width: 19, height: 8.6)))
        p.addPath(Ink.tapered([CGPoint(x: 6, y: -13.5), CGPoint(x: 11, y: -20), CGPoint(x: 15.5, y: -19.3)], 4.4, 2.6))
        p.addPath(Ink.tapered([CGPoint(x: -8, y: -13), CGPoint(x: -13, y: -9 + CGFloat(sin(ph)) * 1.5)], 2.6, 0.6))
        let swings: [(CGFloat, Double)] = [(6.5, 0), (4, 0.6), (-4, 2.2), (-6.5, 2.8)]
        for (x, off) in swings {
            p.addPath(leg(x, hipY: -9, swing: CGFloat(sin(ph + off)) * 0.9, width: 1.9))
        }
        if withRider {
            p.addPath(Ink.tapered([CGPoint(x: 0, y: -15), CGPoint(x: 0.6, y: -24)], 3.4, 3.0))
            p.addPath(Ink.circle(CGPoint(x: 0.8, y: -26.2), 2.0))
            p.addPath(Ink.tapered([CGPoint(x: 1, y: -21), CGPoint(x: 6, y: -28)], 0.9, 0.5))
        }
        return p
    }

    /// Foot soldier with a spear, 4 walking frames.
    static let soldier: [Path] = (0..<4).map { f in
        let ph = Double(f) / 4 * 2 * .pi
        var p = Path()
        p.addPath(leg(-0.8, hipY: -8, swing: CGFloat(sin(ph)), width: 1.8))
        p.addPath(leg(0.8, hipY: -8, swing: CGFloat(-sin(ph)), width: 1.8))
        p.addPath(Ink.tapered([CGPoint(x: 0, y: -8), CGPoint(x: 0, y: -15)], 4.2, 4.6))
        p.addPath(Ink.circle(CGPoint(x: 0.2, y: -17), 1.9))
        p.addPath(Ink.tapered([CGPoint(x: 3, y: -2), CGPoint(x: 3.2, y: -22)], 0.6, 0.6))
        p.addPath(Path { $0.move(to: CGPoint(x: 2.4, y: -22)); $0.addLine(to: CGPoint(x: 3.2, y: -25)); $0.addLine(to: CGPoint(x: 4, y: -22)); $0.closeSubpath() })
        return p
    }

    /// Unsullied: soldier + round shield and a plumed helmet.
    static let unsullied: [Path] = soldier.map { base in
        var p = base
        p.addPath(Ink.ellipse(CGPoint(x: 2.6, y: -11), 2.6, 3.4))
        p.addPath(Path { $0.move(to: CGPoint(x: -0.2, y: -18.6)); $0.addLine(to: CGPoint(x: 0.4, y: -21.6)); $0.addLine(to: CGPoint(x: 1, y: -18.6)); $0.closeSubpath() })
        return p
    }

    /// Wight: hunched, arms forward, 4 frames.
    static let wight: [Path] = (0..<4).map { f in
        let ph = Double(f) / 4 * 2 * .pi
        var p = Path()
        p.addPath(leg(-0.8, hipY: -7.5, swing: CGFloat(sin(ph)) * 0.8, width: 1.7))
        p.addPath(leg(0.8, hipY: -7.5, swing: CGFloat(-sin(ph)) * 0.8, width: 1.7))
        p.addPath(Ink.tapered([CGPoint(x: -0.5, y: -7.5), CGPoint(x: 1.2, y: -14)], 3.8, 4.2))
        p.addPath(Ink.circle(CGPoint(x: 2.6, y: -15.6), 1.8))
        p.addPath(Ink.tapered([CGPoint(x: 1.5, y: -13), CGPoint(x: 6.5, y: -12 + CGFloat(sin(ph)) * 1)], 1.0, 0.7))
        return p
    }

    /// Kneeling figure (the Dothraki bow to Daenerys).
    static let kneeler: Path = {
        var p = Path()
        // Shin on the ground, thigh up, torso bowed forward, head down, arm reaching to the ground.
        p.addPath(Ink.tapered([CGPoint(x: -5, y: -1), CGPoint(x: 0, y: -1)], 2, 2))
        p.addPath(Ink.tapered([CGPoint(x: 0, y: -1.2), CGPoint(x: 1, y: -6)], 2.6, 3))
        p.addPath(Ink.tapered([CGPoint(x: 1, y: -6), CGPoint(x: 5.5, y: -9.5)], 4.4, 3.6))
        p.addPath(Ink.circle(CGPoint(x: 8, y: -8.2), 1.9))
        p.addPath(Ink.tapered([CGPoint(x: 5, y: -8), CGPoint(x: 9, y: -2)], 1.2, 0.8))
        return p
    }()
}

enum Crowd {
    enum Kind { case riders, soldiers, unsullied, wights, kneelers }

    /// A crowd marching along a band of the scene. `depth` 0 = far (small, high), 1 = near (big, low).
    /// - speed: points per second at near depth, negative walks left.
    static func draw(_ c: GraphicsContext, _ env: SceneEnv, kind: Kind, count: Int, xRange: ClosedRange<CGFloat>,
                     yFar: CGFloat, yNear: CGFloat, sFar: CGFloat, sNear: CGFloat,
                     speed: CGFloat, far: RGB, near: RGB, seed: Int = 0, standing: Bool = false) {
        let n = min(count, 60)
        let span = xRange.upperBound - xRange.lowerBound
        var items: [(z: Double, x: CGFloat, y: CGFloat, s: CGFloat, idx: Int)] = []
        items.reserveCapacity(n)
        for i in 0..<n {
            let z = M.rand(i, seed + 11)
            let s = M.lerp(sFar, sNear, CGFloat(z)) * env.u
            let y = M.lerp(yFar, yNear, CGFloat(z))
            let drift = standing ? 0 : speed * s / max(0.001, sNear * env.u) * CGFloat(env.t)
            var x = CGFloat(M.rand(i, seed + 12)) * span + drift
            x = x.truncatingRemainder(dividingBy: span)
            if x < 0 { x += span }
            items.append((z, xRange.lowerBound + x, y, s, i))
        }
        items.sort { $0.z < $1.z }
        let dir: CGFloat = speed < 0 ? -1 : 1
        for it in items {
            let color = RGB.lerp(far, near, it.z)
            let frame = standing ? 0 : Int(env.t * (kind == .riders ? 7 : 4) + Double(it.idx) * 0.37) & 3
            let stamp: Path
            switch kind {
            case .riders: stamp = Stamps.rider[frame]
            case .soldiers: stamp = Stamps.soldier[standing ? 0 : frame]
            case .unsullied: stamp = Stamps.unsullied[standing ? 0 : frame]
            case .wights: stamp = Stamps.wight[frame]
            case .kneelers: stamp = Stamps.kneeler
            }
            let t = CGAffineTransform(translationX: it.x, y: it.y).scaledBy(x: it.s * dir, y: it.s)
            c.fill(stamp.applying(t), with: .color(color.color()))
        }
    }

    /// Ranks standing in a block (Unsullied, wights).
    static func formation(_ c: GraphicsContext, _ env: SceneEnv, kind: Kind, cols: Int, rows: Int, origin: CGPoint,
                          dx: CGFloat, dy: CGFloat, scale: CGFloat, color: RGB, dir: CGFloat = 1, march: Bool = true) {
        for r in 0..<rows {
            for col in 0..<cols {
                let k = r * cols + col
                let depth = CGFloat(r) / CGFloat(max(1, rows - 1))
                let s = scale * env.u * (0.8 + 0.2 * depth)
                let p = CGPoint(x: origin.x + CGFloat(col) * dx * env.u + CGFloat(r % 2) * dx * 0.5 * env.u, y: origin.y + CGFloat(r) * dy * env.u)
                let frame = march ? (Int(env.t * 3.5) & 3) : 0
                let stamp: Path = kind == .wights ? Stamps.wight[(frame + k) & 3] : Stamps.unsullied[frame]
                let tr = CGAffineTransform(translationX: p.x, y: p.y).scaledBy(x: s * dir, y: s)
                c.fill(stamp.applying(tr), with: .color(color.color(0.8 + 0.2 * Double(depth))))
            }
        }
    }
}

enum Ships {
    /// A sailing ship, facing right (set `dir` -1 to face left). `scale` 1 = about 46 points long.
    static func draw(_ c: GraphicsContext, at p: CGPoint, scale: CGFloat, t: Double, seed: Int = 0,
                     hull: RGB, sail: RGB, flag: RGB? = nil, horses: Bool = false, dir: CGFloat = 1, burning: Double = 0) {
        var g = c
        let roll = sin(t * 1.1 + Double(seed)) * 0.04
        g.translateBy(x: p.x, y: p.y + CGFloat(sin(t * 1.5 + Double(seed) * 2)) * 1.2 * scale)
        g.rotate(by: .radians(roll))
        g.scaleBy(x: dir * scale, y: scale)

        // Hull.
        var h = Path()
        h.move(to: CGPoint(x: -23, y: -7))
        h.addQuadCurve(to: CGPoint(x: -17, y: 3), control: CGPoint(x: -22, y: 1.5))
        h.addLine(to: CGPoint(x: 15, y: 3))
        h.addQuadCurve(to: CGPoint(x: 25, y: -9), control: CGPoint(x: 23, y: -1))
        h.addLine(to: CGPoint(x: 18, y: -6))
        h.addLine(to: CGPoint(x: -17, y: -6))
        h.closeSubpath()
        g.fill(h, with: .linearGradient(Gradient(colors: [hull.color(), RGB(hull.r * 0.55, hull.g * 0.55, hull.b * 0.55).color()]),
                                        startPoint: CGPoint(x: 0, y: -8), endPoint: CGPoint(x: 0, y: 3)))
        g.stroke(Path { $0.move(to: CGPoint(x: -19, y: -3)); $0.addLine(to: CGPoint(x: 18, y: -3)) },
                 with: .color(.white.opacity(0.12)), lineWidth: 0.5)

        // Horses standing on deck.
        if horses {
            for i in 0..<4 {
                let x = CGFloat(-12 + i * 7)
                var hp = Path()
                hp.addPath(Path(ellipseIn: CGRect(x: x - 2.6, y: -11.3, width: 5.2, height: 2.6)))
                hp.addPath(Ink.tapered([CGPoint(x: x + 1.8, y: -10.6), CGPoint(x: x + 3.2, y: -13.6), CGPoint(x: x + 4.6, y: -13.3)], 1.5, 0.9))
                hp.addPath(Ink.tapered([CGPoint(x: x - 1.8, y: -9.5), CGPoint(x: x - 1.9, y: -6)], 0.7, 0.6))
                hp.addPath(Ink.tapered([CGPoint(x: x + 1.5, y: -9.5), CGPoint(x: x + 1.6, y: -6)], 0.7, 0.6))
                g.fill(hp, with: .color(RGB(0.28 + 0.1 * M.rand(i, seed), 0.2, 0.14).color()))
            }
        }

        // Mast, sail, flag.
        g.stroke(Path { $0.move(to: CGPoint(x: 0, y: -6)); $0.addLine(to: CGPoint(x: 0, y: -42)) },
                 with: .color(RGB(0.22, 0.16, 0.12).color()), lineWidth: 1.2)
        let bulge = CGFloat(sin(t * 1.3 + Double(seed))) * 0.8
        var s = Path()
        s.move(to: CGPoint(x: 0.5, y: -40))
        s.addQuadCurve(to: CGPoint(x: 15, y: -16), control: CGPoint(x: 16 + bulge, y: -30))
        s.addQuadCurve(to: CGPoint(x: 0.5, y: -15), control: CGPoint(x: 7, y: -13 + bulge))
        s.closeSubpath()
        g.fill(s, with: .linearGradient(Gradient(colors: [sail.color(), RGB(sail.r * 0.8, sail.g * 0.8, sail.b * 0.8).color()]),
                                        startPoint: CGPoint(x: 0, y: -40), endPoint: CGPoint(x: 12, y: -14)))
        var s2 = Path()
        s2.move(to: CGPoint(x: -0.5, y: -38))
        s2.addQuadCurve(to: CGPoint(x: -12, y: -18), control: CGPoint(x: -13 - bulge, y: -29))
        s2.addQuadCurve(to: CGPoint(x: -0.5, y: -17), control: CGPoint(x: -6, y: -15))
        s2.closeSubpath()
        g.fill(s2, with: .color(RGB(sail.r * 0.9, sail.g * 0.9, sail.b * 0.9).color()))
        if let flag {
            var f = Path()
            let w = CGFloat(sin(t * 5 + Double(seed))) * 1.2
            f.move(to: CGPoint(x: 0, y: -42))
            f.addQuadCurve(to: CGPoint(x: 9, y: -41 + w), control: CGPoint(x: 5, y: -45))
            f.addLine(to: CGPoint(x: 0, y: -38))
            f.closeSubpath()
            g.fill(f, with: .color(flag.color()))
        }
        if burning > 0.02 {
            Fire.flames(g, x0: -14, x1: 14, y: -6, height: 22, intensity: burning, t: t, seed: seed + 50, u: 1.6)
        }
    }
}
