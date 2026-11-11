import SwiftUI

/// Shared pieces of the scenes: sky, sun, clouds, sea, King's Landing, Dragonstone.
/// `u` is the scene unit: 1 at the normal card height of 118 pt.
enum Landscape {
    static func sky(_ c: GraphicsContext, _ size: CGSize, top: RGB, bottom: RGB, horizon: CGFloat) {
        c.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [top.color(), bottom.color()]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)
        ))
    }

    static func sun(_ c: GraphicsContext, at p: CGPoint, radius r: CGFloat, color: RGB, glow: Double) {
        c.fill(Ink.circle(p, r * 5), with: .radialGradient(
            Gradient(colors: [color.color(0.45 * glow), color.color(0)]),
            center: p, startRadius: r * 0.5, endRadius: r * 5
        ))
        c.fill(Ink.circle(p, r), with: .radialGradient(
            Gradient(colors: [RGB(1, 0.98, 0.9).color(), color.color()]),
            center: p, startRadius: 0, endRadius: r
        ))
    }

    static func stars(_ c: GraphicsContext, _ size: CGSize, u: CGFloat, t: Double, opacity: Double, maxY: CGFloat, count: Int) {
        guard opacity > 0.01 else { return }
        for i in 0..<count {
            let p = CGPoint(x: CGFloat(M.rand(i, 1)) * size.width, y: CGFloat(M.rand(i, 2)) * maxY)
            let twinkle = 0.45 + 0.55 * sin(t * (0.8 + M.rand(i, 3) * 2) + Double(i))
            let a = opacity * max(0.15, twinkle)
            if i % 9 == 0 {
                c.fill(Ink.sparkle(p, 2.2 * u), with: .color(.white.opacity(a)))
            } else {
                c.fill(Ink.circle(p, (0.35 + CGFloat(M.rand(i, 4)) * 0.6) * u), with: .color(.white.opacity(a)))
            }
        }
    }

    static func clouds(_ c: GraphicsContext, _ size: CGSize, u: CGFloat, t: Double, tint: RGB, opacity: Double) {
        let puffs: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(-13, 2, 11, 5), (-3, -2, 10, 6.5), (8, 1, 11, 5.5), (0, 3, 18, 4)]
        let span = size.width + 120 * u
        for i in 0..<6 {
            let speed = (2.0 + 4.0 * M.rand(i, 7)) * Double(u)
            let phase = M.fract((M.rand(i, 8) * Double(span) - t * speed) / Double(span))
            let x = CGFloat(phase) * span - 60 * u
            let y = size.height * CGFloat(0.08 + 0.30 * M.rand(i, 9))
            let s = CGFloat(0.55 + 0.6 * M.rand(i, 10)) * u
            var cloud = Path()
            for (dx, dy, rx, ry) in puffs {
                cloud.addPath(Ink.ellipse(CGPoint(x: x + dx * s, y: y + dy * s), rx * s, ry * s))
            }
            c.fill(cloud, with: .color(tint.color(opacity * (0.4 + 0.3 * M.rand(i, 11)))))
        }
    }

    static func sea(_ c: GraphicsContext, _ size: CGSize, horizon hy: CGFloat, u: CGFloat, t: Double,
                    top: RGB, bottom: RGB, glint: RGB?, glintX: CGFloat) {
        let w = size.width, h = size.height
        c.fill(Path(CGRect(x: 0, y: hy, width: w, height: h - hy)), with: .linearGradient(
            Gradient(colors: [top.color(), bottom.color()]),
            startPoint: CGPoint(x: 0, y: hy), endPoint: CGPoint(x: 0, y: h)
        ))
        c.fill(Path(CGRect(x: 0, y: hy - 0.4 * u, width: w, height: 1.0 * u)), with: .color(.white.opacity(0.14)))

        // Sun or moon path on the water.
        if let glint {
            for k in 0..<7 {
                let y = hy + (2 + CGFloat(k) * 4.4) * u
                guard y < h else { break }
                let half = (10 - CGFloat(k)) * u * CGFloat(0.65 + 0.35 * sin(t * 3 + Double(k) * 1.3))
                let a = 0.4 * (1 - Double(k) / 8)
                c.fill(Path(roundedRect: CGRect(x: glintX - half, y: y, width: half * 2, height: 1.1 * u), cornerRadius: 0.5 * u),
                       with: .color(glint.color(a)))
            }
        }

        // Little waves drifting.
        for row in 0..<4 {
            let y = hy + (6 + CGFloat(row) * 8) * u
            guard y < h - u else { break }
            let gap = (22 + CGFloat(row) * 4) * u
            let offset = CGFloat(M.fract(t * (0.04 + 0.02 * Double(row)))) * gap
            var p = Path()
            var k = 0
            var x = -gap + offset
            while x < w + gap {
                let jitter = CGFloat(M.rand(k, 30 + row)) * 9 * u
                let len = (5 + CGFloat(row)) * u
                p.move(to: CGPoint(x: x + jitter, y: y))
                p.addQuadCurve(to: CGPoint(x: x + jitter + len, y: y), control: CGPoint(x: x + jitter + len / 2, y: y - 1.4 * u))
                x += gap
                k += 1
            }
            c.stroke(p, with: .color(.white.opacity(0.10 + 0.04 * Double(row))), lineWidth: 0.8 * u)
        }

        // Sparkles on the water.
        for i in 0..<12 {
            let b = pow(max(0, sin(t * 1.8 + Double(i) * 1.7)), 8)
            guard b > 0.02 else { continue }
            let p = CGPoint(x: CGFloat(M.rand(i, 20)) * w, y: hy + 3 * u + CGFloat(M.rand(i, 21)) * (h - hy - 6 * u))
            c.fill(Ink.sparkle(p, (1 + 1.5 * CGFloat(b)) * u), with: .color(.white.opacity(b)))
        }
    }

    /// King's Landing: a hill with houses and the Red Keep. `base`: top of the hill.
    static func kingsLanding(_ c: GraphicsContext, base: CGPoint, u: CGFloat, t: Double, lit: Double, land: RGB) {
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: base.x + x * u, y: base.y + y * u) }
        let windowColor = RGB(1, 0.78, 0.4)

        var mound = Path()
        mound.move(to: P(-38, 12))
        mound.addQuadCurve(to: P(36, 12), control: P(0, -16))
        mound.closeSubpath()
        c.fill(mound, with: .color(land.color()))

        // Houses on the slope.
        for i in 0..<16 {
            let x = -32 + CGFloat(M.rand(i, 30)) * 62
            let groundY = 12 - 14 * (1 - (x / 37) * (x / 37))
            let hw = 2.8 + CGFloat(M.rand(i, 31)) * 2.2
            let hh = 2.5 + CGFloat(M.rand(i, 32)) * 3
            let rect = CGRect(x: base.x + (x - hw / 2) * u, y: base.y + (groundY - hh) * u, width: hw * u, height: (hh + 1.5) * u)
            c.fill(Path(rect), with: .color(RGB(0.24, 0.15, 0.15).color()))
            if M.rand(i, 33) > 0.35 {
                let tw = 0.55 + 0.45 * sin(t * 1.7 + Double(i) * 2)
                c.fill(Ink.circle(P(x, groundY - hh * 0.55), 0.55 * u), with: .color(windowColor.color((0.3 + 0.7 * lit) * tw)))
            }
        }

        // Red Keep.
        let keepTop = RGB(0.62, 0.18, 0.14), keepBottom = RGB(0.32, 0.08, 0.08), roof = RGB(0.74, 0.22, 0.16)
        c.fill(Path(CGRect(x: base.x - 11 * u, y: base.y - 8 * u, width: 22 * u, height: 7 * u)), with: .color(keepBottom.color()))
        let towers: [(CGFloat, CGFloat, CGFloat)] = [(-9.5, 4, 10), (-4.8, 5, 15), (0, 7, 22), (5.2, 5, 14), (9.8, 4, 9)]
        for (i, tower) in towers.enumerated() {
            let (dx, tw, th) = tower
            let top = -2 - th
            c.fill(Path(CGRect(x: base.x + (dx - tw / 2) * u, y: base.y + top * u, width: tw * u, height: (th + 1) * u)),
                   with: .linearGradient(Gradient(colors: [keepTop.color(), keepBottom.color()]),
                                         startPoint: P(dx, top), endPoint: P(dx, -1)))
            var r = Path()
            r.move(to: P(dx - tw / 2 - 0.7, top))
            r.addLine(to: P(dx, top - 4.5))
            r.addLine(to: P(dx + tw / 2 + 0.7, top))
            r.closeSubpath()
            c.fill(r, with: .color(roof.color()))
            let tw2 = 0.6 + 0.4 * sin(t * 1.3 + Double(i))
            c.fill(Ink.circle(P(dx, top + th * 0.4), 0.7 * u), with: .color(windowColor.color((0.35 + 0.65 * lit) * tw2)))
        }
        if lit > 0.5 {
            c.fill(Ink.circle(P(0, -10), 26 * u), with: .radialGradient(
                Gradient(colors: [windowColor.color(0.22 * (lit - 0.5) * 2), windowColor.color(0)]),
                center: P(0, -10), startRadius: 0, endRadius: 26 * u
            ))
        }
    }

    /// Dragonstone: a jagged rock in the sea with a castle on top. `base`: center at the waterline.
    static func dragonstone(_ c: GraphicsContext, base: CGPoint, u: CGFloat, t: Double, rock: RGB) {
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: base.x + x * u, y: base.y + y * u) }
        let pts: [(CGFloat, CGFloat)] = [(-27, 4), (-22, -5), (-16, -9), (-12, -19), (-7, -16), (-2, -29),
                                         (3, -24), (8, -27), (13, -16), (19, -10), (24, -3), (28, 4)]
        var crag = Path()
        crag.move(to: P(pts[0].0, pts[0].1))
        pts.dropFirst().forEach { crag.addLine(to: P($0.0, $0.1)) }
        crag.closeSubpath()
        c.fill(crag, with: .linearGradient(
            Gradient(colors: [rock.color(), RGB(rock.r * 0.4, rock.g * 0.4, rock.b * 0.45).color()]),
            startPoint: P(0, -29), endPoint: P(0, 4)
        ))
        var facets = Path()
        facets.move(to: P(-2, -29)); facets.addLine(to: P(-6, -8))
        facets.move(to: P(8, -27)); facets.addLine(to: P(10, -6))
        facets.move(to: P(-12, -19)); facets.addLine(to: P(-14, -4))
        c.stroke(facets, with: .color(.white.opacity(0.08)), lineWidth: 0.7 * u)

        // Castle.
        let towers: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(-2, -29, 3.4, 9), (3, -24, 2.8, 6), (8, -27, 3.2, 8)]
        let castle = RGB(rock.r * 0.55, rock.g * 0.55, rock.b * 0.65)
        for (i, tower) in towers.enumerated() {
            let (x, y, tw, th) = tower
            c.fill(Path(CGRect(x: base.x + (x - tw / 2) * u, y: base.y + (y - th) * u, width: tw * u, height: (th + 1.5) * u)),
                   with: .color(castle.color()))
            var r = Path()
            r.move(to: P(x - tw / 2 - 0.5, y - th))
            r.addLine(to: P(x, y - th - 3.5))
            r.addLine(to: P(x + tw / 2 + 0.5, y - th))
            r.closeSubpath()
            c.fill(r, with: .color(castle.color()))
            let flicker = 0.55 + 0.45 * sin(t * 2.3 + Double(i) * 1.9)
            c.fill(Ink.circle(P(x, y - th * 0.55), 0.6 * u), with: .color(RGB(1, 0.6, 0.25).color(0.8 * flicker)))
        }

        // Surf.
        let s = 1 + 0.04 * CGFloat(sin(t * 1.4))
        c.stroke(Ink.ellipse(P(0, 4), 30 * u * s, 2.2 * u), with: .color(.white.opacity(0.22)), lineWidth: 0.8 * u)
    }

    static func label(_ c: GraphicsContext, _ text: String, at p: CGPoint, u: CGFloat) {
        var l = c
        l.addFilter(.shadow(color: .black.opacity(0.7), radius: 2 * u))
        l.draw(
            Text(text)
                .font(.system(size: 8.5 * u, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85)),
            at: p, anchor: .center
        )
    }
}
