import AppKit
import StudyNookCore

/// Places the panel at the notch, tracks the cursor (expand/collapse) and drives the timer tick.
@MainActor
final class NotchWindowController {
    private let engine: PomodoroEngine
    private let model: NotchViewModel
    private var panel: NotchPanel?
    private var timer: Timer?
    private var screenObserver: NSObjectProtocol?
    private var insideSince: Date?
    private var outsideSince: Date?

    /// How long the cursor must stay over the notch before the island opens.
    private let openDelay: TimeInterval = 0.12
    /// How long the island waits after the cursor leaves.
    private let closeDelay: TimeInterval = 0.35

    init(engine: PomodoroEngine, model: NotchViewModel) {
        self.engine = engine
        self.model = model
    }

    func show() {
        layout()
        // Cheap polling of the cursor position: global mouse monitors are not needed and need no permissions.
        schedule(fast: true)
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.layout() }
        }
    }

    /// Polling rate: 15 Hz while the cursor is near the island (so it opens without lag), 5 Hz otherwise.
    private var isFast = false

    private func schedule(fast: Bool) {
        guard timer == nil || fast != isFast else { return }
        isFast = fast
        timer?.invalidate()
        let interval = fast ? 1.0 / 15.0 : 1.0 / 5.0
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.step() }
        }
        // Lets macOS batch our wakeups with others.
        t.tolerance = interval * 0.3
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// The panel is only as big as it needs to be: a small strip while collapsed (cheap for the window server),
    /// the full size while expanded and for a moment after, so the collapse animation can finish.
    private var isBig = true
    private var bigUntil = Date.distantPast

    private func frame(big: Bool) -> NSRect {
        let m = model.metrics
        let size = big ? model.panelSize
            : CGSize(width: model.collapsedSize(active: true).width + 48, height: m.notchHeight + 12)
        return NSRect(x: m.centerX - size.width / 2, y: m.screenTop - size.height, width: size.width, height: size.height)
    }

    private func layout() {
        guard let metrics = NotchMetrics.detect() else { return }
        model.metrics = metrics
        let frame = frame(big: true)
        isBig = true
        bigUntil = Date().addingTimeInterval(1)
        if panel == nil {
            let panel = NotchPanel(contentRect: frame)
            let host = FirstMouseHostingView(rootView: NotchRootView(engine: engine, model: model))
            host.sizingOptions = []
            host.frame = NSRect(origin: .zero, size: frame.size)
            host.autoresizingMask = [.width, .height]
            panel.contentView = host
            self.panel = panel
        }
        panel?.setFrame(frame, display: true)
        panel?.orderFrontRegardless()
    }

    /// Grows the panel the moment the island opens; shrinks it once the closing animation is over.
    func syncFrame() {
        guard let panel else { return }
        let now = Date()
        if model.isExpanded { bigUntil = now.addingTimeInterval(0.9) }
        let wantBig = now < bigUntil
        if wantBig != isBig {
            isBig = wantBig
            panel.setFrame(frame(big: wantBig), display: true)
        }
    }

    private func step() {
        engine.tick()
        guard let panel else { return }

        let mouse = NSEvent.mouseLocation
        let now = Date()
        let expanded = model.isExpanded

        // Resize right after the hover state below changes, not one tick later.
        defer { syncFrame() }
        let island = model.islandRect(expanded: expanded, active: engine.phase != .idle)

        // The panel takes clicks only while the cursor is over the open island; everywhere else clicks pass through.
        let ignore = !(expanded && island.insetBy(dx: -2, dy: -2).contains(mouse))
        if panel.ignoresMouseEvents != ignore { panel.ignoresMouseEvents = ignore }

        // Poll fast only when the cursor is close to the island or something is moving.
        let near = island.insetBy(dx: -140, dy: -90).contains(mouse)
        schedule(fast: near || expanded || model.isHovering || now < bigUntil)

        // Margin on top: the cursor stops at the screen edge.
        let hot = island.insetBy(dx: -8, dy: -8)
        if hot.contains(mouse) {
            outsideSince = nil
            guard !model.isHovering else { return }
            let since = insideSince ?? now
            insideSince = since
            if now.timeIntervalSince(since) >= openDelay { model.isHovering = true }
        } else {
            insideSince = nil
            guard model.isHovering else { return }
            let since = outsideSince ?? now
            outsideSince = since
            if now.timeIntervalSince(since) >= closeDelay { model.isHovering = false }
        }
    }
}
