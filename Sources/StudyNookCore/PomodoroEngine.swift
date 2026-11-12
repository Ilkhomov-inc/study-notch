import Foundation
import Observation

/// Phases of the day.
/// `idle → journey → arrival → choice → (journey | rest) → …`
public enum Phase: String, Sendable, CaseIterable {
    /// Nothing is running; the next chapter waits to be started.
    case idle
    /// A timed journey: one chapter of the story. Can be paused or cancelled.
    case journey
    /// A few seconds of arrival animation after the journey. Cannot be interrupted.
    case arrival
    /// The user decides: keep going or rest.
    case choice
    /// Optional rest scene. Can be ended early.
    case rest
}

@MainActor
@Observable
public final class PomodoroEngine {
    public struct Durations: Sendable, Equatable {
        /// Real seconds per timer "minute". 60 normally, smaller for quick checks.
        public var secondsPerMinute: TimeInterval
        public var arrival: TimeInterval

        public init(secondsPerMinute: TimeInterval, arrival: TimeInterval) {
            self.secondsPerMinute = secondsPerMinute
            self.arrival = arrival
        }

        public static let standard = Durations(secondsPerMinute: 60, arrival: 4.5)
        public static let fast = Durations(secondsPerMinute: 0.8, arrival: 4.5)
    }

    /// The first journey of the day is always exactly this long.
    public static let firstJourneyMinutes = 25
    public static let journeyOptions = [15, 25, 45, 60]
    public static let restOptions = [5, 10, 15]

    public private(set) var phase: Phase = .idle
    public private(set) var isPaused = false
    public private(set) var flightsToday = 0
    /// Chapter shown right now: the one being played, or the one just finished (its rest scene), or the next one when idle.
    public private(set) var chapter: Chapter = .birth
    public private(set) var plannedMinutes = PomodoroEngine.firstJourneyMinutes
    public let durations: Durations

    @ObservationIgnored public let story: StoryProgress
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let log: FlightLog
    @ObservationIgnored private var lastDayCheckMinute = -1

    private var phaseEnd: Date?
    private var pausedRemaining: TimeInterval?

    /// Called on every phase change with (old, new).
    @ObservationIgnored public var onPhaseChange: ((Phase, Phase) -> Void)?

    public init(
        durations: Durations = .standard,
        now: @escaping () -> Date = Date.init,
        log: FlightLog = FlightLog(),
        story: StoryProgress = StoryProgress()
    ) {
        self.durations = durations
        self.now = now
        self.log = log
        self.story = story
        self.flightsToday = log.count(on: now())
        self.chapter = story.current
    }

    // MARK: - Reading

    /// True while the next journey must be exactly 25 minutes (the first one of the day).
    public var nextJourneyIsFixed: Bool { flightsToday == 0 }

    public func duration(of phase: Phase) -> TimeInterval {
        switch phase {
        case .journey, .rest: TimeInterval(plannedMinutes) * durations.secondsPerMinute
        case .arrival: durations.arrival
        case .idle, .choice: 0
        }
    }

    /// Time left in the current phase. In idle/choice it is the length of the planned journey.
    public func remaining(at date: Date? = nil) -> TimeInterval {
        if let pausedRemaining { return pausedRemaining }
        guard let phaseEnd else {
            return phase == .idle || phase == .choice ? TimeInterval(plannedMinutes) * durations.secondsPerMinute : 0
        }
        return max(0, phaseEnd.timeIntervalSince(date ?? now()))
    }

    /// Progress of the current phase, 0...1.
    public func progress(at date: Date? = nil) -> Double {
        let total = duration(of: phase)
        guard total > 0 else { return phase == .choice ? 1 : 0 }
        return min(1, max(0, 1 - remaining(at: date) / total))
    }

    public var canPause: Bool { phase == .journey }
    public var canCancel: Bool { phase == .journey }
    public var canStartJourney: Bool { phase == .idle || phase == .choice }
    public var canRest: Bool { phase == .choice || phase == .idle }
    public var canEndRest: Bool { phase == .rest }

    // MARK: - Actions

    /// Starts the next chapter. The first journey of the day ignores `minutes` and lasts 25.
    public func startJourney(minutes: Int = PomodoroEngine.firstJourneyMinutes) {
        guard canStartJourney else { return }
        let m = nextJourneyIsFixed ? Self.firstJourneyMinutes : max(1, minutes)
        plannedMinutes = m
        chapter = story.current
        begin(.journey, minutes: m, at: now())
    }

    public func startRest(minutes: Int = PomodoroEngine.restOptions[0]) {
        guard canRest else { return }
        let m = max(1, minutes)
        plannedMinutes = m
        begin(.rest, minutes: m, at: now())
    }

    public func endRestEarly() {
        guard phase == .rest else { return }
        phaseEnd = nil
        plannedMinutes = Self.firstJourneyMinutes
        set(.choice)
    }

    public func pause() {
        guard phase == .journey, !isPaused, let phaseEnd else { return }
        pausedRemaining = max(0, phaseEnd.timeIntervalSince(now()))
        self.phaseEnd = nil
        isPaused = true
    }

    public func resume() {
        guard phase == .journey, isPaused, let pausedRemaining else { return }
        phaseEnd = now().addingTimeInterval(pausedRemaining)
        self.pausedRemaining = nil
        isPaused = false
    }

    public func togglePause() {
        isPaused ? resume() : pause()
    }

    /// Cancels a journey. The chapter is not counted and stays the next one.
    public func cancel() {
        guard canCancel else { return }
        phaseEnd = nil
        pausedRemaining = nil
        isPaused = false
        chapter = story.current
        set(.idle)
    }

    /// Advances phases whose time is up. Call it about once a second.
    /// If the Mac slept through several phases, they are all applied in order.
    public func tick() {
        let current = now()
        refreshDayIfNeeded(current)
        var steps = 0
        while let end = phaseEnd, !isPaused, current >= end, steps < 4 {
            steps += 1
            advance(endedAt: end)
        }
    }

    /// Jump into a phase of a chapter with given progress (for snapshots and debugging).
    public func debugJump(to target: Phase, progress: Double, chapter: Chapter, minutes: Int = 25) {
        let p = min(1, max(0, progress))
        self.chapter = chapter
        plannedMinutes = minutes
        switch target {
        case .journey, .rest, .arrival:
            let total = target == .arrival ? durations.arrival : TimeInterval(minutes) * durations.secondsPerMinute
            phaseEnd = now().addingTimeInterval(total * (1 - p))
            pausedRemaining = nil
            isPaused = false
            set(target)
        case .idle, .choice:
            phaseEnd = nil
            pausedRemaining = nil
            isPaused = false
            set(target)
        }
    }

    // MARK: - Private

    private func advance(endedAt end: Date) {
        switch phase {
        case .journey:
            let count = log.increment(on: end)
            if flightsToday != count { flightsToday = count }
            // `chapter` stays the one just finished: arrival and rest scenes belong to it.
            story.advance()
            phaseEnd = end.addingTimeInterval(durations.arrival)
            set(.arrival)
        case .arrival:
            phaseEnd = nil
            plannedMinutes = Self.firstJourneyMinutes
            set(.choice)
        case .rest:
            phaseEnd = nil
            plannedMinutes = Self.firstJourneyMinutes
            set(.choice)
        case .idle, .choice:
            phaseEnd = nil
        }
    }

    private func begin(_ next: Phase, minutes: Int, at start: Date) {
        phaseEnd = start.addingTimeInterval(TimeInterval(minutes) * durations.secondsPerMinute)
        pausedRemaining = nil
        isPaused = false
        set(next)
    }

    private func set(_ next: Phase) {
        let old = phase
        guard old != next else { return }
        phase = next
        onPhaseChange?(old, next)
    }

    private func refreshDayIfNeeded(_ date: Date) {
        let minute = Int(date.timeIntervalSinceReferenceDate / 60)
        guard minute != lastDayCheckMinute else { return }
        lastDayCheckMinute = minute
        let count = log.count(on: date)
        if count != flightsToday { flightsToday = count }
    }
}

/// Completed journeys per day, stored in UserDefaults.
public struct FlightLog {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func count(on date: Date) -> Int {
        defaults.integer(forKey: key(for: date))
    }

    @discardableResult
    public func increment(on date: Date) -> Int {
        let next = count(on: date) + 1
        defaults.set(next, forKey: key(for: date))
        return next
    }

    private func key(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "flights.%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
