import SwiftUI
import StudyNookCore

/// Picks the scene for the current phase and chapter.
/// Every scene is split into a slow `background` (sky, ground, buildings: redrawn about once a second)
/// and a fast `foreground` (actors, fire, particles: redrawn at the frame rate).
enum StoryScenes {
    // MARK: - Road and event

    /// While the timer runs only the road is shown: the army marches, ships sail, dragons fly.
    /// The action of the chapter (fire, battles, fallen dragons) plays at the start of the rest.
    static let eventShare = 0.55

    /// Part of the chapter's timeline shown as the road.
    static func roadRange(_ ch: Chapter) -> ClosedRange<Double> {
        switch ch {
        case .birth: 0...0.44
        case .qarth: 0...0.78
        case .astapor: 0.8...1.0
        default: 0...1
        }
    }

    /// Part of the chapter's timeline shown as the event during the rest. nil: the rest is only the quiet scene.
    static func eventRange(_ ch: Chapter) -> ClosedRange<Double>? {
        switch ch {
        case .birth: 0.45...1
        case .qarth: 0.8...1
        case .astapor: 0.3...0.78
        case .vaesDothrak, .goldenRoad, .beyondWall, .winterfell, .rhaegal: 0...1
        case .epilogue: 0.2...1
        case .meereen, .sailing, .kingsLanding: nil
        }
    }

    static func roadEnv(_ env: SceneEnv, _ ch: Chapter) -> SceneEnv {
        let r = roadRange(ch)
        return SceneEnv(size: env.size, t: env.t, p: r.lowerBound + (r.upperBound - r.lowerBound) * env.p, total: env.total / max(0.05, r.upperBound - r.lowerBound), calm: true)
    }

    /// The event as a scene environment, while it plays (the first part of a rest).
    static func eventEnv(_ env: SceneEnv, _ ch: Chapter) -> SceneEnv? {
        guard env.p < eventShare, let r = eventRange(ch) else { return nil }
        let local = env.p / eventShare
        return SceneEnv(size: env.size, t: env.t, p: r.lowerBound + (r.upperBound - r.lowerBound) * local, total: env.total * eventShare / max(0.05, r.upperBound - r.lowerBound), calm: false)
    }

    static func background(_ c: GraphicsContext, _ env: SceneEnv, phase: Phase, chapter ch: Chapter) {
        switch phase {
        case .idle where ch == .birth:
            break // the idle night scene is drawn in one piece in the foreground
        case .idle:
            Travel.background(c, SceneEnv(size: env.size, t: 0, p: 0, total: 1500), ch)
        case .journey:
            Travel.background(c, env, ch)
        case .arrival:
            Travel.background(c, SceneEnv(size: env.size, t: 0, p: 1, total: 1500), ch)
        case .choice, .rest:
            if let ev = eventEnv(env, ch) { journeyBackground(c, ev, ch) } else { RestStory.background(c, env, ch) }
        }
    }

    static func foreground(_ c: GraphicsContext, _ env: SceneEnv, phase: Phase, chapter ch: Chapter) {
        switch phase {
        case .idle where ch == .birth:
            IdlePainter.draw(c, size: env.size, t: env.t, ready: false)
        case .idle:
            Travel.foreground(c, SceneEnv(size: env.size, t: env.t, p: 0, total: 1500), ch)
        case .journey:
            // The road: the party travels from one place to the next as the timer runs.
            Travel.foreground(c, env, ch)
        case .arrival:
            Travel.foreground(c, SceneEnv(size: env.size, t: env.t, p: 1, total: 1500), ch)
            banner(c, env, ch)
        case .choice, .rest:
            if let ev = eventEnv(env, ch) {
                journeyForeground(c, ev, ch)
            } else {
                RestStory.foreground(c, env, ch)
            }
            // A quick dip to black between the event and the quiet scene.
            if phase == .rest, eventRange(ch) != nil {
                let d = abs(env.p - eventShare), half = 0.75 / env.total
                if d < half { Stage.wash(c, env, RGB(0, 0, 0), 1 - d / half) }
            }
        }
    }

    static func journeyBackground(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
        switch ch {
        case .birth: JourneyEarly.birthBackground(c, env)
        case .qarth: JourneyEarly.qarthBackground(c, env)
        case .astapor: JourneyEarly.astaporBackground(c, env)
        case .vaesDothrak: JourneyEarly.vaesBackground(c, env)
        case .meereen: JourneyLate.meereenBackground(c, env)
        case .sailing: JourneyLate.sailingBackground(c, env)
        case .goldenRoad: JourneyLate.goldenBackground(c, env)
        case .beyondWall: JourneyLate.wallBackground(c, env)
        case .winterfell: JourneyLate.winterfellBackground(c, env)
        case .rhaegal: JourneyLate.rhaegalBackground(c, env)
        case .kingsLanding: JourneyLate.landingBackground(c, env)
        case .epilogue: JourneyLate.epilogueBackground(c, env)
        }
    }

    static func journeyForeground(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
        switch ch {
        case .birth: JourneyEarly.birthForeground(c, env)
        case .qarth: JourneyEarly.qarthForeground(c, env)
        case .astapor: JourneyEarly.astaporForeground(c, env)
        case .vaesDothrak: JourneyEarly.vaesForeground(c, env)
        case .meereen: JourneyLate.meereenForeground(c, env)
        case .sailing: JourneyLate.sailingForeground(c, env)
        case .goldenRoad: JourneyLate.goldenForeground(c, env)
        case .beyondWall: JourneyLate.wallForeground(c, env)
        case .winterfell: JourneyLate.winterfellForeground(c, env)
        case .rhaegal: JourneyLate.rhaegalForeground(c, env)
        case .kingsLanding: JourneyLate.landingForeground(c, env)
        case .epilogue: JourneyLate.epilogueForeground(c, env)
        }
    }

    /// "Глава N пройдена" pops in over the finished scene.
    private static func banner(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
        let u = env.u
        let k = min(1, env.p * 5)
        let s = CGFloat(M.easeOutBack(k))
        var tc = c
        tc.opacity = min(1, k * 2) * (1 - M.smoothstep(0.9, 1, env.p))
        tc.translateBy(x: env.w * 0.5, y: env.h * 0.3)
        tc.scaleBy(x: s, y: s)
        tc.addFilter(.shadow(color: Theme.focus.opacity(0.9), radius: 6 * u))
        tc.draw(Text("Глава \(ch.number) пройдена").font(.system(size: 17 * u, weight: .heavy, design: .rounded)).foregroundStyle(Color.white), at: .zero, anchor: .center)
        tc.draw(Text(ch.title).font(.system(size: 10.5 * u, weight: .semibold, design: .rounded)).foregroundStyle(Color.white.opacity(0.85)),
                at: CGPoint(x: 0, y: 16 * u), anchor: .center)
        for i in 0..<8 {
            let ang = Double(i) / 8 * 2 * .pi + env.t * 0.8
            let rr = (52 + 6 * CGFloat(sin(env.t * 3 + Double(i)))) * u
            tc.fill(Ink.sparkle(CGPoint(x: CGFloat(cos(ang)) * rr, y: CGFloat(sin(ang)) * rr * 0.32), 2.4 * u), with: .color(RGB(1, 0.85, 0.5).color(0.9)))
        }
    }
}
