import SwiftUI

/// Hand-built architecture: towers with shaded faces, stone courses, battlements and roofs.
/// Used in backgrounds, which are redrawn about once a second, so detail here is cheap.
enum Buildings {
    private static func shade(_ c: RGB, _ k: Double) -> RGB { RGB(min(1, c.r * k), min(1, c.g * k), min(1, c.b * k)) }

    // MARK: - Pieces

    /// A tower with a lit left face, a shaded right face, stone courses, arrow slits, optional battlements and a conical roof.
    static func tower(_ c: GraphicsContext, x: CGFloat, base: CGFloat, w: CGFloat, h: CGFloat, stone: RGB, roof: RGB?,
                      u: CGFloat, lit: Double, seed: Int, crenel: Bool = false, flag: RGB? = nil, t: Double = 0) {
        let rect = CGRect(x: x, y: base - h, width: w, height: h)
        c.fill(Path(rect), with: .linearGradient(
            Gradient(stops: [.init(color: shade(stone, 1.25).color(), location: 0), .init(color: stone.color(), location: 0.45), .init(color: shade(stone, 0.6).color(), location: 1)]),
            startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + w, y: 0)))
        // Stone courses.
        var courses = Path()
        var y = base - h + 3 * u
        var k = 0
        while y < base {
            courses.move(to: CGPoint(x: x, y: y)); courses.addLine(to: CGPoint(x: x + w, y: y))
            let off = CGFloat(k % 2) * w * 0.25
            courses.move(to: CGPoint(x: x + w * 0.3 + off, y: y)); courses.addLine(to: CGPoint(x: x + w * 0.3 + off, y: y + 3 * u))
            y += 3 * u; k += 1
        }
        c.stroke(courses, with: .color(shade(stone, 0.5).color(0.35)), lineWidth: 0.4 * u)
        // Arrow slits and a glowing window.
        let rows = max(1, Int(h / (12 * u)))
        for r in 0..<rows {
            let wy = base - h + (6 + CGFloat(r) * 12) * u
            let wx = x + w * (0.35 + 0.2 * CGFloat(M.rand(r, seed)))
            var slit = Path()
            slit.move(to: CGPoint(x: wx, y: wy + 4.5 * u)); slit.addLine(to: CGPoint(x: wx, y: wy + 1 * u))
            slit.addQuadCurve(to: CGPoint(x: wx + 1.5 * u, y: wy + 1 * u), control: CGPoint(x: wx + 0.75 * u, y: wy - 1 * u)); slit.addLine(to: CGPoint(x: wx + 1.5 * u, y: wy + 4.5 * u)); slit.closeSubpath()
            c.fill(slit, with: .color(RGB(0.06, 0.05, 0.07).color()))
            if M.rand(r + 3, seed) > 0.3 {
                let flick = 0.7 + 0.3 * sin(t * 1.6 + Double(r + seed))
                c.fill(slit, with: .color(RGB(1, 0.72, 0.35).color((0.25 + 0.75 * lit) * flick)))
            }
        }
        // Plinth.
        c.fill(Path(CGRect(x: x - 1 * u, y: base - 2.5 * u, width: w + 2 * u, height: 2.5 * u)), with: .color(shade(stone, 0.8).color()))
        var topY = base - h
        if crenel {
            let n = max(3, Int(w / (2.6 * u)))
            var cr = Path()
            for i in 0..<n where i % 2 == 0 {
                cr.addRect(CGRect(x: x - 0.8 * u + CGFloat(i) * (w + 1.6 * u) / CGFloat(n), y: topY - 2.4 * u, width: (w + 1.6 * u) / CGFloat(n), height: 2.6 * u))
            }
            c.fill(cr, with: .color(stone.color()))
            c.fill(Path(CGRect(x: x - 1 * u, y: topY, width: w + 2 * u, height: 1.4 * u)), with: .color(shade(stone, 0.7).color()))
            topY -= 2.4 * u
        }
        if let roof {
            let rh = w * 1.25
            var l = Path(), r = Path()
            l.move(to: CGPoint(x: x - 1.4 * u, y: topY)); l.addLine(to: CGPoint(x: x + w / 2, y: topY - rh)); l.addLine(to: CGPoint(x: x + w / 2, y: topY)); l.closeSubpath()
            r.move(to: CGPoint(x: x + w / 2, y: topY - rh)); r.addLine(to: CGPoint(x: x + w + 1.4 * u, y: topY)); r.addLine(to: CGPoint(x: x + w / 2, y: topY)); r.closeSubpath()
            c.fill(l, with: .color(shade(roof, 1.25).color()))
            c.fill(r, with: .color(shade(roof, 0.65).color()))
            c.stroke(Path { $0.move(to: CGPoint(x: x - 1.4 * u, y: topY)); $0.addLine(to: CGPoint(x: x + w + 1.4 * u, y: topY)) }, with: .color(shade(roof, 0.5).color()), lineWidth: 0.6 * u)
            if let flag {
                c.stroke(Path { $0.move(to: CGPoint(x: x + w / 2, y: topY - rh)); $0.addLine(to: CGPoint(x: x + w / 2, y: topY - rh - 5 * u)) }, with: .color(.black.opacity(0.6)), lineWidth: 0.5 * u)
                var f = Path()
                let wave = CGFloat(sin(t * 3 + Double(seed))) * 0.6 * u
                f.move(to: CGPoint(x: x + w / 2, y: topY - rh - 5 * u)); f.addLine(to: CGPoint(x: x + w / 2 + 4 * u, y: topY - rh - 4 * u + wave)); f.addLine(to: CGPoint(x: x + w / 2, y: topY - rh - 2.8 * u)); f.closeSubpath()
                c.fill(f, with: .color(flag.color()))
            }
        }
    }

    /// A curtain wall with battlements, courses, buttresses and a gate.
    static func wall(_ c: GraphicsContext, x0: CGFloat, x1: CGFloat, base: CGFloat, h: CGFloat, stone: RGB, u: CGFloat, gate: CGFloat? = nil, seed: Int = 0, lit: Double = 0.5) {
        let rect = CGRect(x: x0, y: base - h, width: x1 - x0, height: h)
        c.fill(Path(rect), with: .linearGradient(Gradient(colors: [shade(stone, 1.15).color(), shade(stone, 0.6).color()]),
                                                 startPoint: CGPoint(x: 0, y: base - h), endPoint: CGPoint(x: 0, y: base)))
        var courses = Path()
        var y = base - h + 3 * u
        var k = 0
        while y < base {
            courses.move(to: CGPoint(x: x0, y: y)); courses.addLine(to: CGPoint(x: x1, y: y))
            var x = x0 + CGFloat(k % 2) * 3 * u
            while x < x1 { courses.move(to: CGPoint(x: x, y: y)); courses.addLine(to: CGPoint(x: x, y: y + 3 * u)); x += 6 * u }
            y += 3 * u; k += 1
        }
        c.stroke(courses, with: .color(shade(stone, 0.45).color(0.3)), lineWidth: 0.35 * u)
        var cr = Path()
        var x = x0
        while x < x1 { cr.addRect(CGRect(x: x, y: base - h - 2.4 * u, width: 2.6 * u, height: 2.6 * u)); x += 5.2 * u }
        c.fill(cr, with: .color(stone.color()))
        // Buttresses.
        var b = Path()
        x = x0 + 12 * u
        while x < x1 - 4 * u { b.addRect(CGRect(x: x, y: base - h * 0.85, width: 3 * u, height: h * 0.85)); x += 26 * u }
        c.fill(b, with: .color(shade(stone, 0.75).color()))
        if let g = gate {
            var arch = Path()
            arch.move(to: CGPoint(x: g - 4 * u, y: base)); arch.addLine(to: CGPoint(x: g - 4 * u, y: base - h * 0.55))
            arch.addQuadCurve(to: CGPoint(x: g + 4 * u, y: base - h * 0.55), control: CGPoint(x: g, y: base - h * 0.95)); arch.addLine(to: CGPoint(x: g + 4 * u, y: base)); arch.closeSubpath()
            c.fill(arch, with: .color(RGB(0.05, 0.04, 0.05).color()))
            c.fill(arch, with: .color(RGB(1, 0.65, 0.3).color(0.25 + 0.5 * lit)))
        }
    }

    /// A small house with a gabled tile roof, chimney and windows.
    static func house(_ c: GraphicsContext, x: CGFloat, base: CGFloat, w: CGFloat, h: CGFloat, wall: RGB, roof: RGB, u: CGFloat, lit: Double, seed: Int, t: Double = 0, snow: Bool = false) {
        c.fill(Path(CGRect(x: x, y: base - h, width: w, height: h)), with: .linearGradient(
            Gradient(colors: [shade(wall, 1.1).color(), shade(wall, 0.65).color()]), startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + w, y: 0)))
        let rh = w * 0.45
        var l = Path(), r = Path()
        l.move(to: CGPoint(x: x - 0.8 * u, y: base - h)); l.addLine(to: CGPoint(x: x + w / 2, y: base - h - rh)); l.addLine(to: CGPoint(x: x + w / 2, y: base - h)); l.closeSubpath()
        r.move(to: CGPoint(x: x + w / 2, y: base - h - rh)); r.addLine(to: CGPoint(x: x + w + 0.8 * u, y: base - h)); r.addLine(to: CGPoint(x: x + w / 2, y: base - h)); r.closeSubpath()
        c.fill(l, with: .color(shade(roof, 1.2).color()))
        c.fill(r, with: .color(shade(roof, 0.7).color()))
        if snow {
            var s = Path()
            s.move(to: CGPoint(x: x - 0.8 * u, y: base - h)); s.addLine(to: CGPoint(x: x + w / 2, y: base - h - rh)); s.addLine(to: CGPoint(x: x + w + 0.8 * u, y: base - h))
            s.addLine(to: CGPoint(x: x + w * 0.85, y: base - h - 0.6 * u)); s.addLine(to: CGPoint(x: x + w / 2, y: base - h - rh + 1.4 * u)); s.addLine(to: CGPoint(x: x + w * 0.15, y: base - h - 0.6 * u)); s.closeSubpath()
            c.fill(s, with: .color(RGB(0.93, 0.96, 1).color(0.95)))
        }
        if M.rand(seed, 3) > 0.5 { c.fill(Path(CGRect(x: x + w * 0.7, y: base - h - rh * 0.9, width: 1.4 * u, height: 3 * u)), with: .color(shade(wall, 0.5).color())) }
        if M.rand(seed, 4) > 0.3 {
            let flick = 0.7 + 0.3 * sin(t * 1.4 + Double(seed))
            c.fill(Path(CGRect(x: x + w * 0.3, y: base - h * 0.65, width: 1.5 * u, height: 2 * u)), with: .color(RGB(1, 0.75, 0.38).color((0.3 + 0.7 * lit) * flick)))
        }
        if M.rand(seed, 5) > 0.5 { c.fill(Path(CGRect(x: x + w * 0.6, y: base - h * 0.4, width: 1.5 * u, height: h * 0.4)), with: .color(shade(wall, 0.4).color())) }
    }

    /// A shiny dome with a spire.
    static func dome(_ c: GraphicsContext, at p: CGPoint, r: CGFloat, color: RGB, u: CGFloat) {
        var d = Path()
        d.addArc(center: p, radius: r, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        d.closeSubpath()
        c.fill(d, with: .radialGradient(Gradient(colors: [shade(color, 1.5).color(), color.color(), shade(color, 0.55).color()]),
                                        center: CGPoint(x: p.x - r * 0.35, y: p.y - r * 0.55), startRadius: 0, endRadius: r * 1.5))
        c.stroke(Path { $0.move(to: CGPoint(x: p.x, y: p.y - r)); $0.addLine(to: CGPoint(x: p.x, y: p.y - r - 4 * u)) }, with: .color(RGB(0.9, 0.78, 0.4).color()), lineWidth: 0.7 * u)
        c.fill(Ink.circle(CGPoint(x: p.x, y: p.y - r - 4 * u), 0.9 * u), with: .color(RGB(1, 0.9, 0.5).color()))
    }

    // MARK: - Places

    /// King's Landing: a real coastal city. Three hills (the Hill of Visenya with the Great Sept, the High Hill of Aegon
    /// with the Red Keep, the Hill of Rhaenys), dense streets of houses down the slopes, a harbour wall and city gates.
    /// Local units: x from -64 (shore) to `extent` (open country on the right), y 0 = base line, hills rise to about -34.
    static func kingsLanding(_ c: GraphicsContext, base: CGPoint, u: CGFloat, t: Double, lit: Double, land: RGB, extent: CGFloat = 70) {
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: base.x + x * u, y: base.y + y * u) }
        func bump(_ x: CGFloat, _ mid: CGFloat, _ w: CGFloat) -> CGFloat { exp(-pow((x - mid) / w, 2)) }
        /// Surface of the land: shore on the left, three hills, flat country on the right.
        func ground(_ x: CGFloat) -> CGFloat {
            let level = 12 - 44 * bump(x, 6, 17) - 28 * bump(x, -30, 13) - 22 * bump(x, 44, 14) - 4 * bump(x, 90, 30)
            let shore = max(0, min(1, (x + 66) / 20))
            return level + (1 - shore) * 70
        }

        // The land, with a lit crest and a shaded foot.
        var landPath = Path()
        landPath.move(to: P(-70, 120))
        var x: CGFloat = -70
        while x <= extent { landPath.addLine(to: P(x, ground(x))); x += 2 }
        landPath.addLine(to: P(extent, 120))
        landPath.closeSubpath()
        c.fill(landPath, with: .linearGradient(Gradient(colors: [shade(land, 1.7).color(), land.color(), shade(land, 0.7).color()]),
                                               startPoint: P(0, -34), endPoint: P(0, 40)))
        // Beach and surf along the left shore.
        var shore = Path()
        x = -70
        shore.move(to: P(x, ground(x)))
        while x <= -40 { shore.addLine(to: P(x, ground(x))); x += 1.5 }
        c.stroke(shore, with: .color(RGB(0.95, 0.85, 0.65).color(0.7)), lineWidth: 1.6 * u)
        c.stroke(shore.applying(CGAffineTransform(translationX: -2 * u, y: 0.5 * u)), with: .color(.white.opacity(0.35)), lineWidth: 0.8 * u)

        // Houses from the back rows to the front ones, so lower streets overlap the upper ones.
        struct H { var x: CGFloat; var y: CGFloat; var w: CGFloat; var h: CGFloat; var i: Int }
        var houses: [H] = []
        var i = 0
        var hx: CGFloat = -52
        while hx < extent - 4 {
            for row in 0..<4 {
                let jitter = CGFloat(M.rand(i, 31) - 0.5) * 3
                let xx = hx + jitter
                let dense = xx < 66 ? 1.0 : 0.35
                if M.rand(i, 35) < dense {
                    let by = ground(xx) + 3 + CGFloat(row) * 4.2
                    let w = (3.2 + 2.8 * CGFloat(M.rand(i, 32))) * (0.9 + 0.1 * CGFloat(row))
                    let h = (3 + 3.4 * CGFloat(M.rand(i, 33))) * (0.9 + 0.1 * CGFloat(row))
                    if by < 40 { houses.append(H(x: xx, y: by, w: w, h: h, i: i)) }
                }
                i += 1
            }
            hx += 2.9
        }
        houses.sort { $0.y < $1.y }
        for h in houses {
            let tint = M.rand(h.i, 34)
            house(c, x: base.x + (h.x - h.w / 2) * u, base: base.y + h.y * u, w: h.w * u, h: h.h * u,
                  wall: RGB(0.62 + 0.25 * tint, 0.5 + 0.18 * tint, 0.4 + 0.1 * tint),
                  roof: tint > 0.6 ? RGB(0.62, 0.24, 0.16) : (tint > 0.3 ? RGB(0.72, 0.38, 0.22) : RGB(0.42, 0.3, 0.28)),
                  u: u * 0.55, lit: lit, seed: h.i, t: t)
        }

        // The harbour wall along the shore, with two towers.
        var wallPath = Path()
        x = -62
        wallPath.move(to: P(x, ground(x) - 1))
        while x <= -4 { wallPath.addLine(to: P(x, ground(x) - 0.5)); x += 2 }
        c.stroke(wallPath, with: .color(RGB(0.5, 0.4, 0.36).color()), style: StrokeStyle(lineWidth: 3 * u, lineCap: .butt))
        c.stroke(wallPath, with: .color(RGB(0.3, 0.22, 0.2).color()), style: StrokeStyle(lineWidth: 0.7 * u, dash: [1.6 * u, 1.6 * u]))
        for tx in [CGFloat(-58), -22] {
            tower(c, x: base.x + (tx - 2.2) * u, base: base.y + (ground(tx) + 1) * u, w: 4.4 * u, h: 12 * u, stone: RGB(0.52, 0.42, 0.38), roof: RGB(0.55, 0.2, 0.15), u: u * 0.5, lit: lit, seed: Int(tx) + 100, t: t)
        }

        // The Great Sept of Baelor on the Hill of Visenya: white, seven spires.
        let sx: CGFloat = -30, sy = ground(sx) + 1
        c.fill(Path(CGRect(x: base.x + (sx - 8) * u, y: base.y + (sy - 7) * u, width: 16 * u, height: 8 * u)), with: .linearGradient(
            Gradient(colors: [RGB(0.98, 0.96, 0.92).color(), RGB(0.7, 0.68, 0.66).color()]), startPoint: P(sx - 8, 0), endPoint: P(sx + 8, 0)))
        for k in 0..<7 {
            let px = sx - 7 + CGFloat(k) * 2.3
            let hh: CGFloat = k == 3 ? 15 : (k % 2 == 0 ? 10 : 12)
            c.fill(Path(CGRect(x: base.x + px * u, y: base.y + (sy - 7 - hh * 0.55) * u, width: 1.8 * u, height: hh * 0.6 * u)), with: .color(RGB(0.96, 0.94, 0.9).color()))
            var sp = Path()
            sp.move(to: P(px - 0.4, sy - 7 - hh * 0.55)); sp.addLine(to: P(px + 0.9, sy - 7 - hh)); sp.addLine(to: P(px + 2.2, sy - 7 - hh * 0.55)); sp.closeSubpath()
            c.fill(sp, with: .color(RGB(0.82, 0.8, 0.78).color()))
            c.fill(Ink.circle(P(px + 0.9, sy - 7 - hh - 0.8), 0.5 * u), with: .color(RGB(1, 0.9, 0.5).color()))
        }

        // The Red Keep on the High Hill of Aegon: walls, a great hall and a crown of towers.
        let kx: CGFloat = 6, ky = ground(kx)
        let keep = RGB(0.66, 0.22, 0.16), roof = RGB(0.82, 0.3, 0.18)
        wall(c, x0: base.x + (kx - 19) * u, x1: base.x + (kx + 19) * u, base: base.y + (ky + 3) * u, h: 8 * u, stone: RGB(0.58, 0.2, 0.15), u: u * 0.55, gate: base.x + kx * u, lit: lit)
        // The great hall.
        c.fill(Path(CGRect(x: base.x + (kx - 9) * u, y: base.y + (ky - 8) * u, width: 18 * u, height: 8 * u)), with: .linearGradient(
            Gradient(colors: [keep.color(), shade(keep, 0.6).color()]), startPoint: P(0, ky - 8), endPoint: P(0, ky)))
        var hallRoof = Path()
        hallRoof.move(to: P(kx - 10, ky - 8)); hallRoof.addLine(to: P(kx - 5, ky - 13)); hallRoof.addLine(to: P(kx + 5, ky - 13)); hallRoof.addLine(to: P(kx + 10, ky - 8)); hallRoof.closeSubpath()
        c.fill(hallRoof, with: .color(roof.color()))
        let towers: [(CGFloat, CGFloat, CGFloat)] = [(-16, 4.6, 20), (-11, 5.2, 30), (-5, 4.4, 24), (1, 7.6, 44), (8, 4.6, 30), (13, 5, 24), (18, 4.2, 16)]
        for (n, tw) in towers.enumerated() {
            tower(c, x: base.x + (kx + tw.0 - tw.1 / 2) * u, base: base.y + (ky + 2) * u, w: tw.1 * u, h: tw.2 * u * 0.9, stone: keep, roof: roof, u: u * 0.55, lit: lit, seed: n + 5,
                  crenel: n == 3, flag: (n == 3 || n == 1) ? RGB(0.08, 0.08, 0.1) : nil, t: t)
        }
        if lit > 0.55 {
            c.fill(Ink.circle(P(kx, ky - 16), 38 * u), with: .radialGradient(
                Gradient(colors: [RGB(1, 0.72, 0.4).color(0.2 * (lit - 0.5) * 2), RGB(1, 0.72, 0.4).color(0)]),
                center: P(kx, ky - 16), startRadius: 0, endRadius: 38 * u))
        }

        // The land walls and the great gate on the right.
        let gx: CGFloat = 64
        wall(c, x0: base.x + (gx - 4) * u, x1: base.x + extent * u, base: base.y + (ground(gx) + 5) * u, h: 9 * u, stone: RGB(0.5, 0.4, 0.36), u: u * 0.55)
        for tx in [CGFloat(gx - 5), gx + 5] {
            tower(c, x: base.x + (tx - 3) * u, base: base.y + (ground(gx) + 5.5) * u, w: 6 * u, h: 17 * u, stone: RGB(0.54, 0.42, 0.38), roof: RGB(0.55, 0.2, 0.15), u: u * 0.55, lit: lit, seed: Int(tx) + 150, crenel: true, t: t)
        }
        var gate = Path()
        let gy = ground(gx) + 5.5
        gate.move(to: P(gx - 2.4, gy)); gate.addLine(to: P(gx - 2.4, gy - 8)); gate.addQuadCurve(to: P(gx + 2.4, gy - 8), control: P(gx, gy - 12)); gate.addLine(to: P(gx + 2.4, gy)); gate.closeSubpath()
        c.fill(gate, with: .color(RGB(0.06, 0.04, 0.05).color()))
        c.fill(gate, with: .color(RGB(1, 0.65, 0.3).color(0.2 + 0.4 * lit)))
    }

    /// Dragonstone: a black crag with strata, with towers carved like dragons on top.
    static func dragonstone(_ c: GraphicsContext, base: CGPoint, u: CGFloat, t: Double, rock: RGB) {
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: base.x + x * u, y: base.y + y * u) }
        let pts: [(CGFloat, CGFloat)] = [(-30, 4), (-26, -3), (-21, -6), (-18, -14), (-13, -13), (-10, -22), (-5, -20), (-3, -30), (0, -26), (3, -33), (7, -28), (10, -30), (14, -20), (19, -14), (22, -8), (27, -3), (31, 4)]
        var crag = Path()
        crag.move(to: P(pts[0].0, pts[0].1))
        pts.dropFirst().forEach { crag.addLine(to: P($0.0, $0.1)) }
        crag.closeSubpath()
        c.fill(crag, with: .linearGradient(Gradient(colors: [shade(rock, 1.6).color(), rock.color(), shade(rock, 0.4).color()]), startPoint: P(-10, -33), endPoint: P(8, 4)))
        // Shaded right faces and strata.
        var shadePath = Path()
        shadePath.move(to: P(3, -33)); shadePath.addLine(to: P(7, -28)); shadePath.addLine(to: P(10, -30)); shadePath.addLine(to: P(14, -20)); shadePath.addLine(to: P(19, -14)); shadePath.addLine(to: P(22, -8)); shadePath.addLine(to: P(27, -3)); shadePath.addLine(to: P(31, 4)); shadePath.addLine(to: P(6, 4)); shadePath.closeSubpath()
        c.fill(shadePath, with: .color(shade(rock, 0.4).color(0.55)))
        var strata = Path()
        for k in 0..<5 {
            let y = -4 - CGFloat(k) * 5.5
            strata.move(to: P(-22 + CGFloat(k) * 2.5, y)); strata.addQuadCurve(to: P(24 - CGFloat(k) * 2.5, y + 1.5), control: P(0, y - 2))
        }
        c.stroke(strata, with: .color(.white.opacity(0.1)), lineWidth: 0.5 * u)
        // Towers carved like dragons.
        let tw: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(-3, -30, 4.4, 14), (3, -33, 3.6, 10), (10, -30, 4.2, 12)]
        for (i, d) in tw.enumerated() {
            tower(c, x: base.x + (d.0 - d.2 / 2) * u, base: base.y + (d.1 + 1) * u, w: d.2 * u, h: d.3 * u, stone: RGB(rock.r * 0.7, rock.g * 0.7, rock.b * 0.8),
                  roof: RGB(0.18, 0.17, 0.22), u: u * 0.45, lit: 0.8, seed: i + 70, t: t)
        }
        c.stroke(Ink.ellipse(P(0, 4), 33 * u * (1 + 0.04 * CGFloat(sin(t * 1.4))), 2.4 * u), with: .color(.white.opacity(0.25)), lineWidth: 0.8 * u)
    }

    /// Winterfell: grey walls, a keep with snowy roofs, towers and glowing windows.
    static func winterfell(_ c: GraphicsContext, _ env: SceneEnv, snowRoofs: Bool = true) {
        let u = env.u, hy = env.hy
        let stone = RGB(0.22, 0.24, 0.30)
        wall(c, x0: env.w * 0.02, x1: env.w * 0.44, base: hy + 5 * u, h: 15 * u, stone: stone, u: u, gate: env.w * 0.22, seed: 2, lit: 0.9)
        for i in 0..<6 {
            let x = env.w * (0.03 + 0.075 * CGFloat(i))
            let hh = (30 + 26 * M.rand(i, 7)) * u
            tower(c, x: x, base: hy + 4 * u, w: (9 + 3 * CGFloat(M.rand(i, 8))) * u, h: hh, stone: stone, roof: RGB(0.2, 0.2, 0.27), u: u * 0.8, lit: 0.9, seed: i + 10, crenel: i % 3 == 1)
            if snowRoofs {
                var s = Path()
                let w = 10 * u
                s.move(to: CGPoint(x: x - 1.4 * u, y: hy + 4 * u - hh - 2 * u)); s.addLine(to: CGPoint(x: x + w / 2, y: hy + 4 * u - hh - w * 1.25))
                s.addLine(to: CGPoint(x: x + w / 2 + 2 * u, y: hy + 4 * u - hh - w * 1.25 + 4 * u)); s.addLine(to: CGPoint(x: x + w / 2 - 2 * u, y: hy + 4 * u - hh - 5 * u)); s.closeSubpath()
                c.fill(s, with: .color(RGB(0.9, 0.94, 1).color(0.8)))
            }
        }
        // Houses and the Great Keep behind the wall.
        for i in 0..<9 {
            let x = env.w * (0.05 + 0.04 * CGFloat(i))
            house(c, x: x, base: hy + 6 * u, w: (5 + 3 * CGFloat(M.rand(i, 21))) * u, h: (5 + 3 * CGFloat(M.rand(i, 22))) * u, wall: RGB(0.24, 0.24, 0.3), roof: RGB(0.18, 0.18, 0.25), u: u * 0.7, lit: 0.9, seed: i + 30, snow: true)
        }
    }

    /// Pentos: whitewashed villas with arcades, terracotta roofs, orange trees and a tower.
    static func pentos(_ c: GraphicsContext, _ env: SceneEnv) {
        let u = env.u, hy = env.hy
        let wall = RGB(0.95, 0.9, 0.82), tile = RGB(0.82, 0.42, 0.26)
        for i in 0..<3 {
            let x = env.w * (0.04 + 0.4 * CGFloat(i)), ww = 130 * u, hh = 38 * u
            c.fill(Path(CGRect(x: x, y: hy - hh, width: ww, height: hh + 3 * u)), with: .linearGradient(Gradient(colors: [wall.color(), shade(wall, 0.8).color()]), startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + ww, y: 0)))
            // Roof with tiles.
            var roof = Path()
            roof.move(to: CGPoint(x: x - 5 * u, y: hy - hh)); roof.addLine(to: CGPoint(x: x + 14 * u, y: hy - hh - 10 * u)); roof.addLine(to: CGPoint(x: x + ww - 14 * u, y: hy - hh - 10 * u)); roof.addLine(to: CGPoint(x: x + ww + 5 * u, y: hy - hh)); roof.closeSubpath()
            c.fill(roof, with: .linearGradient(Gradient(colors: [shade(tile, 1.2).color(), shade(tile, 0.75).color()]), startPoint: CGPoint(x: 0, y: hy - hh - 10 * u), endPoint: CGPoint(x: 0, y: hy - hh)))
            var rows = Path()
            for k in 1..<3 { rows.move(to: CGPoint(x: x + (14 - CGFloat(k) * 2) * u, y: hy - hh - 10 * u + CGFloat(k) * 3.2 * u)); rows.addLine(to: CGPoint(x: x + ww - (14 - CGFloat(k) * 2) * u, y: hy - hh - 10 * u + CGFloat(k) * 3.2 * u)) }
            c.stroke(rows, with: .color(.black.opacity(0.18)), lineWidth: 0.5 * u)
            // Arcade with columns.
            for k in 0..<5 {
                let ax = x + (8 + CGFloat(k) * 24) * u
                var arch = Path()
                arch.move(to: CGPoint(x: ax, y: hy + 3 * u)); arch.addLine(to: CGPoint(x: ax, y: hy - 19 * u))
                arch.addQuadCurve(to: CGPoint(x: ax + 16 * u, y: hy - 19 * u), control: CGPoint(x: ax + 8 * u, y: hy - 32 * u)); arch.addLine(to: CGPoint(x: ax + 16 * u, y: hy + 3 * u)); arch.closeSubpath()
                c.fill(arch, with: .linearGradient(Gradient(colors: [RGB(0.2, 0.15, 0.14).color(), RGB(0.38, 0.28, 0.24).color()]), startPoint: CGPoint(x: 0, y: hy - 30 * u), endPoint: CGPoint(x: 0, y: hy + 3 * u)))
                c.fill(Path(CGRect(x: ax + 16 * u, y: hy - 19 * u, width: 8 * u, height: 22 * u)), with: .color(shade(wall, 0.9).color()))
            }
            c.fill(Path(CGRect(x: x, y: hy - 3 * u, width: ww, height: 3 * u)), with: .color(shade(wall, 0.65).color()))
        }
        // A tall bell tower between the villas.
        tower(c, x: env.w * 0.405, base: hy + 2 * u, w: 11 * u, h: 62 * u, stone: wall, roof: tile, u: u * 0.9, lit: 0, seed: 90)
        // Orange trees in a row with trunks, shaded crowns and fruit.
        for i in 0..<8 {
            let x = env.w * (0.12 + 0.11 * CGFloat(i)), y = hy + 6 * u
            c.fill(Path(CGRect(x: x - 0.9 * u, y: y - 5 * u, width: 1.8 * u, height: 6 * u)), with: .color(RGB(0.3, 0.2, 0.12).color()))
            c.fill(Ink.circle(CGPoint(x: x, y: y - 9 * u), 6.2 * u), with: .radialGradient(Gradient(colors: [RGB(0.42, 0.66, 0.28).color(), RGB(0.16, 0.36, 0.16).color()]),
                                                                                           center: CGPoint(x: x - 2 * u, y: y - 12 * u), startRadius: 0, endRadius: 8 * u))
            for k in 0..<5 { c.fill(Ink.circle(CGPoint(x: x + CGFloat(k - 2) * 2.3 * u, y: y - 9 * u + CGFloat((k * 3) % 5 - 2) * 1.5 * u), 0.9 * u), with: .color(RGB(1, 0.58, 0.1).color())) }
        }
    }

    /// Qarth: white towers with blue domes, a great gate and layered terraces.
    static func qarth(_ c: GraphicsContext, _ env: SceneEnv, x0: CGFloat, scale k: CGFloat) {
        let u = env.u, hy = env.hy
        let white = RGB(0.93, 0.91, 0.86)
        c.fill(Path(CGRect(x: x0, y: hy - 6 * u * k, width: 130 * u, height: 8 * u * k)), with: .color(shade(white, 0.8).color()))
        for i in 0..<11 {
            let x = x0 + CGFloat(i) * 11.5 * u
            let hh = (14 + 26 * M.rand(i, 14)) * u * k
            let w = (7 + 3 * CGFloat(M.rand(i, 15))) * u
            c.fill(Path(CGRect(x: x, y: hy - hh, width: w, height: hh + 2 * u)), with: .linearGradient(Gradient(colors: [shade(white, 1.05).color(), shade(white, 0.7).color()]), startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + w, y: 0)))
            var win = Path()
            for r in 0..<Int(hh / (7 * u)) { win.addRect(CGRect(x: x + w * 0.4, y: hy - hh + (3 + CGFloat(r) * 7) * u, width: 1.4 * u, height: 2.6 * u)) }
            c.fill(win, with: .color(RGB(0.2, 0.3, 0.5).color(0.8)))
            dome(c, at: CGPoint(x: x + w / 2, y: hy - hh), r: w * 0.62, color: RGB(0.16, 0.5, 0.78), u: u * 0.6)
        }
        // The great gate: three arches.
        for k in 0..<3 {
            let ax = x0 + (46 + CGFloat(k) * 14) * u
            var arch = Path()
            arch.move(to: CGPoint(x: ax, y: hy + 2 * u)); arch.addLine(to: CGPoint(x: ax, y: hy - 8 * u * k0(k)))
            arch.addQuadCurve(to: CGPoint(x: ax + 10 * u, y: hy - 8 * u * k0(k)), control: CGPoint(x: ax + 5 * u, y: hy - 15 * u * k0(k))); arch.addLine(to: CGPoint(x: ax + 10 * u, y: hy + 2 * u)); arch.closeSubpath()
            c.fill(arch, with: .color(RGB(0.1, 0.18, 0.3).color()))
        }
    }
    private static func k0(_ k: Int) -> CGFloat { 1 }

    /// Astapor: stepped brick pyramids with stairs, doorways and banners.
    static func astapor(_ c: GraphicsContext, _ env: SceneEnv, t: Double) {
        let u = env.u, hy = env.hy
        let brick = RGB(0.72, 0.30, 0.20)
        for i in 0..<4 {
            let w0 = (62 + 22 * CGFloat(M.rand(i, 3))) * u
            let x = env.w * (0.03 + 0.27 * CGFloat(i))
            let steps = 5, sh = 8.5 * u
            for s in 0..<steps {
                let ww = w0 * (1 - CGFloat(s) * 0.17)
                let rx = x + (w0 - ww) / 2, ry = hy + 4 * u - CGFloat(s + 1) * sh
                c.fill(Path(CGRect(x: rx, y: ry, width: ww, height: sh)), with: .linearGradient(Gradient(colors: [shade(brick, 1.25 - 0.05 * Double(s)).color(), shade(brick, 0.7).color()]), startPoint: CGPoint(x: rx, y: 0), endPoint: CGPoint(x: rx + ww, y: 0)))
                c.fill(Path(CGRect(x: rx, y: ry, width: ww, height: 1.2 * u)), with: .color(RGB(0.95, 0.65, 0.45).color(0.55)))
                // Brick pattern.
                var b = Path()
                var bx = rx
                while bx < rx + ww { b.move(to: CGPoint(x: bx, y: ry + 1.2 * u)); b.addLine(to: CGPoint(x: bx, y: ry + sh)); bx += 3.4 * u }
                c.stroke(b, with: .color(.black.opacity(0.14)), lineWidth: 0.35 * u)
            }
            // Stairs and a doorway.
            let cx = x + w0 / 2
            c.fill(Path { p in p.move(to: CGPoint(x: cx - 3 * u, y: hy + 4 * u)); p.addLine(to: CGPoint(x: cx - 1.2 * u, y: hy + 4 * u - CGFloat(steps) * sh)); p.addLine(to: CGPoint(x: cx + 1.2 * u, y: hy + 4 * u - CGFloat(steps) * sh)); p.addLine(to: CGPoint(x: cx + 3 * u, y: hy + 4 * u)); p.closeSubpath() },
                   with: .color(RGB(0.95, 0.75, 0.55).color(0.8)))
            var door = Path()
            door.move(to: CGPoint(x: cx - 3 * u, y: hy + 4 * u)); door.addLine(to: CGPoint(x: cx - 3 * u, y: hy - 3 * u)); door.addQuadCurve(to: CGPoint(x: cx + 3 * u, y: hy - 3 * u), control: CGPoint(x: cx, y: hy - 9 * u)); door.addLine(to: CGPoint(x: cx + 3 * u, y: hy + 4 * u)); door.closeSubpath()
            c.fill(door, with: .color(RGB(0.1, 0.05, 0.05).color()))
            // Banner on the top.
            let top = hy + 4 * u - CGFloat(steps) * sh
            c.stroke(Path { $0.move(to: CGPoint(x: cx, y: top)); $0.addLine(to: CGPoint(x: cx, y: top - 9 * u)) }, with: .color(.black.opacity(0.6)), lineWidth: 0.6 * u)
            let wave = CGFloat(sin(t * 2.5 + Double(i))) * 0.8 * u
            c.fill(Path { p in p.move(to: CGPoint(x: cx, y: top - 9 * u)); p.addQuadCurve(to: CGPoint(x: cx + 7 * u, y: top - 7.5 * u + wave), control: CGPoint(x: cx + 3.5 * u, y: top - 10.5 * u)); p.addLine(to: CGPoint(x: cx, y: top - 5 * u)); p.closeSubpath() },
                   with: .color(RGB(0.92, 0.76, 0.2).color()))
        }
    }
}
