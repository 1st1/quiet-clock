import Foundation
import Darwin

struct ClockRGB: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double

    var isValid: Bool { [red, green, blue].allSatisfy { $0.isFinite && (0...1).contains($0) } }
}

struct ClockAppearance: Codable, Equatable {
    var fontFamily = "System Rounded"
    var automaticSize = true
    var fontSize = 84.0
    var weight = 2
    var spacing = -2.0
    var automaticTextColor = true
    var textColor = ClockRGB(red: 1, green: 1, blue: 1)
    var automaticBackgroundColor = true
    var backgroundColor = ClockRGB(red: 0.12, green: 0.13, blue: 0.15)
    var transparentBackground = false

    static let weightNames = ["Ultra Light", "Thin", "Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black"]
    static let systemFamilies = ["System Rounded", "System", "System Serif", "System Monospaced"]

    var isValid: Bool {
        !fontFamily.isEmpty && fontFamily.count <= 200 && fontSize.isFinite && (20...140).contains(fontSize)
            && (0..<Self.weightNames.count).contains(weight)
            && spacing.isFinite && (-8...16).contains(spacing)
            && textColor.isValid && backgroundColor.isValid
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
