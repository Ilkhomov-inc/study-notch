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
        now: { clock.now },
        log: FlightLog(defaults: defaults),
        story: StoryProgress(defaults: defaults)
    )
    return (engine, clock)
}

@MainActor
@Suite("PomodoroEngine")
struct PomodoroEngineTests {
    @Test("The first journey of the day is always 25 minutes")
    func firstJourneyIsFixed() {
        let (engine, _) = makeEngine()
        #expect(engine.nextJourneyIsFixed)
        engine.startJourney(minutes: 60)
        #expect(engine.phase == .journey)
        #expect(engine.plannedMinutes == 25)
        #expect(engine.remaining() == 25 * 60)
    }

    @Test("After a journey comes arrival, then a free choice")
    func journeyThenChoice() {
        let (engine, clock) = makeEngine()
        engine.startJourney()
        clock.advance(25 * 60)
        engine.tick()
        #expect(engine.phase == .arrival)
        #expect(engine.chapter == .birth)

        clock.advance(engine.durations.arrival)
        engine.tick()
        #expect(engine.phase == .choice)
        #expect(!engine.nextJourneyIsFixed)
        #expect(engine.canStartJourney)
        #expect(engine.canRest)

        clock.advance(60 * 60)
        engine.tick()
        #expect(engine.phase == .choice)
    }

    @Test("Later journeys use the chosen length and the next chapter")
    func chosenLength() {
        let (engine, clock) = makeEngine()
        engine.startJourney()
        clock.advance(25 * 60 + 10)
        engine.tick()
        engine.startJourney(minutes: 45)
        #expect(engine.plannedMinutes == 45)
        #expect(engine.chapter == .qarth)
        #expect(engine.remaining() == 45 * 60)
    }

    @Test("Rest is optional and can be ended early")
    func restIsOptional() {
        let (engine, clock) = makeEngine()
        engine.startJourney()
        clock.advance(25 * 60 + 10)
        engine.tick()
        #expect(engine.phase == .choice)

        engine.startRest(minutes: 10)
        #expect(engine.phase == .rest)
        #expect(engine.chapter == .birth)
        #expect(engine.remaining() == 10 * 60)

        clock.advance(2 * 60)
        engine.endRestEarly()
        #expect(engine.phase == .choice)
    }

    @Test("Rest ends by itself and returns to the choice")
    func restEnds() {
        let (engine, clock) = makeEngine()
        engine.debugJump(to: .choice, progress: 1, chapter: .birth)
        engine.startRest(minutes: 5)
        clock.advance(5 * 60)
        engine.tick()
        #expect(engine.phase == .choice)
    }

    @Test("Pause keeps the remaining time")
    func pauseKeepsRemaining() {
        let (engine, clock) = makeEngine()
        engine.startJourney()
        clock.advance(10 * 60)
        engine.pause()
        #expect(engine.isPaused)
        #expect(engine.remaining() == 15 * 60)

        clock.advance(60 * 60)
        engine.tick()
        #expect(engine.phase == .journey)

        engine.resume()
        clock.advance(15 * 60)
        engine.tick()
        #expect(engine.phase == .arrival)
    }

    @Test("A cancelled journey is not counted and the chapter stays the same")
    func cancelKeepsChapter() {
        let (engine, clock) = makeEngine()
        engine.startJourney()
        clock.advance(5 * 60)
        engine.cancel()
        #expect(engine.phase == .idle)
        #expect(engine.flightsToday == 0)
        #expect(engine.chapter == .birth)
        #expect(engine.nextJourneyIsFixed)
    }

    @Test("If the Mac slept through the journey, the cycle catches up")
    func sleepCatchUp() {
        let (engine, clock) = makeEngine()
        engine.startJourney()
        clock.advance(2 * 60 * 60)
        engine.tick()
        #expect(engine.phase == .choice)
        #expect(engine.flightsToday == 1)
    }

    @Test("The story goes through 12 chapters and starts over")
    func storyWraps() {
        let defaults = UserDefaults(suiteName: "studynook.tests.\(UUID().uuidString)")!
        let story = StoryProgress(defaults: defaults)
        #expect(story.current == .birth)
        for _ in 0..<11 { story.advance() }
        #expect(story.current == .epilogue)
        story.advance()
        #expect(story.current == .birth)
        #expect(story.finishedStories == 1)
    }

    @Test("Statistics count chapters and minutes per day and over the week")
    func statistics() {
        let (engine, clock) = makeEngine()
        engine.startJourney()
        clock.advance(25 * 60 + 10)
        engine.tick()
        engine.startJourney(minutes: 45)
        clock.advance(45 * 60 + 10)
        engine.tick()
        #expect(engine.flightsToday == 2)
        #expect(engine.minutesToday == 70)

        clock.advance(24 * 60 * 60)
        engine.tick()
        engine.startJourney()
        clock.advance(25 * 60 + 10)
        engine.tick()
        let week = engine.history(days: 7)
        #expect(week.count == 7)
        #expect(week.last?.chapters == 1)
        #expect(week.last?.minutes == 25)
        #expect(week.reduce(0) { $0 + $1.chapters } == 3)
        #expect(week.reduce(0) { $0 + $1.minutes } == 95)
    }

    @Test("Only finished chapters can be watched again")
    func watchedChapters() {
        let (engine, clock) = makeEngine()
        #expect(engine.watchedChapters.isEmpty)
        engine.startJourney()
        clock.advance(25 * 60 + 10)
        engine.tick()
        #expect(engine.watchedChapters == [.birth])
    }

    @Test("Phase changes are reported in order")
    func phaseCallbacks() {
        let (engine, clock) = makeEngine()
        var seen: [Phase] = []
        engine.onPhaseChange = { _, new in seen.append(new) }
        engine.startJourney()
        clock.advance(2 * 60 * 60)
        engine.tick()
        #expect(seen == [.journey, .arrival, .choice])
    }
}
