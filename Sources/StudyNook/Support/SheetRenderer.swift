import AppKit
import SwiftUI
import StudyNookCore

/// Debug: renders many scenes into a few contact sheets, so the whole story can be reviewed at a glance.
///   STUDYNOOK_SHEETS=<dir> build/StudyNook.app/Contents/MacOS/StudyNook
@MainActor
enum SheetRenderer {
    struct Tile {
        var label: String
        var phase: Phase
        var chapter: Chapter
        var p: Double
    }

    static let tileSize = CGSize(width: 508, height: 118)

    static func run(to dir: String) {
        let folder = URL(fileURLWithPath: dir)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        var journeys: [Tile] = []
        var rests: [Tile] = []
        for ch in Chapter.allCases {
            for p in [0.1, 0.5, 0.9] {
                journeys.append(Tile(label: "\(ch.number) путь \(Int(p * 100))%", phase: .journey, chapter: ch, p: p))
            }
            for p in [0.1, 0.3, 0.5, 0.8] {
                rests.append(Tile(label: "\(ch.number) отдых \(Int(p * 100))%", phase: .rest, chapter: ch, p: p))
            }
        }
        let extras = [Tile(label: "ожидание", phase: .idle, chapter: .birth, p: 0),
                      Tile(label: "выбор", phase: .choice, chapter: .birth, p: 1)]
        let sheets: [(String, [Tile])] = [
            ("journey-a", Array(journeys[0..<12])), ("journey-b", Array(journeys[12..<24])), ("journey-c", Array(journeys[24..<36])),
            ("rest-a", Array(rests[0..<16])), ("rest-b", Array(rests[16..<32])), ("rest-c", Array(rests[32..<48])),
            ("extras", extras),
        ]
        // Dragons up close: every colour, four wing positions, and lying down.
        let dragons = Canvas(opaque: true) { c, size in
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.55, green: 0.62, blue: 0.75)))
            let pals: [DragonPalette] = [.drogon, .rhaegal, .viserion, .undead]
            for (row, pal) in pals.enumerated() {
                for k in 0..<4 {
                    let pos = CGPoint(x: 150 + CGFloat(k) * 270, y: 95 + CGFloat(row) * 150)
                    DragonPainter.drawFlying(c, pose: DragonPose(position: pos, angle: 0, scale: 2.0, flip: -1),
                                             flapPhase: Double(k) * .pi / 2, t: 1.3, palette: pal)
                }
            }
            for (k, pal) in pals.enumerated() {
                let rig = RestDragonRig(base: CGPoint(x: 160 + CGFloat(k) * 270, y: 770), scale: 3.0, t: 1.0, lift: 0.4)
                DragonPainter.drawResting(c, rig: rig, t: 1.0, eyesClosed: k % 2 == 0, palette: pal)
            }
        }
        .frame(width: 1100, height: 820)
        let dr = ImageRenderer(content: dragons)
        dr.scale = 1
        if let img = dr.nsImage, let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: folder.appendingPathComponent("dragons.png"))
        }

        for (name, tiles) in sheets {
            let view = sheet(tiles)
            let r = ImageRenderer(content: view)
            r.scale = 1.5
            guard let img = r.nsImage, let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else { continue }
            try? png.write(to: folder.appendingPathComponent("\(name).png"))
        }
    }

    private static func sheet(_ tiles: [Tile]) -> some View {
        let cols = 2
        let rows = (tiles.count + cols - 1) / cols
        return VStack(spacing: 6) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 6) {
                    ForEach(0..<cols, id: \.self) { c in
                        let i = r * cols + c
                        if i < tiles.count { tile(tiles[i]) }
                    }
                }
            }
        }
        .padding(6)
        .background(Color(white: 0.2))
    }

    private static func tile(_ tile: Tile) -> some View {
        ZStack(alignment: .topLeading) {
            Canvas(opaque: true) { c, size in
                let env = SceneEnv(size: size, t: 1234.56, p: tile.p, total: 1500)
                StoryScenes.background(c, SceneEnv(size: size, t: 0, p: tile.p, total: 1500), phase: tile.phase, chapter: tile.chapter)
                StoryScenes.foreground(c, env, phase: tile.phase, chapter: tile.chapter)
            }
            .frame(width: tileSize.width, height: tileSize.height)
            Text(tile.label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(Capsule().fill(.black.opacity(0.6)))
                .padding(4)
        }
    }
}
