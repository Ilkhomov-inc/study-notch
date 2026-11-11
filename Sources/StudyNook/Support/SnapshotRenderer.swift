import AppKit
import SwiftUI
import StudyNookCore

/// Debug: renders the island in every phase to PNG files and quits.
/// `STUDYNOOK_SNAPSHOT=/some/dir build/StudyNook.app/Contents/MacOS/StudyNook`
/// Needs no screen recording permission: views are rendered offscreen.
@MainActor
enum SnapshotRenderer {
    static func run(to dir: String) {
        let folder = URL(fileURLWithPath: dir)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let cases: [(name: String, phase: Phase, progress: Double, expanded: Bool)] = [
            ("idle", .idle, 0, true),
            ("flight-10", .focus, 0.10, true),
            ("flight-55", .focus, 0.55, true),
            ("flight-95", .focus, 0.95, true),
            ("arrival-30", .arrival, 0.30, true),
            ("arrival-72", .arrival, 0.72, true),
            ("rest-20", .rest, 0.20, true),
            ("rest-90", .rest, 0.90, true),
            ("ready", .restDone, 1, true),
            ("compact-focus", .focus, 0.30, false),
            ("compact-rest", .rest, 0.40, false),
        ]

        for item in cases {
            let defaults = UserDefaults(suiteName: "studynook.snapshot") ?? .standard
            let engine = PomodoroEngine(log: FlightLog(defaults: defaults))
            engine.debugJump(to: item.phase, progress: item.progress)
            let model = NotchViewModel()
            if let metrics = NotchMetrics.detect() { model.metrics = metrics }
            model.pinnedExpanded = item.expanded

            let size = model.panelSize
            let view = NotchRootView(engine: engine, model: model)
                .frame(width: size.width, height: size.height)
                .background(Color(white: 0.55))
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else { continue }
            try? png.write(to: folder.appendingPathComponent("\(item.name).png"))
        }
    }
}
