import SwiftUI

enum MusicTheme {
    /// Apple Music red.
    static let accent = Color(red: 0.99, green: 0.24, blue: 0.35)
}

/// Music in the island, in place of the scene: cover, title, progress you can drag, and the buttons.
struct MusicPanel: View {
    let music: MusicController

    var body: some View {
        Group {
            if let track = music.track {
                playing(track)
            } else if music.needsPermission {
                message(
                    symbol: "lock.fill",
                    title: "Нужен доступ к музыке",
                    detail: "Разрешите Study Nook управлять Музыкой и Spotify: Настройки → Конфиденциальность → Автоматизация."
                ) {
                    pill("Открыть настройки", symbol: "gearshape.fill") { music.openPrivacySettings() }
                }
            } else {
                message(
                    symbol: "music.note",
                    title: "Музыка не играет",
                    detail: "Включите песню в Музыке или Spotify, и её можно будет листать отсюда."
                ) {
                    HStack(spacing: 8) {
                        ForEach(MusicPlayer.allCases.filter(\.isInstalled), id: \.self) { p in
                            pill(p.title, symbol: "arrow.up.forward.app.fill") { music.open(p) }
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(white: 0.11))
        .onAppear { music.setVisible(true) }
        .onDisappear { music.setVisible(false) }
    }

    private func playing(_ t: NowPlaying) -> some View {
        HStack(alignment: .center, spacing: 14) {
            cover
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(t.title.isEmpty ? "Без названия" : t.title)
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(t.artist.isEmpty ? t.player.title : "\(t.artist) · \(t.player.title)")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .lineLimit(1)
                    Spacer(minLength: 0)
                    Button { music.toggleFavorite() } label: {
                        Image(systemName: t.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(t.isFavorite ? MusicTheme.accent : .white.opacity(t.player.canFavorite ? 0.75 : 0.25))
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(!t.player.canFavorite)
                    .help(t.player.canFavorite
                          ? (t.isFavorite ? "Убрать из избранного" : "В избранное")
                          : "Spotify не даёт ставить лайки из других приложений")
                }
                ScrubBar(track: t) { music.seek(to: $0) }
                HStack(spacing: 4) {
                    button("gobackward.15", size: 14, help: "Назад на 15 секунд") { music.skip(by: -15) }
                    button("backward.fill", size: 15, help: "Предыдущая") { music.previousTrack() }
                    Button { music.playPause() } label: {
                        Image(systemName: t.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(.white))
                            .contentShape(Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .help(t.isPlaying ? "Пауза" : "Играть")
                    button("forward.fill", size: 15, help: "Следующая") { music.nextTrack() }
                    button("goforward.15", size: 14, help: "Вперёд на 15 секунд") { music.skip(by: 15) }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var cover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.24), Color(white: 0.15)], startPoint: .top, endPoint: .bottom))
            if let image = music.artwork {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(width: 94, height: 94)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func button(_ symbol: String, size: CGFloat, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 40, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .help(help)
    }

    private func message<A: View>(symbol: String, title: String, detail: String, @ViewBuilder actions: () -> A) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(MusicTheme.accent)
                .frame(width: 94, height: 94)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.06)))
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
                actions()
            }
        }
    }

    private func pill(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(MusicTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(MusicTheme.accent.opacity(0.16)))
                .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
    }
}

/// Progress of the song. Click or drag to jump anywhere in it.
private struct ScrubBar: View {
    let track: NowPlaying
    let seek: (Double) -> Void
    @State private var dragging: Double?
    @State private var hover = false

    var body: some View {
        // Once a second is enough for a bar this short; it stops while paused.
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let pos = dragging.map { $0 * track.duration } ?? track.position(at: ctx.date)
            let frac = track.duration > 0 ? pos / track.duration : 0
            HStack(spacing: 8) {
                Text(Self.time(pos))
                    .frame(width: 34, alignment: .trailing)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.18))
                        Capsule().fill(.white.opacity(hover || dragging != nil ? 0.95 : 0.75))
                            .frame(width: max(0, geo.size.width * frac))
                    }
                    .frame(height: hover || dragging != nil ? 6 : 4)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in dragging = min(1, max(0, v.location.x / geo.size.width)) }
                            .onEnded { v in
                                let f = min(1, max(0, v.location.x / geo.size.width))
                                dragging = nil
                                seek(f * track.duration)
                            }
                    )
                }
                .frame(height: 14)
                .onHover { hover = $0 }
                Text("−" + Self.time(max(0, track.duration - pos)))
                    .frame(width: 38, alignment: .leading)
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.5))
            .animation(.easeOut(duration: 0.15), value: hover)
        }
        .disabled(track.duration <= 0)
    }

    private static func time(_ s: Double) -> String {
        let t = Int(s.rounded(.down))
        return t >= 3600 ? String(format: "%d:%02d:%02d", t / 3600, t / 60 % 60, t % 60) : String(format: "%d:%02d", t / 60, t % 60)
    }
}
