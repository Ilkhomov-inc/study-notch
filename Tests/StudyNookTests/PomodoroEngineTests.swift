import Foundation
import Testing
@testable import StudyNookCore

@MainActor
final class FakeClock {
    var now = Date(timeIntervalSince1970: 1_800_000_000)
    func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}

@MainActor
private func makeEngine() -> (PomodoroEngine, FakeClock) {
    let clock = FakeClock()
    let defaults = UserDefaults(suiteName: "studynook.tests.\(UUID().uuidString)")!
    let engine = PomodoroEngine(
        durations: .standard,
        now: { clock.now },
        log: FlightLog(defaults: defaults)
    )
    return (engine, clock)
}

@MainActor
@Suite("PomodoroEngine")
struct PomodoroEngineTests {
    @Test("Focus lasts 25 minutes, then landing and a 5-minute rest")
    func fullCycle() {
        let (engine, clock) = makeEngine()
        engine.start()
        #expect(engine.phase == .focus)
        #expect(engine.remaining() == 25 * 60)

        clock.advance(25 * 60 - 1)
        engine.tick()
        #expect(engine.phase == .focus)
        #expect(engine.remaining() == 1)

        clock.advance(1)
        engine.tick()
        #expect(engine.phase == .arrival)

        clock.advance(engine.durations.arrival)
        engine.tick()
        #expect(engine.phase == .rest)
        #expect(engine.remaining() == 5 * 60)

        clock.advance(5 * 60)
        engine.tick()
        #expect(engine.phase == .restDone)
    }

    @Test("Rest cannot be paused, cancelled or skipped")
    func restIsMandatory() {
        let (engine, clock) = makeEngine()
        engine.debugJump(to: .rest, progress: 0.2)
        #expect(!engine.canPause)
        #expect(!engine.canCancel)
        #expect(!engine.canStart)

        engine.pause()
        engine.cancel()
        engine.start()
        #expect(engine.phase == .rest)
        #expect(!engine.isPaused)

        clock.advance(60)
        engine.tick()
        #expect(engine.phase == .rest)
    }

    @Test("Pause keeps the remaining time")
    func pauseKeepsRemaining() {
        let (engine, clock) = makeEngine()
        engine.start()
        clock.advance(10 * 60)
        engine.pause()
        #expect(engine.isPaused)
        #expect(engine.remaining() == 15 * 60)

        clock.advance(60 * 60)
        engine.tick()
        #expect(engine.phase == .focus)
        #expect(engine.remaining() == 15 * 60)

        engine.resume()
        clock.advance(15 * 60)
        engine.tick()
        #expect(engine.phase == .arrival)
    }

    @Test("A completed flight is counted, a cancelled one is not")
    func flightCounter() {
        let (engine, clock) = makeEngine()
        engine.start()
        clock.advance(5 * 60)
        engine.cancel()
        #expect(engine.phase == .idle)
        #expect(engine.flightsToday == 0)

        engine.start()
        clock.advance(25 * 60)
        engine.tick()
        #expect(engine.flightsToday == 1)
    }

    @Test("If the Mac slept through focus and rest, the cycle catches up")
    func sleepCatchUp() {
        let (engine, clock) = makeEngine()
        engine.start()
        clock.advance(2 * 60 * 60)
        engine.tick()
        #expect(engine.phase == .restDone)
        #expect(engine.flightsToday == 1)
    }

    @Test("After rest the next flight waits for the user")
    func nextFlightIsManual() {
        let (engine, clock) = makeEngine()
        engine.debugJump(to: .rest, progress: 0.99)
        clock.advance(10)
        engine.tick()
        #expect(engine.phase == .restDone)

        clock.advance(10 * 60)
        engine.tick()
        #expect(engine.phase == .restDone)

        engine.start()
        #expect(engine.phase == .focus)
    }

    @Test("Phase changes are reported in order")
    func phaseCallbacks() {
        let (engine, clock) = makeEngine()
        var seen: [Phase] = []
        engine.onPhaseChange = { _, new in seen.append(new) }
        engine.start()
        clock.advance(2 * 60 * 60)
        engine.tick()
        #expect(seen == [.focus, .arrival, .rest, .restDone])
    }
}
