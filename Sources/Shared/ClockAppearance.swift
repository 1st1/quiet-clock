import Foundation
import Darwin

struct ClockRGB: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double

    var isValid: Bool { [red, green, blue].allSatisfy { $0.isFinite && (0...1).contains($0) } }
}

enum ClockAlignment: String, Codable, CaseIterable {
    case left, center, right
    var label: String { rawValue.capitalized }
}

struct ClockAppearance: Codable, Equatable {
    var fontFamily = "System Rounded"
    var automaticSize = true
    var fontSize = 84.0
    var weight = 2
    var spacing = -2.0
    var automaticTextColor = true
    var textColor = ClockRGB(red: 1, green: 1, blue: 1)
    // Optional storage keeps appearance files from earlier versions readable.
    var savedLinkSize: Double?
    var linkSize: Double {
        get { savedLinkSize ?? 16 }
        set { savedLinkSize = newValue }
    }
    var savedLinkSpacing: Double?
    var linkSpacing: Double {
        get { savedLinkSpacing ?? 12 }
        set { savedLinkSpacing = newValue }
    }
    var savedDividerBrightness: Double?
    var dividerBrightness: Double {
        get { savedDividerBrightness ?? 0.25 }
        set { savedDividerBrightness = newValue }
    }
    static let linkSpacingRange = 0.0...48.0
    static let linkSizeRange = 8.0...32.0
    static let clockSizeRange = 8.0...240.0

    var savedAlignment: ClockAlignment?
    var alignment: ClockAlignment {
        get { savedAlignment ?? .center }
        set { savedAlignment = newValue }
    }
    var savedShortcuts: [ClockShortcut]?
    var shortcuts: [ClockShortcut] {
        get { savedShortcuts ?? [] }
        set { savedShortcuts = newValue }
    }

    static let weightNames = ["Ultra Light", "Thin", "Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black"]
    static let systemFamilies = ["System Rounded", "System", "System Serif", "System Monospaced"]

    var isValid: Bool {
        !fontFamily.isEmpty && fontFamily.count <= 200 && fontSize.isFinite && Self.clockSizeRange.contains(fontSize)
            && (0..<Self.weightNames.count).contains(weight)
            && spacing.isFinite && (-8...16).contains(spacing)
            && linkSize.isFinite && Self.linkSizeRange.contains(linkSize)
            && linkSpacing.isFinite && Self.linkSpacingRange.contains(linkSpacing)
            && dividerBrightness.isFinite && (0...1).contains(dividerBrightness)
            && textColor.isValid && shortcuts.count <= 6 && shortcuts.allSatisfy(\.isValid)
            && Set(shortcuts.map(\.id)).count == shortcuts.count
    }
}

struct AppearanceStore {
    let url: URL

    static var shared: AppearanceStore {
        // A sandbox's homeDirectoryForCurrentUser points into its own container.
        // Resolve the account's actual home for the narrowly entitled shared folder.
        let home = String(cString: getpwuid(getuid())!.pointee.pw_dir)
        return AppearanceStore(url: URL(fileURLWithPath: home)
            .appendingPathComponent("Library/Application Support/Quiet Clock/appearance.json"))
    }

    func load() throws -> ClockAppearance {
        guard FileManager.default.fileExists(atPath: url.path) else { return ClockAppearance() }
        let value = try JSONDecoder().decode(ClockAppearance.self, from: Data(contentsOf: url))
        guard value.isValid else { throw CocoaError(.coderReadCorrupt) }
        return value
    }

    func save(_ value: ClockAppearance) throws {
        guard value.isValid else { throw CocoaError(.coderInvalidValue) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: url, options: .atomic)
    }
}
