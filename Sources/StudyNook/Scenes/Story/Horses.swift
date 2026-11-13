import SwiftUI

/// A detailed horse: shaded body, jointed legs in a gallop, mane, tail, head with ears and an eye.
/// Facing right, feet on `at`. At scale 1 it is about 30 units long and 25 tall.
enum Horse {
    struct Coat {
        var body: RGB
        var mane: RGB
        static let silver = Coat(body: RGB(0.88, 0.88, 0.92), mane: RGB(0.75, 0.75, 0.82))
        static let black = Coat(body: RGB(0.13, 0.11, 0.11), mane: RGB(0.05, 0.04, 0.04))
        static let bay = Coat(body: RGB(0.48, 0.28, 0.16), mane: RGB(0.12, 0.08, 0.06))
        static let chestnut = Coat(body: RGB(0.62, 0.36, 0.2), mane: RGB(0.36, 0.18, 0.1))
        static let dun = Coat(body: RGB(0.7, 0.58, 0.4), mane: RGB(0.25, 0.18, 0.12))
        static func random(_ i: Int) -> Coat { [bay, chestnut, dun, black, bay][i % 5] }
    }

    /// Draws the horse and returns where a rider's hips sit, in scene coordinates.
    @discardableResult
    static func draw(_ base: GraphicsContext, at feet: CGPoint, scale k: CGFloat, coat: Coat, phase: Double,
                     saddle: RGB? = nil, facing: CGFloat = 1, moving: Bool = true) -> CGPoint {
        var c = base
        let bob = moving ? CGFloat(sin(phase * 2)) * 0.6 : 0
        c.translateBy(x: feet.x, y: feet.y)
        c.scaleBy(x: k * facing, y: k)
        c.translateBy(x: 0, y: bob)
        let dark = RGB(coat.body.r * 0.55, coat.body.g * 0.55, coat.body.b * 0.55)
        let light = RGB.lerp(coat.body, RGB(1, 1, 1), 0.25)

        // Far legs first (darker), then the body, then near legs.
        func leg(_ hip: CGPoint, _ offset: Double, front: Bool, near: Bool) {
            let ph = phase + offset
            let a = moving ? sin(ph) * 0.55 : (front ? 0.05 : -0.05)
            let lift = moving ? max(0, -cos(ph)) : 0
            let bend = front ? -lift * 1.2 : lift * 0.9
            let knee = CGPoint(x: hip.x + CGFloat(sin(a)) * 5.6, y: hip.y + CGFloat(cos(a)) * 5.6)
            let a2 = a + bend
            let hoof = CGPoint(x: knee.x + CGFloat(sin(a2)) * 5.4, y: knee.y + CGFloat(cos(a2)) * 5.4)
            let col = near ? coat.body : dark
            c.fill(Ink.tapered([hip, knee], 2.6, 1.7), with: .color(col.color()))
            c.fill(Ink.tapered([knee, hoof], 1.7, 1.3), with: .color(col.color()))
            c.fill(Ink.ellipse(CGPoint(x: hoof.x + 0.3, y: hoof.y + 0.2), 1.1, 0.7), with: .color(RGB(0.1, 0.08, 0.07).color()))
        }
        leg(CGPoint(x: -7, y: -11), 0.5, front: false, near: false)
        leg(CGPoint(x: 6, y: -11), 2.7, front: true, near: false)

        // Tail.
        let sway = moving ? sin(phase) * 1.5 : sin(phase * 0.3) * 0.5
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: -10.5, y: -15), CGPoint(x: -15, y: -14 + CGFloat(sway)), CGPoint(x: -15.5, y: -6 + CGFloat(sway))), 2.6, 0.8),
               with: .color(coat.mane.color()))

        // Body: hindquarters, barrel, shoulder.
        var body = Path()
        body.addEllipse(in: CGRect(x: -12.5, y: -18.8, width: 11, height: 11))
        body.addEllipse(in: CGRect(x: -10, y: -18, width: 20, height: 9.6))
        body.addEllipse(in: CGRect(x: 2, y: -18.5, width: 10, height: 10.5))
        c.fill(body, with: .linearGradient(Gradient(colors: [light.color(), coat.body.color(), dark.color()]),
                                           startPoint: CGPoint(x: 0, y: -19), endPoint: CGPoint(x: 0, y: -8)))
        // Muscle line and belly shadow.
        var muscle = Path()
        muscle.move(to: CGPoint(x: -6, y: -16)); muscle.addQuadCurve(to: CGPoint(x: -4, y: -10), control: CGPoint(x: -3, y: -14))
        muscle.move(to: CGPoint(x: 6, y: -16)); muscle.addQuadCurve(to: CGPoint(x: 5, y: -10), control: CGPoint(x: 8, y: -13))
        c.stroke(muscle, with: .color(dark.color(0.5)), lineWidth: 0.5)

        // Neck and head.
        c.fill(Ink.tapered(Ink.quad(CGPoint(x: 8, y: -15), CGPoint(x: 10, y: -21), CGPoint(x: 12.5, y: -24)), 6.4, 3.8), with: .linearGradient(
            Gradient(colors: [light.color(), coat.body.color()]), startPoint: CGPoint(x: 9, y: -24), endPoint: CGPoint(x: 9, y: -14)))
        c.fill(Ink.tapered([CGPoint(x: 12, y: -24), CGPoint(x: 15.5, y: -21.5), CGPoint(x: 17.8, y: -19.6)], 4, 2.4), with: .color(coat.body.color()))
        c.fill(Ink.ellipse(CGPoint(x: 17.6, y: -19.5), 1.4, 1.1), with: .color(dark.color()))
        // Ears, eye, nostril.
        c.fill(Path { $0.move(to: CGPoint(x: 11.6, y: -24.6)); $0.addLine(to: CGPoint(x: 11.8, y: -27.4)); $0.addLine(to: CGPoint(x: 13, y: -24.8)); $0.closeSubpath() }, with: .color(coat.body.color()))
        c.fill(Ink.circle(CGPoint(x: 14.2, y: -23), 0.5), with: .color(.black))
        c.fill(Ink.circle(CGPoint(x: 18.2, y: -19.9), 0.3), with: .color(.black.opacity(0.7)))
        // Mane.
        var mane = Path()
        for i in 0..<6 {
            let f = CGFloat(i) / 5
            let p = CGPoint(x: 7.5 + f * 4.6, y: -17 - f * 7.5)
            let wave = moving ? CGFloat(sin(phase + Double(i))) * 0.6 : 0
            mane.move(to: p)
            mane.addQuadCurve(to: CGPoint(x: p.x - 2.6, y: p.y + 1.6 + wave), control: CGPoint(x: p.x - 1.2, y: p.y - 0.6))
        }
        c.stroke(mane, with: .color(coat.mane.color()), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))

        // Saddle and blanket.
        if let saddle {
            c.fill(Path(roundedRect: CGRect(x: -4, y: -19.3, width: 9, height: 4.2), cornerRadius: 1.2), with: .color(saddle.color()))
            c.fill(Path(roundedRect: CGRect(x: -2.5, y: -20.2, width: 6, height: 1.6), cornerRadius: 0.8), with: .color(RGB(0.3, 0.18, 0.1).color()))
        }

        // Near legs.
        leg(CGPoint(x: -6, y: -11), 0, front: false, near: true)
        leg(CGPoint(x: 7, y: -11), 2.2, front: true, near: true)

        return CGPoint(x: feet.x + 0.5 * k * facing, y: feet.y + (-19.5 + bob) * k)
    }

    /// Horse with a person on it. The rider's hips sit on the saddle and the legs hang down the side.
    static func ridden(_ c: GraphicsContext, at feet: CGPoint, scale k: CGFloat, coat: Coat, rider: FigureStyle, phase: Double,
                       saddle: RGB = RGB(0.55, 0.2, 0.15), facing: CGFloat = 1, moving: Bool = true, t: Double, arms: Double = 0.15) {
        let seat = draw(c, at: feet, scale: k, coat: coat, phase: phase, saddle: saddle, facing: facing, moving: moving)
        let h = 17 * k
        Figure.draw(c, feet: CGPoint(x: seat.x, y: seat.y + h * 0.45), h: h, style: rider, facing: facing, t: t, arms: arms)
    }
}
