import SwiftUI

/// Before the first flight: night, a crescent moon, a dragon egg glowing and wobbling on Dragonstone.
/// After the rest (`ready`): dawn, the dragon hovers by Dragonstone, ready for the next flight.
enum IdlePainter {
    static func draw(_ c: GraphicsContext, size: CGSize, t: Double, ready: Bool) {
        let w = size.width, h = size.height, u = h / 118, hy = h * 0.72

        let top = ready ? RGB(0.16, 0.20, 0.44) : RGB(0.04, 0.06, 0.16)
        let bottom = ready ? RGB(0.92, 0.60, 0.52) : RGB(0.20, 0.17, 0.36)
        Landscape.sky(c, size, top: top, bottom: bottom, horizon: hy)
        Landscape.stars(c, size, u: u, t: t, opacity: ready ? 0.3 : 1, maxY: hy * 0.85, count: 40)

        let glint: RGB
        let glintX: CGFloat
        if ready {
            let sunColor = RGB(1, 0.72, 0.45)
            Landscape.sun(c, at: CGPoint(x: w * 0.86, y: hy - 2 * u), radius: 10 * u, color: sunColor, glow: 0.9)
            glint = sunColor
            glintX = w * 0.86
        } else {
            moon(c, at: CGPoint(x: w * 0.2, y: h * 0.28), r: 7 * u)
            glint = RGB(0.85, 0.88, 1)
            glintX = w * 0.2
        }

        Landscape.sea(c, size, horizon: hy, u: u, t: t,
                      top: ready ? RGB(0.45, 0.38, 0.55) : RGB(0.12, 0.16, 0.30),
                      bottom: RGB(0.03, 0.06, 0.14), glint: glint, glintX: glintX)
        Landscape.kingsLanding(c, base: CGPoint(x: w * 0.13, y: hy + 3 * u), u: u * 0.75, t: t, lit: 0.6,
                               land: RGB(0.16, 0.14, 0.22), extent: 150, mirrored: true)

        let island = CGPoint(x: w * 0.66, y: hy + 3 * u)
        let k: CGFloat = 1.6
        Landscape.dragonstone(c, base: island, u: u * k, t: t,
                              rock: ready ? RGB(0.40, 0.32, 0.40) : RGB(0.24, 0.25, 0.34))

        if ready {
            let pos = CGPoint(x: island.x - 85 * u, y: h * 0.36 + CGFloat(sin(t * 2 * .pi * 0.6)) * 2 * u)
            let pose = DragonPose(position: pos, angle: -0.05, scale: 0.40 * u, flip: -1)
            DragonPainter.drawFlying(c, pose: pose, flapPhase: t * 2 * .pi * 1.1, t: t, palette: .drogon)
        } else {
            egg(c, bottom: CGPoint(x: island.x - 16 * u * k, y: island.y - 9 * u * k), u: u, t: t)
        }

        Landscape.label(c, "Драконий Камень", at: CGPoint(x: island.x, y: h - 8 * u), u: u)
    }

    private static func moon(_ c: GraphicsContext, at p: CGPoint, r: CGFloat) {
        c.fill(Ink.circle(p, r * 4), with: .radialGradient(
            Gradient(colors: [RGB(0.8, 0.85, 1).color(0.25), RGB(0.8, 0.85, 1).color(0)]),
            center: p, startRadius: r * 0.5, endRadius: r * 4
        ))
        c.drawLayer { layer in
            layer.fill(Ink.circle(p, r), with: .color(RGB(0.98, 0.95, 0.85).color()))
            layer.blendMode = .destinationOut
            layer.fill(Ink.circle(CGPoint(x: p.x + r * 0.45, y: p.y - r * 0.3), r * 0.9), with: .color(.black))
        }
    }

    /// Dragon egg: dark red with golden scales; it glows and wobbles now and then.
    private static func egg(_ c: GraphicsContext, bottom: CGPoint, u: CGFloat, t: Double) {
        let cycle = t.truncatingRemainder(dividingBy: 3.6)
        let wobble = cycle < 1 ? sin(cycle * .pi * 5) * (1 - cycle) * 0.22 : 0

        var e = c
        e.translateBy(x: bottom.x, y: bottom.y)
        let glow = 0.55 + 0.3 * sin(t * 1.6)
        e.fill(Ink.circle(CGPoint(x: 0, y: -6.5 * u), 15 * u), with: .radialGradient(
            Gradient(colors: [RGB(1, 0.5, 0.15).color(0.5 * glow), RGB(1, 0.5, 0.15).color(0)]),
            center: CGPoint(x: 0, y: -6.5 * u), startRadius: 0, endRadius: 15 * u
        ))
        e.rotate(by: .radians(wobble))

        let rect = CGRect(x: -4.6 * u, y: -13 * u, width: 9.2 * u, height: 13 * u)
        let shape = EggShape().path(in: rect)
        e.fill(shape, with: .linearGradient(
            Gradient(colors: [RGB(0.62, 0.14, 0.09).color(), RGB(0.14, 0.03, 0.04).color()]),
            startPoint: CGPoint(x: -3 * u, y: -12 * u), endPoint: CGPoint(x: 3 * u, y: 0)
        ))
        var scales = e
        scales.clip(to: shape)
        var arcs = Path()
        for row in 0..<5 {
            let y = (-11.5 + CGFloat(row) * 2.4) * u
            let shift: CGFloat = row % 2 == 0 ? 0 : 1.3
            for col in -3...3 {
                let x = (CGFloat(col) * 2.6 + shift) * u
                arcs.move(to: CGPoint(x: x - 1.3 * u, y: y))
                arcs.addQuadCurve(to: CGPoint(x: x + 1.3 * u, y: y), control: CGPoint(x: x, y: y + 1.8 * u))
            }
        }
        scales.stroke(arcs, with: .color(RGB(1, 0.78, 0.4).color(0.45 + 0.2 * glow)), lineWidth: 0.45 * u)
        scales.fill(Ink.ellipse(CGPoint(x: -1.6 * u, y: -9 * u), 1.2 * u, 2.6 * u), with: .color(.white.opacity(0.18)))
    }
}
