import SwiftUI
import StudyNookCore

/// Picks the scene for the current phase and chapter.
/// Every scene is split into a slow `background` (sky, ground, buildings: redrawn about once a second)
/// and a fast `foreground` (actors, fire, particles: redrawn at the frame rate).
enum StoryScenes {
    static func background(_ c: GraphicsContext, _ env: SceneEnv, phase: Phase, chapter ch: Chapter) {
        switch phase {
        case .idle where ch == .birth:
            break // the idle night scene is drawn in one piece in the foreground
        case .idle:
            journeyBackground(c, env, ch)
        case .journey:
            journeyBackground(c, env, ch)
        case .arrival:
            journeyBackground(c, SceneEnv(size: env.size, t: env.t, p: 1, total: env.total), ch)
        case .choice, .rest:
            RestStory.background(c, env, ch)
        }
    }

    static func foreground(_ c: GraphicsContext, _ env: SceneEnv, phase: Phase, chapter ch: Chapter) {
        switch phase {
        case .idle where ch == .birth:
            IdlePainter.draw(c, size: env.size, t: env.t, ready: false)
        case .idle:
            journeyForeground(c, SceneEnv(size: env.size, t: env.t, p: 0.02, total: env.total), ch)
        case .journey:
            journeyForeground(c, env, ch)
        case .arrival:
            journeyForeground(c, SceneEnv(size: env.size, t: env.t, p: 1, total: env.total), ch)
            banner(c, env, ch)
        case .choice, .rest:
            RestStory.foreground(c, env, ch)
        }
    }

    private static func journeyBackground(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
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

    private static func journeyForeground(_ c: GraphicsContext, _ env: SceneEnv, _ ch: Chapter) {
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
