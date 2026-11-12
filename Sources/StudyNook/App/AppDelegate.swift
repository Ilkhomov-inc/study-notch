import AppKit
import StudyNookCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var engine: PomodoroEngine!
    private var model: NotchViewModel!
    private var notch: NotchWindowController!
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let env = ProcessInfo.processInfo.environment

        if let dir = env["STUDYNOOK_SNAPSHOT"] {
            SnapshotRenderer.run(to: dir, only: env["STUDYNOOK_ONLY"])
            NSApp.terminate(nil)
            return
        }

        engine = PomodoroEngine(durations: env["STUDYNOOK_FAST"] == "1" ? .fast : .standard)
        model = NotchViewModel()
        model.pinnedExpanded = env["STUDYNOOK_EXPANDED"] == "1"

        engine.onPhaseChange = { [weak self] old, new in
            self?.phaseChanged(from: old, to: new)
        }

        notch = NotchWindowController(engine: engine, model: model)
        notch.show()

        setUpStatusItem()
        observeSleep()
        Feedback.prepare()

        if let raw = env["STUDYNOOK_PHASE"] {
            let progress = Double(env["STUDYNOOK_PROGRESS"] ?? "") ?? 0.45
            let number = Int(env["STUDYNOOK_CHAPTER"] ?? "") ?? 1
            let chapter = Chapter(rawValue: max(0, min(Chapter.count - 1, number - 1))) ?? .birth
            let phase: Phase? = switch raw {
            case "journey", "flight", "focus": .journey
            case "arrival": .arrival
            case "rest": .rest
            case "choice", "ready": .choice
            case "idle": .idle
            default: nil
            }
            if let phase { engine.debugJump(to: phase, progress: progress, chapter: chapter) }
        }
    }

    // MARK: - Phase reactions

    private func phaseChanged(from old: Phase, to new: Phase) {
        model.forcedByPhase = (new == .arrival)

        switch new {
        case .journey where old != .journey:
            Feedback.play(.takeoff)
        case .arrival:
            Feedback.play(.arrival)
            Feedback.haptic()
            Feedback.notify(
                title: "Глава \(engine.chapter.number) пройдена",
                body: "\(engine.chapter.title). Дальше: в путь или отдых?"
            )
        case .choice:
            if old == .rest {
                Feedback.play(.restDone)
                Feedback.notify(title: "Отдых окончен", body: "Дракон отдохнул. В путь?")
            }
            model.hold(for: 20)
        default:
            break
        }
    }

    /// Scenes stop drawing while the screen is asleep.
    private func observeSleep() {
        let nc = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.model.isAwake = false }
            }
        }
        for name in [NSWorkspace.screensDidWakeNotification, NSWorkspace.didWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.model.isAwake = true }
            }
        }
    }

    // MARK: - Menu bar item

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "flame.fill", accessibilityDescription: "Study Nook")
            image?.isTemplate = true
            button.image = image
        }
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let chapter = engine.story.current
        switch engine.phase {
        case .idle:
            let m = engine.nextJourneyIsFixed ? 25 : model.journeyMinutes
            menu.addItem(item("В путь · глава \(chapter.number) · \(m) мин", #selector(startJourney)))
        case .choice:
            let m = engine.nextJourneyIsFixed ? 25 : model.journeyMinutes
            menu.addItem(item("В путь · глава \(chapter.number) · \(m) мин", #selector(startJourney)))
            menu.addItem(item("Отдых · \(model.restMinutes) мин", #selector(startRest)))
        case .journey:
            menu.addItem(item(engine.isPaused ? "Продолжить путь" : "Пауза", #selector(togglePause)))
            menu.addItem(item("Отменить путь", #selector(cancelJourney)))
        case .arrival:
            let info = NSMenuItem(title: "Глава пройдена…", action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
        case .rest:
            menu.addItem(item("Закончить отдых", #selector(endRest)))
        }
        let flights = NSMenuItem(title: "Путей сегодня: \(engine.flightsToday) · история пройдена раз: \(engine.story.finishedStories)", action: nil, keyEquivalent: "")
        flights.isEnabled = false
        menu.addItem(.separator())
        menu.addItem(flights)
        menu.addItem(.separator())
        menu.addItem(item("Выйти из Study Nook", #selector(quit), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func startJourney() { engine.startJourney(minutes: model.journeyMinutes) }
    @objc private func startRest() { engine.startRest(minutes: model.restMinutes) }
    @objc private func endRest() { engine.endRestEarly() }
    @objc private func togglePause() { engine.togglePause() }
    @objc private func cancelJourney() { engine.cancel() }
    @objc private func quit() { NSApp.terminate(nil) }
}
