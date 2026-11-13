import AppKit
import Observation
import SwiftUI
import StudyNookCore

/// Where the camera notch is, in screen coordinates.
struct NotchMetrics: Equatable {
    var notchWidth: CGFloat
    var notchHeight: CGFloat
    /// Horizontal center of the notch.
    var centerX: CGFloat
    /// Top edge of the screen (screen.frame.maxY).
    var screenTop: CGFloat
    var hasNotch: Bool

    static let fallback = NotchMetrics(notchWidth: 180, notchHeight: 32, centerX: 735, screenTop: 956, hasNotch: false)

    /// The built-in display with a notch, otherwise the main screen with a "pill" in the middle of the menu bar.
    @MainActor
    static func detect() -> NotchMetrics? {
        if let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }),
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            return NotchMetrics(
                notchWidth: right.minX - left.maxX,
                notchHeight: screen.safeAreaInsets.top,
                centerX: (left.maxX + right.minX) / 2,
                screenTop: screen.frame.maxY,
                hasNotch: true
            )
        }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return nil }
        let menuBar = max(24, screen.frame.maxY - screen.visibleFrame.maxY)
        return NotchMetrics(
            notchWidth: 160,
            notchHeight: menuBar,
            centerX: screen.frame.midX,
            screenTop: screen.frame.maxY,
            hasNotch: false
        )
    }
}

enum NotchLayout {
    /// Width of the "wings" on each side of the notch in the collapsed view.
    static let wing: CGFloat = 76
    static let expandedWidth: CGFloat = 540
    /// Expanded height without the notch strip.
    static let expandedBody: CGFloat = 206
    static let sceneHeight: CGFloat = 118
    /// Spare room around the island inside the panel for the shadow.
    static let panelPadding: CGFloat = 40

    static let collapsedTopRadius: CGFloat = 6
    static let collapsedBottomRadius: CGFloat = 10
    static let expandedTopRadius: CGFloat = 14
    static let expandedBottomRadius: CGFloat = 34

    static let spring = Animation.spring(response: 0.44, dampingFraction: 0.8)
}

/// State of the island shared between AppKit (hover, panel) and SwiftUI.
@MainActor
@Observable
final class NotchViewModel {
    var metrics: NotchMetrics = .fallback
    /// Cursor is over the island.
    var isHovering = false
    /// Arrival and rest keep the island open on their own.
    var forcedByPhase = false
    /// Kept open for a few seconds (after the rest ends).
    var isHeld = false
    /// Debug: always open.
    var pinnedExpanded = false
    /// False while the screen sleeps: scenes stop drawing.
    var isAwake = true
    /// Statistics panel shown instead of the scene.
    var showStats = false
    /// A finished chapter being watched again.
    var replay: Replay?
    @ObservationIgnored private var replayToken = 0

    func startReplay(_ chapter: Chapter) {
        replayToken += 1
        let token = replayToken
        showStats = false
        replay = Replay(chapter: chapter, started: Date())
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Replay.total))
            guard let self, self.replayToken == token else { return }
            self.replay = nil
        }
    }

    func stopReplay() {
        replayToken += 1
        replay = nil
    }

    /// Minutes picked in the choice screen.
    var journeyMinutes = 25
    var restMinutes = 5

    @ObservationIgnored private var holdToken = 0

    var isExpanded: Bool { pinnedExpanded || forcedByPhase || isHovering || isHeld || replay != nil }

    var expandedSize: CGSize {
        CGSize(width: NotchLayout.expandedWidth, height: metrics.notchHeight + NotchLayout.expandedBody)
    }

    func collapsedSize(active: Bool) -> CGSize {
        let extra = active ? NotchLayout.wing * 2 : NotchLayout.collapsedTopRadius * 2
        return CGSize(width: metrics.notchWidth + extra, height: metrics.notchHeight)
    }

    var panelSize: CGSize {
        CGSize(
            width: NotchLayout.expandedWidth + NotchLayout.panelPadding * 2,
            height: expandedSize.height + NotchLayout.panelPadding
        )
    }

    /// The island's rectangle on screen.
    func islandRect(expanded: Bool, active: Bool) -> CGRect {
        let size = expanded ? expandedSize : collapsedSize(active: active)
        return CGRect(
            x: metrics.centerX - size.width / 2,
            y: metrics.screenTop - size.height,
            width: size.width,
            height: size.height
        )
    }

    func hold(for seconds: Double) {
        holdToken += 1
        let token = holdToken
        isHeld = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, self.holdToken == token else { return }
            self.isHeld = false
        }
    }
}
