import SwiftUI

/// Notch-like shape: the top corners flare outward (concave), the bottom corners are rounded.
/// Both radii are animatable, so collapsed ↔ expanded morphs smoothly.
struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set { topRadius = newValue.first; bottomRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let top = min(topRadius, w / 4, h / 2)
        let bottom = min(bottomRadius, (w - top * 2) / 2, h - top)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX + top, y: rect.minY + top),
                       control: CGPoint(x: rect.minX + top, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + top, y: rect.minY + h - bottom))
        p.addQuadCurve(to: CGPoint(x: rect.minX + top + bottom, y: rect.minY + h),
                       control: CGPoint(x: rect.minX + top, y: rect.minY + h))
        p.addLine(to: CGPoint(x: rect.minX + w - top - bottom, y: rect.minY + h))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w - top, y: rect.minY + h - bottom),
                       control: CGPoint(x: rect.minX + w - top, y: rect.minY + h))
        p.addLine(to: CGPoint(x: rect.minX + w - top, y: rect.minY + top))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w, y: rect.minY),
                       control: CGPoint(x: rect.minX + w - top, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
