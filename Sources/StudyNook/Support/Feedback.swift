import AppKit
import UserNotifications

/// Sounds, trackpad haptics and notifications at phase changes.
@MainActor
enum Feedback {
    enum Cue {
        case takeoff, arrival, restDone

        var soundName: String {
            switch self {
            case .takeoff: "Pop"
            case .arrival: "Hero"
            case .restDone: "Glass"
            }
        }
    }

    /// Notifications only work inside a real .app bundle.
    private static var canNotify: Bool { Bundle.main.bundleIdentifier != nil }

    static func prepare() {
        guard canNotify else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    static func play(_ cue: Cue) {
        NSSound(named: NSSound.Name(cue.soundName))?.play()
    }

    static func haptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }

    static func notify(title: String, body: String) {
        guard canNotify else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
