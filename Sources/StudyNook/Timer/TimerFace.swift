import SwiftUI
import StudyNookCore

enum Theme {
    /// Apple Clock timer orange.
    static let focus = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let rest = Color(red: 0.39, green: 0.85, blue: 0.80)

    static func accent(_ phase: Phase) -> Color {
        switch phase {
        case .focus, .arrival: focus
        case .rest: rest
        case .idle, .restDone: .white
        }
    }

    static func title(_ phase: Phase) -> String {
        switch phase {
        case .idle: "ГОТОВ"
        case .focus: "ФОКУС"
        case .arrival: "ПРИЛЁТ"
        case .rest: "ОТДЫХ"
        case .restDone: "ОТДОХНУЛИ"
        }
    }

    static func label(_ phase: Phase, paused: Bool) -> String {
        switch phase {
        case .idle: "Драконий Камень · готов к полёту"
        case .focus: paused ? "Дракон парит · пауза" : "Полёт в Королевскую Гавань"
        case .arrival: "Королевская Гавань!"
        case .rest: "Отдых с Дейенерис"
        case .restDone: "Ещё полёт?"
        }
    }
}

// MARK: - Collapsed: wings to the left and right of the notch

struct CompactContent: View {
    let engine: PomodoroEngine
    let model: NotchViewModel

    var body: some View {
        let phase = engine.phase
        let accent = Theme.accent(phase)
        HStack(spacing: 0) {
            leading(phase, accent)
                .frame(width: NotchLayout.wing - NotchLayout.collapsedTopRadius)
            Color.clear.frame(width: model.metrics.notchWidth)
            TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
                let left = phase == .arrival ? 0 : engine.remaining(at: ctx.date)
                Text(phase == .restDone ? "готово" : TimeText.mmss(left))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accent)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: Int(ceil(left)))
                    .scaleEffect(phase == .focus && left < 10 && left > 0 ? 1 + 0.08 * (1 - M.fract(left)) : 1)
            }
            .frame(width: NotchLayout.wing - NotchLayout.collapsedTopRadius)
        }
        .padding(.horizontal, NotchLayout.collapsedTopRadius)
        .frame(height: model.metrics.notchHeight)
    }

    @ViewBuilder
    private func leading(_ phase: Phase, _ accent: Color) -> some View {
        if phase == .focus {
            MiniDragonView(color: accent, paused: engine.isPaused)
        } else {
            let symbol = switch phase {
            case .arrival: "flame.fill"
            case .rest: "heart.fill"
            default: "sparkles"
            }
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .symbolEffect(.pulse, isActive: phase == .rest || phase == .arrival)
        }
    }
}

// MARK: - Expanded: scene on top, Apple Clock style timer below

struct ExpandedContent: View {
    let engine: PomodoroEngine
    let model: NotchViewModel

    var body: some View {
        let phase = engine.phase
        let accent = Theme.accent(phase)
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
                    HStack(spacing: 6) {
                        ProgressRing(remaining: 1 - engine.progress(at: ctx.date), color: accent)
                            .frame(width: 13, height: 13)
                        Text(Theme.title(phase))
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .tracking(0.6)
                            .foregroundStyle(accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: model.metrics.notchWidth + 8)
                EggCounter(flights: engine.flightsToday)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 26)
            .frame(height: model.metrics.notchHeight)

            SceneCard(engine: engine)
                .frame(height: NotchLayout.sceneHeight)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 4)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: -2) {
                    Text(Theme.label(phase, paused: engine.isPaused))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
                        // Landing is not part of the 25 minutes: the focus clock stays at zero.
                        let left = phase == .arrival ? 0 : engine.remaining(at: ctx.date)
                        Text(TimeText.mmss(left))
                            .font(.system(size: 38, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(accent)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.snappy, value: Int(ceil(left)))
                    }
                }
                Spacer(minLength: 0)
                Controls(engine: engine)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .frame(width: model.expandedSize.width, height: model.expandedSize.height, alignment: .top)
    }
}

/// Round buttons like the Apple timer: grey ✕ and orange pause/start.
struct Controls: View {
    let engine: PomodoroEngine

    var body: some View {
        HStack(spacing: 12) {
            switch engine.phase {
            case .idle:
                CircleButton(symbol: "play.fill", tint: Theme.focus) { engine.start() }
            case .restDone:
                CircleButton(symbol: "xmark", tint: .white, fill: .white.opacity(0.14)) { engine.cancel() }
                CircleButton(symbol: "play.fill", tint: Theme.focus) { engine.start() }
            case .focus:
                CircleButton(symbol: "xmark", tint: .white, fill: .white.opacity(0.14)) { engine.cancel() }
                CircleButton(symbol: engine.isPaused ? "play.fill" : "pause.fill", tint: Theme.focus) { engine.togglePause() }
            case .arrival, .rest:
                Label(engine.phase == .arrival ? "Посадка…" : "Отдых обязателен", systemImage: "lock.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.rest)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.rest.opacity(0.15)))
            }
        }
        .animation(NotchLayout.spring, value: engine.phase)
    }
}

struct CircleButton: View {
    let symbol: String
    let tint: Color
    var fill: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 46, height: 46)
                .background(Circle().fill(fill ?? tint.opacity(0.22)))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Ring that empties as time runs out, like in Clock.
struct ProgressRing: View {
    let remaining: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.25), lineWidth: 2.2)
            Circle()
                .trim(from: 0, to: remaining)
                .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

/// Dragon eggs: one per completed flight today.
struct EggCounter: View {
    let flights: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(4, min(flights, 8)), id: \.self) { i in
                EggShape()
                    .fill(i < flights
                          ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.95, green: 0.42, blue: 0.2), Color(red: 0.45, green: 0.08, blue: 0.06)], startPoint: .top, endPoint: .bottom))
                          : AnyShapeStyle(Color.clear))
                    .overlay(EggShape().stroke(.white.opacity(i < flights ? 0 : 0.3), lineWidth: 1))
                    .frame(width: 8, height: 10.5)
            }
        }
        .help("Полётов сегодня: \(flights)")
    }
}
