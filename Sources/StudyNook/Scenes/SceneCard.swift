import SwiftUI
import StudyNookCore

/// Scene card in the expanded island. Redrawn every frame while the island is open.
struct SceneCard: View {
    let engine: PomodoroEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let phase = engine.phase
        let paused = engine.isPaused
        TimelineView(.animation) { ctx in
            let date = ctx.date
            let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 86_400) * (reduceMotion ? 0.3 : 1)
            let p = engine.progress(at: date)
            Canvas { c, size in
                switch phase {
                case .idle:
                    IdlePainter.draw(c, size: size, t: t, ready: false)
                case .restDone:
                    IdlePainter.draw(c, size: size, t: t, ready: true)
                case .focus:
                    FlightPainter.draw(c, size: size, progress: p, t: t, paused: paused, arrival: nil)
                case .arrival:
                    FlightPainter.draw(c, size: size, progress: 1, t: t, paused: false, arrival: p)
                case .rest:
                    RestPainter.draw(c, size: size, progress: p, t: t)
                }
            }
            .id(phase)
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.7), value: phase)
    }
}
