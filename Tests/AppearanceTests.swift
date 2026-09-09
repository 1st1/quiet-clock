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
        custom.fontFamily = "Georgia"
        custom.automaticSize = false
        custom.fontSize = 110
        custom.weight = 6
        custom.spacing = 4.5
        custom.automaticTextColor = false
        custom.textColor = ClockRGB(red: 0.3, green: 0.7, blue: 0.9)
        custom.automaticBackgroundColor = false
        custom.backgroundColor = ClockRGB(red: 0.1, green: 0.2, blue: 0.3)
        custom.transparentBackground = true
        try store.save(custom)
        let reloaded = try AppearanceStore(url: store.url).load()
        assert(reloaded == custom, "All settings must survive a separate store instance")
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
