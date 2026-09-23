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
    var savedAutomaticLineHeight: Bool?
    var automaticLineHeight: Bool {
        get { savedAutomaticLineHeight ?? true }
        set { savedAutomaticLineHeight = newValue }
    }
    var savedClockLineHeight: Double?
    var clockLineHeight: Double {
        get { savedClockLineHeight ?? 100 }
        set { savedClockLineHeight = newValue }
    }
    static let clockLineHeightRange = 8.0...240.0
    var savedClockTopPadding: Double?
    var clockTopPadding: Double {
        get { savedClockTopPadding ?? 0 }
        set { savedClockTopPadding = newValue }
    }
    var savedClockBottomPadding: Double?
    var clockBottomPadding: Double {
        get { savedClockBottomPadding ?? 0 }
        set { savedClockBottomPadding = newValue }
    }
    var savedDividerBottomPadding: Double?
    var dividerBottomPadding: Double {
        get { savedDividerBottomPadding ?? 8 }
        set { savedDividerBottomPadding = newValue }
    }
    static let paddingRange = -64.0...64.0
    var savedLinkFontFamily: String?
    var linkFontFamily: String {
        get { savedLinkFontFamily ?? "System" }
        set { savedLinkFontFamily = newValue }
    }
    var savedLinkWeight: Int?
    var linkWeight: Int {
        get { savedLinkWeight ?? 4 }
        set { savedLinkWeight = newValue }
    }
    var savedLinkSize: Double?
    var linkSize: Double {
        get { savedLinkSize ?? 16 }
        set {
            // Preserve the existing icon size when adjusting text in older settings.
            if savedIconSize == nil { savedIconSize = linkSize }
            savedLinkSize = newValue
        }
    }
    var savedIconSize: Double?
    var iconSize: Double {
        get { savedIconSize ?? linkSize }
        set { savedIconSize = newValue }
    }
    var savedIconGap: Double?
    var iconGap: Double {
        get { savedIconGap ?? 5 }
        set { savedIconGap = newValue }
    }
    static let iconSizeRange = 8.0...64.0
    static let iconGapRange = 0.0...32.0
    var savedLinkSpacing: Double?
    var linkSpacing: Double {
        get { savedLinkSpacing ?? 12 }
        set { savedLinkSpacing = newValue }
    }
    var savedShowDivider: Bool?
    var showDivider: Bool {
        get { savedShowDivider ?? true }
        set { savedShowDivider = newValue }
    }
    var savedDividerLength: Double?
    var dividerLength: Double {
        get { savedDividerLength ?? 1 }
        set { savedDividerLength = newValue }
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
            && clockLineHeight.isFinite && Self.clockLineHeightRange.contains(clockLineHeight)
            && [clockTopPadding, clockBottomPadding, dividerBottomPadding]
                .allSatisfy { $0.isFinite && Self.paddingRange.contains($0) }
            && spacing.isFinite && (-8...16).contains(spacing)
            && !linkFontFamily.isEmpty && linkFontFamily.count <= 200
            && (0..<Self.weightNames.count).contains(linkWeight)
            && linkSize.isFinite && Self.linkSizeRange.contains(linkSize)
            && iconSize.isFinite && Self.iconSizeRange.contains(iconSize)
            && iconGap.isFinite && Self.iconGapRange.contains(iconGap)
            && linkSpacing.isFinite && Self.linkSpacingRange.contains(linkSpacing)
            && dividerLength.isFinite && (0...1).contains(dividerLength)
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
