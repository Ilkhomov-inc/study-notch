import SwiftUI
import StudyNookCore

/// Watching a finished chapter again: about a minute of its journey, then its event, then the quiet scene.
/// It does not touch the timer or the story progress.
struct Replay: Equatable {
    let chapter: Chapter
    let started: Date

    static let journeyLength = 22.0
    static let eventLength = 26.0
    static let quietLength = 8.0
    static var total: Double { journeyLength + eventLength + quietLength }

    /// Which scene to draw at `date`, with its progress and the length that scene "pretends" to have.
    func frame(at date: Date) -> (phase: Phase, p: Double, total: Double) {
        let e = max(0, date.timeIntervalSince(started))
        if e < Self.journeyLength {
            return (.journey, e / Self.journeyLength, Self.journeyLength)
        }
        let r = e - Self.journeyLength
        let share = StoryScenes.eventShare
        if StoryScenes.eventRange(chapter) != nil {
            if r < Self.eventLength {
                return (.rest, share * r / Self.eventLength, Self.eventLength / share)
            }
            let q = min(1, (r - Self.eventLength) / Self.quietLength)
            return (.rest, share + (1 - share) * 0.6 * q, Self.eventLength / share)
        }
        // Chapters without an event (and the burning of King's Landing): the rest scene the whole time.
        let rest = Self.eventLength + Self.quietLength
        return (.rest, min(1, r / rest), rest)
    }

    func progress(at date: Date) -> Double { M.clamp01(date.timeIntervalSince(started) / Self.total) }
}

/// Statistics in the island: today, this week, a bar per day, and finished chapters to watch again.
struct StatsPanel: View {
    let engine: PomodoroEngine
    let model: NotchViewModel

    private static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.setLocalizedDateFormatFromTemplate("EEEEEE")
        return f
    }()

    var body: some View {
        // Reading flightsToday makes the panel refresh when a chapter is finished.
        let _ = engine.flightsToday
        let week = engine.history(days: 7)
        let weekChapters = week.reduce(0) { $0 + $1.chapters }
        let weekMinutes = week.reduce(0) { $0 + $1.minutes }
        let today = week.last ?? DayStat(date: Date(), chapters: 0, minutes: 0)
        let peak = max(25, week.map(\.minutes).max() ?? 0)

        HStack(alignment: .top, spacing: 14) {
            // Numbers.
            VStack(alignment: .leading, spacing: 6) {
                stat(title: "СЕГОДНЯ", main: "\(today.chapters)", unit: chaptersWord(today.chapters), detail: minutesText(today.minutes))
                stat(title: "НЕДЕЛЯ", main: "\(weekChapters)", unit: chaptersWord(weekChapters), detail: minutesText(weekMinutes))
            }
            .frame(width: 118, alignment: .leading)

            // A bar per day: height = minutes, number on top = chapters.
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(week.enumerated()), id: \.offset) { i, day in
                    let isToday = i == week.count - 1
                    VStack(spacing: 3) {
                        Text(day.chapters > 0 ? "\(day.chapters)" : " ")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(isToday ? Theme.focus : .white.opacity(0.7))
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(isToday ? AnyShapeStyle(Theme.focus) : AnyShapeStyle(Color.white.opacity(day.minutes > 0 ? 0.45 : 0.12)))
                            .frame(width: 12, height: max(3, 54 * CGFloat(day.minutes) / CGFloat(peak)))
                        Text(Self.weekday.string(from: day.date).capitalized)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(isToday ? Theme.focus : .white.opacity(0.5))
                    }
                }
            }
            .frame(height: 86, alignment: .bottom)

            // Finished chapters to watch again.
            VStack(alignment: .leading, spacing: 5) {
                Text("ПЕРЕСМОТРЕТЬ")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.55))
                let chapters = engine.watchedChapters
                if chapters.isEmpty {
                    Text("Пройдите первую главу, и её можно будет посмотреть снова.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 5)], alignment: .leading, spacing: 5) {
                            ForEach(chapters, id: \.rawValue) { ch in
                                Button { model.startReplay(ch) } label: {
                                    HStack(spacing: 4) {
                                        Text("\(ch.number)").font(.system(size: 10, weight: .heavy, design: .rounded)).foregroundStyle(Theme.focus)
                                        Text(ch.title).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(.white).lineLimit(1)
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Capsule().fill(.white.opacity(0.1)))
                                    .contentShape(Capsule())
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(white: 0.11))
    }

    private func stat(title: String, main: String, unit: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.55))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(main).font(.system(size: 24, weight: .light, design: .rounded)).monospacedDigit().foregroundStyle(.white)
                Text(unit).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.7))
            }
            Text(detail).font(.system(size: 10.5, weight: .medium, design: .rounded)).foregroundStyle(Theme.focus)
        }
    }

    private func chaptersWord(_ n: Int) -> String {
        let r10 = n % 10, r100 = n % 100
        if r10 == 1 && r100 != 11 { return "глава" }
        if (2...4).contains(r10) && !(12...14).contains(r100) { return "главы" }
        return "глав"
    }

    private func minutesText(_ m: Int) -> String {
        m >= 60 ? "\(m / 60) ч \(m % 60) мин учёбы" : "\(m) мин учёбы"
    }
}

/// Bottom row while a chapter is being watched again.
struct ReplayBar: View {
    let replay: Replay
    let model: NotchViewModel

    var body: some View {
        HStack(spacing: 12) {
            TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
                ProgressRing(remaining: 1 - replay.progress(at: ctx.date), color: Theme.focus)
                    .frame(width: 22, height: 22)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("ПЕРЕСМОТР")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Theme.focus)
                Text("Глава \(replay.chapter.number) · \(replay.chapter.title)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            CircleButton(symbol: "xmark", tint: .white, fill: .white.opacity(0.14)) { model.stopReplay() }
        }
    }
}
