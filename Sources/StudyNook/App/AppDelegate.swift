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
            SnapshotRenderer.run(to: dir)
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
        Feedback.prepare()

        if let raw = env["STUDYNOOK_PHASE"] {
            let progress = Double(env["STUDYNOOK_PROGRESS"] ?? "") ?? 0.45
            let phase: Phase? = switch raw {
            case "flight", "focus": .focus
            case "arrival": .arrival
            case "rest": .rest
            case "ready", "restDone": .restDone
            case "idle": .idle
            default: nil
            }
            if let phase { engine.debugJump(to: phase, progress: progress) }
        }
    }

    // MARK: - Phase reactions

    private func phaseChanged(from old: Phase, to new: Phase) {
        model.forcedByPhase = (new == .arrival || new == .rest)

        switch new {
        case .focus where old == .idle || old == .restDone:
            Feedback.play(.takeoff)
        case .arrival:
            Feedback.play(.arrival)
            Feedback.haptic()
            Feedback.notify(
                title: "Дракон долетел до Королевской Гавани",
                body: "25 минут фокуса позади. Теперь 5 минут отдыха с Дейенерис."
            )
        case .restDone:
            Feedback.play(.restDone)
            Feedback.haptic()
            Feedback.notify(title: "Отдых окончен", body: "Дракон отдохнул. Ещё полёт?")
            model.hold(for: 8)
        default:
            break
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
        switch engine.phase {
        case .idle, .restDone:
            menu.addItem(item("Взлететь · 25 минут", #selector(startFlight)))
        case .focus:
            menu.addItem(item(engine.isPaused ? "Продолжить полёт" : "Пауза", #selector(togglePause)))
            menu.addItem(item("Отменить полёт", #selector(cancelFlight)))
        case .arrival, .rest:
            let left = TimeText.mmss(engine.remaining())
            let info = NSMenuItem(title: "Отдых обязателен · \(left)", action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
        }
        let flights = NSMenuItem(title: "Полётов сегодня: \(engine.flightsToday)", action: nil, keyEquivalent: "")
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

    @objc private func startFlight() { engine.start() }
    @objc private func togglePause() { engine.togglePause() }
    @objc private func cancelFlight() { engine.cancel() }
    @objc private func quit() { NSApp.terminate(nil) }
}
