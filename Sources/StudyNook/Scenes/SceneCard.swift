import SwiftUI
import StudyNookCore

/// Scene card in the expanded island.
/// Two layers keep the battery happy: the slow background is redrawn once a second,
/// the foreground at 20 fps (12 fps with Low Power Mode or Reduce Motion), and nothing is drawn while the screen sleeps.
struct SceneCard: View {
    let engine: PomodoroEngine
    let model: NotchViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let phase = engine.phase
        let chapter = engine.chapter
        let total = max(1, engine.duration(of: phase))
        let slow = reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
        ZStack {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let p = engine.progress(at: ctx.date)
                Canvas(opaque: true) { c, size in
                    StoryScenes.background(c, SceneEnv(size: size, t: 0, p: p, total: total), phase: phase, chapter: chapter)
                }
            }
            TimelineView(.animation(minimumInterval: slow ? 1.0 / 12.0 : 1.0 / 20.0, paused: !model.isAwake)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 86_400) * (reduceMotion ? 0.3 : 1)
                let p = engine.progress(at: ctx.date)
                Canvas { c, size in
                    StoryScenes.foreground(c, SceneEnv(size: size, t: t, p: p, total: total), phase: phase, chapter: chapter)
                }
            }
        }
        .id("\(phase.rawValue)-\(chapter.rawValue)")
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.6), value: phase)
    }
}
