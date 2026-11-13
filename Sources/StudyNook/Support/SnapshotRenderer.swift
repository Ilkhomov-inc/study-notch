import AppKit
import SwiftUI
import StudyNookCore

/// Debug: renders the island to PNG files and quits. Needs no screen recording permission.
///   STUDYNOOK_SNAPSHOT=<dir> [STUDYNOOK_ONLY=<prefix>] build/StudyNook.app/Contents/MacOS/StudyNook
/// Files are named `<chapter>-<journey|rest>-<progress>.png`, plus `idle`, `choice`, `compact-*`, `stats`, `replay`.
@MainActor
enum SnapshotRenderer {
    struct Item {
        var name: String
        var phase: Phase
        var chapter: Chapter
        var progress: Double
        var expanded = true
    }

    static func run(to dir: String, only: String?) {
        let folder = URL(fileURLWithPath: dir)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        var items: [Item] = [
            Item(name: "idle", phase: .idle, chapter: .birth, progress: 0),
            Item(name: "choice", phase: .choice, chapter: .birth, progress: 1),
            Item(name: "compact-journey", phase: .journey, chapter: .birth, progress: 0.3, expanded: false),
            Item(name: "compact-rest", phase: .rest, chapter: .astapor, progress: 0.4, expanded: false),
        ]
        for ch in Chapter.allCases {
            let n = String(format: "%02d", ch.number)
            let points: [Double] = ch == .birth ? [0.10, 0.33, 0.52, 0.72, 0.93] : [0.15, 0.5, 0.85]
            for p in points {
                items.append(Item(name: "\(n)-journey-\(Int(p * 100))", phase: .journey, chapter: ch, progress: p))
            }
            items.append(Item(name: "\(n)-arrival", phase: .arrival, chapter: ch, progress: 0.4))
            items.append(Item(name: "\(n)-rest-event", phase: .rest, chapter: ch, progress: 0.3))
            items.append(Item(name: "\(n)-rest-quiet", phase: .rest, chapter: ch, progress: 0.8))
        }
        if let only { items = items.filter { $0.name.hasPrefix(only) } }

        for item in items {
            let defaults = UserDefaults(suiteName: "studynook.snapshot") ?? .standard
            let engine = PomodoroEngine(log: FlightLog(defaults: defaults), story: StoryProgress(defaults: defaults))
            engine.debugJump(to: item.phase, progress: item.progress, chapter: item.chapter)
            let model = makeModel()
            model.pinnedExpanded = item.expanded
            render(engine, model, to: folder.appendingPathComponent("\(item.name).png"))
        }

        // Statistics and a replay, with a made-up week of study.
        if only == nil || "stats".hasPrefix(only ?? "") || "replay".hasPrefix(only ?? "") {
            let suite = "studynook.snapshot.stats"
            UserDefaults.standard.removePersistentDomain(forName: suite)
            let d = UserDefaults(suiteName: suite) ?? .standard
            let log = FlightLog(defaults: d)
            for back in 0..<7 {
                guard let day = Calendar.current.date(byAdding: .day, value: -back, to: Date()) else { continue }
                let n = [3, 1, 2, 0, 4, 2, 1][back]
                for _ in 0..<n { log.increment(on: day) }
                log.addMinutes(n * 25 + (back == 0 ? 20 : 0), on: day)
            }
            let story = StoryProgress(defaults: d)
            while story.current.rawValue < 6 { story.advance() }
            let engine = PomodoroEngine(log: log, story: story)
            let model = makeModel()
            model.pinnedExpanded = true
            model.showStats = true
            render(engine, model, to: folder.appendingPathComponent("stats.png"))
            model.showStats = false
            model.replay = Replay(chapter: .astapor, started: Date().addingTimeInterval(-34))
            render(engine, model, to: folder.appendingPathComponent("replay.png"))
        }
    }

    private static func makeModel() -> NotchViewModel {
        let model = NotchViewModel()
        if let metrics = NotchMetrics.detect() { model.metrics = metrics }
        return model
    }

    private static func render(_ engine: PomodoroEngine, _ model: NotchViewModel, to url: URL) {
        let size = model.panelSize
        let view = NotchRootView(engine: engine, model: model)
            .frame(width: size.width, height: size.height)
            .background(Color(white: 0.55))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }
}
