import AppKit
import Observation

/// Players the island can control. Both are driven through AppleScript.
enum MusicPlayer: String, Sendable, CaseIterable {
    case music, spotify

    var bundleID: String { self == .music ? "com.apple.Music" : "com.spotify.client" }
    var title: String { self == .music ? "Музыка" : "Spotify" }
    /// Spotify has no scripting command for "like".
    var canFavorite: Bool { self == .music }

    var isRunning: Bool { !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty }
    var isInstalled: Bool { NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil }
}

/// The track that is playing now.
struct NowPlaying: Equatable, Sendable {
    var player: MusicPlayer
    var id: String
    var title: String
    var artist: String
    var duration: Double
    var isPlaying: Bool
    var isFavorite: Bool
    /// Position at `stamp`; later positions are counted locally, so nothing is polled.
    var position: Double
    var stamp: Date
    var artworkURL: String?

    func position(at date: Date) -> Double {
        let p = isPlaying ? position + date.timeIntervalSince(stamp) : position
        return max(0, duration > 0 ? min(duration, p) : p)
    }
}

/// Now playing in Music or Spotify, and the buttons for it.
///
/// Battery: the players announce every change with a distributed notification, so there is no polling.
/// AppleScript runs only while the music panel is open or after a button press.
@MainActor
@Observable
final class MusicController {
    static let shared = MusicController()

    var track: NowPlaying?
    var artwork: NSImage?
    /// The user turned off automation access for this app.
    var needsPermission = false

    @ObservationIgnored private let runner = ScriptRunner()
    @ObservationIgnored private var started = false
    @ObservationIgnored private var visible = false
    @ObservationIgnored private var artworkID: String?
    @ObservationIgnored private var lastActive: MusicPlayer?
    @ObservationIgnored private var resync: Task<Void, Never>?
    @ObservationIgnored private var refreshToken = 0

    /// Start listening to the players. Costs nothing until something changes.
    func start() {
        guard !started else { return }
        started = true
        let center = DistributedNotificationCenter.default()
        let pairs: [(String, MusicPlayer)] = [
            ("com.apple.Music.playerInfo", .music),
            ("com.spotify.client.PlaybackStateChanged", .spotify),
        ]
        for (name, player) in pairs {
            center.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { note in
                let info = Self.parse(note.userInfo, player: player)
                MainActor.assumeIsolated { self.playerChanged(player, info) }
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
        ) { note in
            let id = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
            MainActor.assumeIsolated {
                if let track = self.track, track.player.bundleID == id {
                    self.track = nil
                    self.artwork = nil
                    self.artworkID = nil
                }
            }
        }
        // No AppleScript at launch: the automation prompt should only appear after the user opens the music panel.
    }

    /// The music panel is on screen: keep the position honest with a rare resync.
    func setVisible(_ on: Bool) {
        guard on != visible else { return }
        visible = on
        resync?.cancel()
        resync = nil
        guard on else { return }
        refresh()
        resync = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard let self, !Task.isCancelled else { return }
                if self.track?.isPlaying == true { self.refresh() }
            }
        }
    }

    // MARK: - Buttons

    func playPause() {
        guard let t = track else { return }
        // Show the change at once; the player confirms with its notification.
        var next = t
        next.position = t.position(at: Date())
        next.stamp = Date()
        next.isPlaying.toggle()
        track = next
        command("playpause", on: t.player)
    }

    func nextTrack() { if let p = track?.player { command("next track", on: p) } }
    func previousTrack() { if let p = track?.player { command("previous track", on: p) } }

    /// Jump a little forward or back.
    func skip(by seconds: Int) {
        guard let t = track else { return }
        seek(to: t.position(at: Date()) + Double(seconds))
    }

    func seek(to seconds: Double) {
        guard var t = track else { return }
        let target = max(0, t.duration > 0 ? min(t.duration - 1, seconds) : seconds)
        t.position = target
        t.stamp = Date()
        track = t
        // Whole seconds keep the script free of locale decimal commas.
        command("set player position to \(Int(target.rounded()))", on: t.player)
    }

    func toggleFavorite() {
        guard var t = track, t.player.canFavorite else { return }
        t.isFavorite.toggle()
        track = t
        command("set favorited of current track to \(t.isFavorite ? "true" : "false")", on: t.player)
    }

    func open(_ player: MusicPlayer) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: player.bundleID) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Reading the players

    private func playerChanged(_ player: MusicPlayer, _ info: NowPlaying?) {
        if info?.isPlaying == true { lastActive = player }
        if visible {
            refresh()
            return
        }
        // Panel closed: take what the notification says, without AppleScript.
        guard let info else {
            if track?.player == player { track = nil }
            return
        }
        if let current = track, current.player != player, current.isPlaying, !info.isPlaying { return }
        var merged = info
        if let current = track, current.player == player, current.id == info.id || info.id.isEmpty {
            if info.position < 0 { merged.position = current.position(at: Date()) }
            merged.isFavorite = current.isFavorite
            merged.artworkURL = info.artworkURL ?? current.artworkURL
            if merged.id.isEmpty { merged.id = current.id }
        }
        if merged.position < 0 { merged.position = 0 }
        track = merged
    }

    /// Ask the running players what is playing. Prefers the one playing, then the one used last.
    func refresh() {
        refreshToken += 1
        let token = refreshToken
        var order = MusicPlayer.allCases.filter(\.isRunning)
        if let last = lastActive, let i = order.firstIndex(of: last) { order.swapAt(0, i) }
        guard !order.isEmpty else {
            track = nil
            artwork = nil
            artworkID = nil
            return
        }
        Task { @MainActor in
            var found: NowPlaying?
            for player in order {
                switch await runner.run(Self.stateScript(player), parse: { Self.parse($0, player: player) }) {
                case .success(let t?):
                    needsPermission = false
                    if found == nil || (t.isPlaying && found?.isPlaying != true) { found = t }
                case .success(nil):
                    needsPermission = false
                case .failure(let e):
                    if e.code == -1743 { needsPermission = true }
                }
                if found?.isPlaying == true { break }
            }
            guard token == refreshToken else { return }
            track = found
            if let found { loadArtwork(for: found) } else { artwork = nil; artworkID = nil }
        }
    }

    private func command(_ line: String, on player: MusicPlayer) {
        let source = "tell application id \"\(player.bundleID)\" to \(line)"
        Task { @MainActor in
            if case .failure(let e) = await runner.run(source, parse: { _ in true }), e.code == -1743 {
                needsPermission = true
            }
            // Some changes (seek, favorite) send no notification: read the state back.
            try? await Task.sleep(for: .milliseconds(350))
            refresh()
        }
    }

    private func loadArtwork(for t: NowPlaying) {
        guard artworkID != t.id else { return }
        artworkID = t.id
        artwork = nil
        let id = t.id
        Task { @MainActor in
            var data: Data?
            switch t.player {
            case .music:
                let script = "tell application id \"com.apple.Music\" to get data of artwork 1 of current track"
                if case .success(let d) = await runner.run(script, parse: { $0.data.isEmpty ? nil : $0.data }) {
                    data = d
                }
            case .spotify:
                if let s = t.artworkURL, let url = URL(string: s), url.scheme == "https" {
                    data = try? await URLSession.shared.data(from: url).0
                }
            }
            guard artworkID == id, let data, let image = NSImage(data: data) else { return }
            artwork = Self.thumbnail(image)
        }
    }

    /// Small copy of the cover: the panel shows it at 94 pt, no need to keep a 640 px bitmap.
    private static func thumbnail(_ image: NSImage) -> NSImage {
        let side: CGFloat = 200
        let out = NSImage(size: NSSize(width: side, height: side))
        out.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
        out.unlockFocus()
        return out
    }

    // MARK: - Scripts and parsing

    nonisolated private static func stateScript(_ player: MusicPlayer) -> String {
        switch player {
        case .music:
            """
            tell application id "com.apple.Music"
                set pstate to (player state as text)
                if pstate is "stopped" then return {pstate}
                set t to current track
                set fav to false
                try
                    set fav to favorited of t
                end try
                return {pstate, name of t, artist of t, duration of t, player position, fav, persistent ID of t, ""}
            end tell
            """
        case .spotify:
            """
            tell application id "com.spotify.client"
                set pstate to (player state as text)
                if pstate is "stopped" then return {pstate}
                set t to current track
                return {pstate, name of t, artist of t, (duration of t) / 1000, player position, false, id of t, artwork url of t}
            end tell
            """
        }
    }

    nonisolated private static func parse(_ d: NSAppleEventDescriptor, player: MusicPlayer) -> NowPlaying? {
        guard d.numberOfItems >= 7, let state = d.atIndex(1)?.stringValue, state != "stopped" else { return nil }
        let art = d.numberOfItems >= 8 ? d.atIndex(8)?.stringValue : nil
        return NowPlaying(
            player: player,
            id: d.atIndex(7)?.stringValue ?? "",
            title: d.atIndex(2)?.stringValue ?? "",
            artist: d.atIndex(3)?.stringValue ?? "",
            duration: d.atIndex(4)?.doubleValue ?? 0,
            isPlaying: state == "playing",
            isFavorite: d.atIndex(6)?.booleanValue ?? false,
            position: d.atIndex(5)?.doubleValue ?? 0,
            stamp: Date(),
            artworkURL: (art?.isEmpty ?? true) ? nil : art
        )
    }

    /// Notification payloads. Position is -1 when the player does not send it (Music).
    nonisolated private static func parse(_ info: [AnyHashable: Any]?, player: MusicPlayer) -> NowPlaying? {
        guard let info, let state = info["Player State"] as? String, state != "Stopped" else { return nil }
        let ms = (info["Total Time"] as? NSNumber)?.doubleValue ?? (info["Duration"] as? NSNumber)?.doubleValue ?? 0
        let id = (info["Track ID"] as? String) ?? (info["PersistentID"] as? NSNumber).map { String(format: "%016llX", $0.uint64Value) } ?? ""
        return NowPlaying(
            player: player,
            id: id,
            title: info["Name"] as? String ?? "",
            artist: info["Artist"] as? String ?? "",
            duration: ms / 1000,
            isPlaying: state == "Playing",
            isFavorite: false,
            position: (info["Playback Position"] as? NSNumber)?.doubleValue ?? -1,
            stamp: Date(),
            artworkURL: nil
        )
    }
}

/// Runs AppleScript off the main thread, one script at a time, with compiled scripts cached.
private final class ScriptRunner: @unchecked Sendable {
    struct Failure: Error { let code: Int }

    private let queue = DispatchQueue(label: "local.studynook.music", qos: .userInitiated)
    private var cache: [String: NSAppleScript] = [:]

    func run<T: Sendable>(
        _ source: String, parse: @escaping @Sendable (NSAppleEventDescriptor) -> T?
    ) async -> Result<T?, Failure> {
        await withCheckedContinuation { cont in
            queue.async {
                let script: NSAppleScript
                if let cached = self.cache[source] {
                    script = cached
                } else if let made = NSAppleScript(source: source) {
                    // Commands with a position change every time; only cache the fixed scripts.
                    if !source.contains("player position to") { self.cache[source] = made }
                    script = made
                } else {
                    cont.resume(returning: .failure(Failure(code: -1)))
                    return
                }
                var error: NSDictionary?
                let out = script.executeAndReturnError(&error)
                if let error {
                    cont.resume(returning: .failure(Failure(code: (error[NSAppleScript.errorNumber] as? Int) ?? -1)))
                } else {
                    cont.resume(returning: .success(parse(out)))
                }
            }
        }
    }
}
