import Foundation

@main
struct ShortcutTests {
    // @lat: [[tests#Validation#Shortcut links]]
    static func main() throws {
        assert(ClockRoute.parse(URL(string: "quietclock://idle")!) == .idle)
        assert(ClockRoute.parse(URL(string: "quietclock://settings")!) == .settings)
        assert(ClockRoute.parse(URL(string: "quietclock://settings?url=other")!) == .invalid)
        var link = ClockShortcut(label: "", address: " github.com/openai ", icon: "github")
        assert(link.destination?.absoluteString == "https://github.com/openai")
        assert(link.title == "github.com")
        assert(ClockShortcut.id(from: link.widgetURL) == link.id)
        assert(ClockRoute.parse(link.widgetURL) == .shortcut(link.id))
        for address in ["", "javascript:alert(1)", "file:///tmp/test", "https://", "https://user:password@example.com", "two words", "quietclock://shortcut/a"] {
            link.address = address
            assert(link.destination == nil, "Unsafe or incomplete address accepted: \(address)")
        }
        for route in ["https://shortcut/\(link.id)", "quietclock://other/\(link.id)", "quietclock://shortcut/nope", "quietclock://shortcut/\(link.id)?url=https://bad.example"] {
            assert(ClockShortcut.id(from: URL(string: route)!) == nil)
        }
        link.icon = "../github"
        assert(!link.isValid)
        link.icon = "github"
        var settings = ClockAppearance()
        let valid = ClockShortcut(address: "https://linear.app", icon: "linear")
        settings.shortcuts = [valid, valid]
        assert(!settings.isValid, "Duplicate routing IDs must be rejected")
        settings.shortcuts = (0..<7).map { _ in ClockShortcut() }
        assert(!settings.isValid)
        settings.shortcuts = [ClockShortcut()]
        assert(settings.isValid, "Incomplete editing drafts must be persistable")
        print("Shortcut URL validation, routing, drafts, and limits passed.")
    }
}
