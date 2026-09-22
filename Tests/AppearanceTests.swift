import Foundation

@main
struct AppearanceTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AppearanceStore(url: directory.appendingPathComponent("appearance.json"))
        let defaults = try store.load()
        assert(defaults == ClockAppearance())
        var custom = defaults
        custom.linkSize = 18
        custom.linkSpacing = 28
        custom.dividerBrightness = 0.7
        custom.alignment = .right
        custom.fontFamily = "Georgia"
        custom.automaticSize = false
        custom.fontSize = 110
        custom.weight = 6
        custom.spacing = 4.5
        custom.automaticTextColor = false
        custom.textColor = ClockRGB(red: 0.3, green: 0.7, blue: 0.9)
        custom.shortcuts = [ClockShortcut(label: "GitHub", address: "https://github.com", icon: "github", display: .both)]
        try store.save(custom)
        let reloaded = try AppearanceStore(url: store.url).load()
        assert(reloaded == custom, "All settings must survive a separate store instance")
        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(custom)) as! [String: Any]
        legacy.removeValue(forKey: "savedShortcuts")
        legacy.removeValue(forKey: "savedAlignment")
        legacy.removeValue(forKey: "savedLinkSize")
        legacy.removeValue(forKey: "savedLinkSpacing")
        legacy.removeValue(forKey: "savedDividerBrightness")
        legacy["transparentBackground"] = false
        legacy["privateBackground"] = ["enabled": false, "style": 2]
        let migrated = try JSONDecoder().decode(ClockAppearance.self, from: JSONSerialization.data(withJSONObject: legacy))
        assert(migrated.shortcuts.isEmpty && migrated.fontFamily == custom.fontFamily && migrated.alignment == .center && migrated.linkSize == 16)
        assert(migrated.linkSpacing == 12 && migrated.dividerBrightness == 0.25)
        for (gap, brightness) in [(0.0, 0.0), (48.0, 1.0)] {
            var boundary = custom
            boundary.linkSpacing = gap
            boundary.dividerBrightness = brightness
            assert(boundary.isValid)
        }
        for gap in [-1.0, 49.0, Double.infinity, Double.nan] {
            var invalidGap = custom
            invalidGap.linkSpacing = gap
            assert(!invalidGap.isValid)
        }
        for brightness in [-0.1, 1.1, Double.infinity, Double.nan] {
            var invalidBrightness = custom
            invalidBrightness.dividerBrightness = brightness
            assert(!invalidBrightness.isValid)
        }
        for size in [8.0, 32.0] {
            var boundary = custom
            boundary.linkSize = size
            boundary.fontSize = size == 8 ? 8 : 240
            assert(boundary.isValid)
        }
        for size in [7.0, 33.0, Double.infinity, Double.nan] {
            var invalidSize = custom
            invalidSize.linkSize = size
            assert(!invalidSize.isValid)
        }
        for size in [7.0, 241.0] {
            var invalidSize = custom
            invalidSize.fontSize = size
            assert(!invalidSize.isValid)
        }
        var invalid = custom
        invalid.weight = 99
        do { try store.save(invalid); fatalError("Invalid weight accepted") }
        catch is CocoaError {}
        let preserved = try store.load()
        assert(preserved == custom, "Invalid saves must preserve existing settings")
        try Data("invalid json".utf8).write(to: store.url)
        do { _ = try store.load(); fatalError("Corrupt settings accepted") }
        catch is DecodingError {}
        try store.save(defaults)
        let reset = try store.load()
        assert(reset == defaults)
        print("Appearance persistence, validation, corruption, and reset checks passed.")
    }
}
