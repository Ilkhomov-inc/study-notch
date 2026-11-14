import SwiftUI
import StudyNookCore

enum Theme {
    /// Apple Clock timer orange.
    static let focus = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let rest = Color(red: 0.39, green: 0.85, blue: 0.80)

    static func accent(_ phase: Phase) -> Color {
        switch phase {
        case .journey, .arrival: focus
        case .rest: rest
        case .idle, .choice: .white
        }
    }

    static func title(_ phase: Phase, chapter: Chapter) -> String {
        switch phase {
        case .idle: "ГОТОВ"
        case .journey: "ГЛАВА \(chapter.number)"
        case .arrival: "ПРИБЫТИЕ"
        case .choice: "ВЫБОР"
        case .rest: "ОТДЫХ"
        }
    }

    static func label(_ phase: Phase, chapter: Chapter, paused: Bool) -> String {
        switch phase {
        case .idle: "Глава \(chapter.number) · \(chapter.title)"
        case .journey: paused ? "Пауза · \(chapter.title)" : chapter.title
        case .arrival: "Глава \(chapter.number) пройдена"
        case .choice: "Что дальше?"
        case .rest: "Отдых · \(chapter.title)"
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
            // Collapsed: the clock only needs to change once a second.
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let left = phase == .arrival ? 0 : engine.remaining(at: ctx.date)
                // No digit animation here: it would redraw the text at display rate every second.
                Text(phase == .choice ? "выбор" : TimeText.mmss(left))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accent)
            }
            .frame(width: NotchLayout.wing - NotchLayout.collapsedTopRadius)
        }
        .padding(.horizontal, NotchLayout.collapsedTopRadius)
        .frame(height: model.metrics.notchHeight)
    }

    @ViewBuilder
    private func leading(_ phase: Phase, _ accent: Color) -> some View {
        if phase == .journey {
            MiniDragonView(color: accent, paused: engine.isPaused, awake: model.isAwake)
        } else {
            let symbol = switch phase {
            case .arrival: "flame.fill"
            case .rest: "heart.fill"
            default: "sparkles"
            }
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
        }
    }
}

// MARK: - Expanded: scene on top, Apple Clock style timer below

struct ExpandedContent: View {
    let engine: PomodoroEngine
    let model: NotchViewModel

    var body: some View {
        let phase = engine.phase
        let chapter = engine.chapter
        let accent = Theme.accent(phase)
        let nextMinutes = engine.nextJourneyIsFixed ? PomodoroEngine.firstJourneyMinutes : model.journeyMinutes
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    HStack(spacing: 6) {
                        ProgressRing(remaining: 1 - engine.progress(at: ctx.date), color: accent)
                            .frame(width: 13, height: 13)
                        Text(Theme.title(phase, chapter: chapter))
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .tracking(0.6)
                            .foregroundStyle(accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: model.metrics.notchWidth + 8)
                // Tap the eggs for statistics and chapters to watch again.
                Button { model.showStats.toggle() } label: {
                    HStack(spacing: 5) {
                        EggCounter(flights: engine.flightsToday)
                        Image(systemName: model.showStats ? "xmark.circle.fill" : "chart.bar.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 26)
            .frame(height: model.metrics.notchHeight)

            Group {
                if model.showStats && model.replay == nil {
                    StatsPanel(engine: engine, model: model)
                } else {
                    SceneCard(engine: engine, model: model)
                }
            }
                .frame(height: NotchLayout.sceneHeight)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 4)

            Group {
                if let replay = model.replay {
                    ReplayBar(replay: replay, model: model)
                } else if phase == .choice {
                    ChoiceView(engine: engine, model: model)
                } else {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: -2) {
                            Text(Theme.label(phase, chapter: chapter, paused: engine.isPaused))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                            TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
                                let left = phase == .arrival ? 0
                                    : phase == .idle ? TimeInterval(nextMinutes) * engine.durations.secondsPerMinute
                                    : engine.remaining(at: ctx.date)
                                Text(TimeText.mmss(left))
                                    .font(.system(size: 38, weight: .light, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(accent)
                            }
                        }
                        Spacer(minLength: 0)
                        Controls(engine: engine, model: model)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .frame(width: model.expandedSize.width, height: model.expandedSize.height, alignment: .top)
        .onDisappear { model.showStats = false }
    }
}

/// Round buttons like the Apple timer: grey ✕ and orange pause/start.
struct Controls: View {
    let engine: PomodoroEngine
    let model: NotchViewModel

    var body: some View {
        HStack(spacing: 12) {
            switch engine.phase {
            case .idle:
                CircleButton(symbol: "play.fill", tint: Theme.focus) {
                    engine.startJourney(minutes: model.journeyMinutes)
                }
            case .journey:
                CircleButton(symbol: "xmark", tint: .white, fill: .white.opacity(0.14)) { engine.cancel() }
                CircleButton(symbol: engine.isPaused ? "play.fill" : "pause.fill", tint: Theme.focus) { engine.togglePause() }
            case .rest:
                Button { engine.endRestEarly() } label: {
                    Label("Закончить отдых", systemImage: "forward.end.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.rest)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.rest.opacity(0.16)))
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableStyle())
            case .arrival, .choice:
                Label("Прибытие…", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.focus)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.focus.opacity(0.15)))
            }
        }
        .animation(NotchLayout.spring, value: engine.phase)
    }
}

/// After a journey: "В путь" or "Отдых", each with its own minute chips.
struct ChoiceView: View {
    let engine: PomodoroEngine
    let model: NotchViewModel

    var body: some View {
        let fixed = engine.nextJourneyIsFixed
        HStack(alignment: .top, spacing: 14) {
            column(
                title: "В путь",
                symbol: "figure.walk.motion",
                tint: Theme.focus,
                options: fixed ? [PomodoroEngine.firstJourneyMinutes] : PomodoroEngine.journeyOptions,
                selection: fixed ? PomodoroEngine.firstJourneyMinutes : model.journeyMinutes
            ) { m in
                model.journeyMinutes = m
            } go: {
                engine.startJourney(minutes: model.journeyMinutes)
            }
            column(
                title: "Отдых",
                symbol: "moon.stars.fill",
                tint: Theme.rest,
                options: PomodoroEngine.restOptions,
                selection: model.restMinutes
            ) { m in
                model.restMinutes = m
            } go: {
                engine.startRest(minutes: model.restMinutes)
            }
        }
    }

    private func column(
        title: String, symbol: String, tint: Color, options: [Int], selection: Int,
        pick: @escaping (Int) -> Void, go: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 6) {
            Button(action: go) {
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                    Text("\(title) · \(selection) мин")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Capsule().fill(tint.opacity(0.2)))
                .contentShape(Capsule())
            }
            .buttonStyle(PressableStyle())

            HStack(spacing: 5) {
                ForEach(options, id: \.self) { m in
                    Button { pick(m) } label: {
                        // With a single option the chip explains why: the first journey of the day is always 25.
                        Text(options.count == 1 ? "\(m) · первый путь дня" : "\(m)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(m == selection ? .black : .white.opacity(0.7))
                            .padding(.horizontal, options.count == 1 ? 6 : 0)
                            .frame(minWidth: 26)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(m == selection ? tint : .white.opacity(0.12)))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
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

/// Dragon eggs: one per completed journey today.
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
        .help("Путей сегодня: \(flights)")
    }
}
