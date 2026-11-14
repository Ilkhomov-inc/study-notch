import SwiftUI
import StudyNookCore

/// Scene card in the expanded island.
/// Two layers keep the battery happy: the slow background is redrawn twice a second,
/// the foreground at 15 fps (10 fps with Low Power Mode or Reduce Motion), and nothing is drawn while the screen sleeps.
/// While a chapter is being watched again, the replay decides what to draw instead of the timer.
struct SceneCard: View {
    let engine: PomodoroEngine
    let model: NotchViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func frame(_ date: Date) -> (phase: Phase, chapter: Chapter, p: Double, total: Double) {
        if let replay = model.replay {
            let f = replay.frame(at: date)
            return (f.phase, replay.chapter, f.p, f.total)
        }
        let phase = engine.phase
        return (phase, engine.chapter, engine.progress(at: date), max(1, engine.duration(of: phase)))
    }

    var body: some View {
        let slow = reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
        let identity = model.replay.map { "replay-\($0.chapter.rawValue)-\($0.started.timeIntervalSince1970)" }
            ?? "\(engine.phase.rawValue)-\(engine.chapter.rawValue)"
        ZStack {
            TimelineView(.animation(minimumInterval: 0.5, paused: !model.isAwake)) { ctx in
                let f = frame(ctx.date)
                Canvas(opaque: true) { c, size in
                    StoryScenes.background(c, SceneEnv(size: size, t: 0, p: f.p, total: f.total), phase: f.phase, chapter: f.chapter)
                }
            }
            TimelineView(.animation(minimumInterval: slow ? 1.0 / 10.0 : 1.0 / 15.0, paused: !model.isAwake)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 86_400) * (reduceMotion ? 0.3 : 1)
                let f = frame(ctx.date)
                Canvas { c, size in
                    StoryScenes.foreground(c, SceneEnv(size: size, t: t, p: f.p, total: f.total), phase: f.phase, chapter: f.chapter)
                }
            }
        }
        .id(identity)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.6), value: identity)
    }
}
