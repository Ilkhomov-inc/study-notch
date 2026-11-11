import Foundation
import Observation

/// Pomodoro phases.
/// `idle → focus → arrival → rest → restDone → (start) focus …`
public enum Phase: String, Sendable, CaseIterable {
    /// Nothing is running yet; the dragon is still an egg on Dragonstone.
    case idle
    /// 25 minutes of focus: the dragon flies to King's Landing. Can be paused or cancelled.
    case focus
    /// A few seconds of landing animation. Cannot be interrupted.
    case arrival
    /// Mandatory 5-minute rest with Daenerys. No pause, no skip.
    case rest
    /// Rest is over; waiting for the user to start the next flight.
    case restDone
}

@MainActor
@Observable
public final class PomodoroEngine {
    public struct Durations: Sendable, Equatable {
        public var focus: TimeInterval
        public var arrival: TimeInterval
        public var rest: TimeInterval

        public init(focus: TimeInterval, arrival: TimeInterval, rest: TimeInterval) {
            self.focus = focus
            self.arrival = arrival
            self.rest = rest
        }

        public static let standard = Durations(focus: 25 * 60, arrival: 4.5, rest: 5 * 60)
        public static let fast = Durations(focus: 20, arrival: 4.5, rest: 10)
    }

    public private(set) var phase: Phase = .idle
    public private(set) var isPaused = false
    public private(set) var flightsToday = 0
    public let durations: Durations

    /// When the current timed phase ends (nil while paused or in an untimed phase).
    private var phaseEnd: Date?
    /// Time left in focus while paused.
    private var pausedRemaining: TimeInterval?

    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let log: FlightLog
    @ObservationIgnored private var lastDayCheckMinute = -1

    /// Called on every phase change with (old, new).
    @ObservationIgnored public var onPhaseChange: ((Phase, Phase) -> Void)?

    public init(
        durations: Durations = .standard,
        now: @escaping () -> Date = Date.init,
        log: FlightLog = FlightLog()
    ) {
        self.durations = durations
        self.now = now
        self.log = log
        self.flightsToday = log.count(on: now())
    }

    // MARK: - Reading

    public func duration(of phase: Phase) -> TimeInterval {
        switch phase {
        case .focus: durations.focus
        case .arrival: durations.arrival
        case .rest: durations.rest
        case .idle, .restDone: 0
        }
    }

    /// Time left in the current phase. In idle/restDone it is the length of the next flight.
    public func remaining(at date: Date? = nil) -> TimeInterval {
        if let pausedRemaining { return pausedRemaining }
        guard let phaseEnd else {
            return (phase == .idle || phase == .restDone) ? durations.focus : 0
        }
        return max(0, phaseEnd.timeIntervalSince(date ?? now()))
    }

    /// Progress of the current phase, 0...1.
    public func progress(at date: Date? = nil) -> Double {
        let total = duration(of: phase)
        guard total > 0 else { return phase == .restDone ? 1 : 0 }
        return min(1, max(0, 1 - remaining(at: date) / total))
    }

    public var canPause: Bool { phase == .focus }
    public var canCancel: Bool { phase == .focus || phase == .restDone }
    public var canStart: Bool { phase == .idle || phase == .restDone }

    // MARK: - Actions

    public func start() {
        guard canStart else { return }
        begin(.focus, at: now())
    }

    public func pause() {
        guard phase == .focus, !isPaused, let phaseEnd else { return }
        pausedRemaining = max(0, phaseEnd.timeIntervalSince(now()))
        self.phaseEnd = nil
        isPaused = true
    }

    public func resume() {
        guard phase == .focus, isPaused, let pausedRemaining else { return }
        phaseEnd = now().addingTimeInterval(pausedRemaining)
        self.pausedRemaining = nil
        isPaused = false
    }

    public func togglePause() {
        isPaused ? resume() : pause()
    }

    /// Cancels a flight or dismisses the "one more flight?" prompt.
    /// Does nothing during arrival and rest: rest is mandatory.
    public func cancel() {
        guard canCancel else { return }
        phaseEnd = nil
        pausedRemaining = nil
        isPaused = false
        set(.idle)
    }

    /// Advances phases whose time is up. Call it a few times per second.
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

    /// Jump into a phase with given progress (for screenshots and debugging).
    public func debugJump(to target: Phase, progress: Double) {
        let p = min(1, max(0, progress))
        switch target {
        case .focus, .arrival, .rest:
            begin(target, at: now().addingTimeInterval(-duration(of: target) * p))
        case .idle, .restDone:
            phaseEnd = nil
            pausedRemaining = nil
            isPaused = false
            set(target)
        }
    }

    // MARK: - Private

    private func advance(endedAt end: Date) {
        switch phase {
        case .focus:
            let count = log.increment(on: end)
            if flightsToday != count { flightsToday = count }
            begin(.arrival, at: end)
        case .arrival:
            begin(.rest, at: end)
        case .rest:
            phaseEnd = nil
            set(.restDone)
        case .idle, .restDone:
            phaseEnd = nil
        }
    }

    private func begin(_ next: Phase, at start: Date) {
        phaseEnd = start.addingTimeInterval(duration(of: next))
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

/// Completed flights per day, stored in UserDefaults.
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
