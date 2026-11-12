import Foundation

/// The story of Daenerys and her dragons, one chapter per journey timer.
public enum Chapter: Int, CaseIterable, Sendable {
    case birth          // Pentos wedding → khalasar → Drogo dies → pyre → dragons hatch
    case qarth          // Red Waste → Qarth, House of the Undying
    case astapor        // Unsullied, Drogon burns Kraznys
    case vaesDothrak    // temple burns, the Dothraki kneel
    case meereen        // Drogon in the gorge, speech from his back
    case sailing        // fleet crosses to Westeros, Dragonstone
    case goldenRoad     // Dothraki and Drogon vs. the Lannister wagons
    case beyondWall     // Jon, wights, Viserion falls
    case winterfell     // Night King on Viserion, Jorah falls
    case rhaegal        // Euron's fleet, Rhaegal falls
    case kingsLanding   // Iron Fleet, the walls, the city burns
    case epilogue       // Drogon melts the Iron Throne, flies east

    public var number: Int { rawValue + 1 }
    public static var count: Int { allCases.count }

    public var title: String {
        switch self {
        case .birth: "Рождение драконов"
        case .qarth: "Дорога в Кварт"
        case .astapor: "Безупречные Астапора"
        case .vaesDothrak: "Огонь Ваэс Дотрака"
        case .meereen: "Речь на спине Дрогона"
        case .sailing: "Плавание в Вестерос"
        case .goldenRoad: "Золотая дорога"
        case .beyondWall: "За Стеной"
        case .winterfell: "Битва за Винтерфелл"
        case .rhaegal: "Гибель Рейгаля"
        case .kingsLanding: "Королевская Гавань"
        case .epilogue: "Эпилог"
        }
    }

    /// Short caption for the timer, in the Apple Clock label style.
    public var caption: String { "Глава \(number) · \(title)" }

    /// Names of the sub-scenes and where each ends (progress 0...1). Only the first chapter is split in five.
    public var beats: [Double] {
        switch self {
        case .birth: [0.20, 0.45, 0.60, 0.85, 1.0]
        default: [1.0]
        }
    }

    /// Which dragons are alive at the end of the chapter.
    public var dragons: Set<Dragon> {
        switch self {
        case .birth, .qarth, .astapor, .vaesDothrak, .meereen, .sailing, .goldenRoad: [.drogon, .rhaegal, .viserion]
        case .beyondWall: [.drogon, .rhaegal]
        case .winterfell: [.drogon, .rhaegal]
        case .rhaegal, .kingsLanding, .epilogue: [.drogon]
        }
    }

    /// Dragons that have died before this chapter's rest (shown as ghosts, sadness scenes).
    public var fallen: [Dragon] {
        switch self {
        case .beyondWall, .winterfell: [.viserion]
        case .rhaegal, .kingsLanding, .epilogue: [.viserion, .rhaegal]
        default: []
        }
    }
}

public enum Dragon: Int, CaseIterable, Sendable {
    case drogon, rhaegal, viserion
}

/// Which chapter is next, and how many times the whole story was finished. Stored in UserDefaults.
public struct StoryProgress {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var current: Chapter {
        Chapter(rawValue: defaults.integer(forKey: "story.chapter")) ?? .birth
    }

    public var finishedStories: Int { defaults.integer(forKey: "story.finished") }

    /// Called after a journey is completed. Returns the chapter that follows.
    @discardableResult
    public func advance() -> Chapter {
        let next = current.rawValue + 1
        if next >= Chapter.count {
            defaults.set(0, forKey: "story.chapter")
            defaults.set(finishedStories + 1, forKey: "story.finished")
        } else {
            defaults.set(next, forKey: "story.chapter")
        }
        return current
    }
}
