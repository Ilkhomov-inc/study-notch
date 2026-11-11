import SwiftUI

/// Small math helpers shared by the scenes.
enum M {
    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t))
    }

    static func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }

    static func fract(_ x: Double) -> Double { x - floor(x) }

    static func smoothstep(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
        let t = clamp01((x - e0) / (e1 - e0))
        return t * t * (3 - 2 * t)
    }

    static func easeInOut(_ x: Double) -> Double {
        x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
    }

    static func easeOutBack(_ x: Double) -> Double {
        let c1 = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }

    /// Stable pseudo-random number in 0..<1 for particle `i`.
    static func rand(_ i: Int, _ salt: Int = 0) -> Double {
        let x = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return x - floor(x)
    }
}

/// RGB color that can be interpolated (SwiftUI Color cannot).
struct RGB {
    var r: Double, g: Double, b: Double

    init(_ r: Double, _ g: Double, _ b: Double) {
        self.r = r; self.g = g; self.b = b
    }

    func color(_ opacity: Double = 1) -> Color {
        Color(red: r, green: g, blue: b, opacity: opacity)
    }

    static func lerp(_ a: RGB, _ b: RGB, _ t: Double) -> RGB {
        RGB(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t)
    }

    /// Interpolates between keyframes sorted by position.
    static func keyframes(_ stops: [(Double, RGB)], _ t: Double) -> RGB {
        guard let first = stops.first, let last = stops.last else { return RGB(0, 0, 0) }
        if t <= first.0 { return first.1 }
        if t >= last.0 { return last.1 }
        for i in 0..<(stops.count - 1) where t <= stops[i + 1].0 {
            let (p0, c0) = stops[i], (p1, c1) = stops[i + 1]
            return lerp(c0, c1, (t - p0) / (p1 - p0))
        }
        return last.1
    }
}

struct QuadCurve {
    var p0: CGPoint, c: CGPoint, p1: CGPoint

    func point(_ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * p0.x + 2 * u * t * c.x + t * t * p1.x,
            y: u * u * p0.y + 2 * u * t * c.y + t * t * p1.y
        )
    }

    func derivative(_ t: CGFloat) -> CGPoint {
        CGPoint(
            x: 2 * (1 - t) * (c.x - p0.x) + 2 * t * (p1.x - c.x),
            y: 2 * (1 - t) * (c.y - p0.y) + 2 * t * (p1.y - c.y)
        )
    }

    /// Path along the part of the curve between t0 and t1.
    func path(from t0: CGFloat, to t1: CGFloat, steps: Int = 40) -> Path {
        var p = Path()
        guard t1 > t0 else { return p }
        p.move(to: point(t0))
        for i in 1...steps {
            p.addLine(to: point(t0 + (t1 - t0) * CGFloat(i) / CGFloat(steps)))
        }
        return p
    }
}

/// Vector drawing helpers.
enum Ink {
    static func cubic(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, steps: Int = 16) -> [CGPoint] {
        (0...steps).map { i in
            let t = CGFloat(i) / CGFloat(steps), u = 1 - t
            let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
            return CGPoint(
                x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
                y: a * p0.y + b * p1.y + c * p2.y + d * p3.y
            )
        }
    }

    static func quad(_ p0: CGPoint, _ c: CGPoint, _ p1: CGPoint, steps: Int = 12) -> [CGPoint] {
        let q = QuadCurve(p0: p0, c: c, p1: p1)
        return (0...steps).map { q.point(CGFloat($0) / CGFloat(steps)) }
    }

    /// A filled shape that runs along `pts`, tapering from width w0 to w1 (tails, necks, horns).
    static func tapered(_ pts: [CGPoint], _ w0: CGFloat, _ w1: CGFloat) -> Path {
        var p = Path()
        let n = pts.count
        guard n > 1 else { return p }
        var left: [CGPoint] = [], right: [CGPoint] = []
        for i in 0..<n {
            let a = pts[max(0, i - 1)], b = pts[min(n - 1, i + 1)]
            var dx = b.x - a.x, dy = b.y - a.y
            let len = max(0.0001, sqrt(dx * dx + dy * dy))
            dx /= len; dy /= len
            let hw = M.lerp(w0, w1, CGFloat(i) / CGFloat(n - 1)) / 2
            left.append(CGPoint(x: pts[i].x - dy * hw, y: pts[i].y + dx * hw))
            right.append(CGPoint(x: pts[i].x + dy * hw, y: pts[i].y - dx * hw))
        }
        p.move(to: left[0])
        left.dropFirst().forEach { p.addLine(to: $0) }
        right.reversed().forEach { p.addLine(to: $0) }
        p.closeSubpath()
        return p
    }

    static func circle(_ c: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    }

    static func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2))
    }

    static func heart(_ c: CGPoint, _ s: CGFloat) -> Path {
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: c.x + x * s, y: c.y + y * s) }
        var p = Path()
        p.move(to: P(0, 0.35))
        p.addCurve(to: P(-0.5, -0.12), control1: P(-0.15, 0.2), control2: P(-0.5, 0.08))
        p.addCurve(to: P(0, -0.22), control1: P(-0.5, -0.42), control2: P(-0.08, -0.45))
        p.addCurve(to: P(0.5, -0.12), control1: P(0.08, -0.45), control2: P(0.5, -0.42))
        p.addCurve(to: P(0, 0.35), control1: P(0.5, 0.08), control2: P(0.15, 0.2))
        p.closeSubpath()
        return p
    }

    /// Little four-pointed sparkle.
    static func sparkle(_ c: CGPoint, _ r: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: c)
        p.closeSubpath()
        return p
    }
}

/// Two-bone inverse kinematics (an arm reaching for a point).
enum IK {
    static func solve(shoulder s: CGPoint, target t: CGPoint, upper l1: CGFloat, lower l2: CGFloat, bendDown: Bool) -> (elbow: CGPoint, hand: CGPoint) {
        var dx = t.x - s.x, dy = t.y - s.y
        var d = sqrt(dx * dx + dy * dy)
        let maxD = (l1 + l2) * 0.999
        if d > maxD { dx *= maxD / d; dy *= maxD / d; d = maxD }
        d = max(d, abs(l1 - l2) + 0.001)
        let base = atan2(dy, dx)
        let a = acos(min(1, max(-1, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d))))
        let angle = base + (bendDown ? a : -a)
        let elbow = CGPoint(x: s.x + cos(angle) * l1, y: s.y + sin(angle) * l1)
        return (elbow, CGPoint(x: s.x + dx, y: s.y + dy))
    }
}

enum TimeText {
    /// "24:13". Rounded up, like the Apple timer: it shows 25:00 at the start and 00:01 in the last second.
    static func mmss(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(ceil(seconds - 0.001)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

/// Egg outline: narrower on top.
struct EggShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height, x = r.minX, y = r.minY
        p.move(to: CGPoint(x: x + w / 2, y: y))
        p.addCurve(to: CGPoint(x: x + w, y: y + h * 0.62),
                   control1: CGPoint(x: x + w * 0.84, y: y), control2: CGPoint(x: x + w, y: y + h * 0.32))
        p.addCurve(to: CGPoint(x: x + w / 2, y: y + h),
                   control1: CGPoint(x: x + w, y: y + h * 0.87), control2: CGPoint(x: x + w * 0.78, y: y + h))
        p.addCurve(to: CGPoint(x: x, y: y + h * 0.62),
                   control1: CGPoint(x: x + w * 0.22, y: y + h), control2: CGPoint(x: x, y: y + h * 0.87))
        p.addCurve(to: CGPoint(x: x + w / 2, y: y),
                   control1: CGPoint(x: x, y: y + h * 0.32), control2: CGPoint(x: x + w * 0.16, y: y))
        p.closeSubpath()
        return p
    }
}
