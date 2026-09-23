import Foundation

@main
struct AppearanceSandboxProbe {
    static func main() throws {
        let operation = CommandLine.arguments[1]
        let filename = CommandLine.arguments[2]
        precondition(filename.hasPrefix("probe-") && !filename.contains("/"))
        let store = AppearanceStore(url: AppearanceStore.shared.url.deletingLastPathComponent().appendingPathComponent(filename))
        switch operation {
        case "write":
            var value = ClockAppearance()
            value.fontFamily = "Georgia"
            value.fontSize = 107
            value.shortcuts = [ClockShortcut(label: "GitHub", address: "https://github.com", icon: "github")]
            try store.save(value)
        case "read":
            let value = try store.load()
            precondition(value.fontFamily == "Georgia" && value.fontSize == 107 && value.shortcuts.first?.icon == "github")
            try store.save(value)
        case "cleanup":
            try FileManager.default.removeItem(at: store.url)
        default: fatalError("Unknown probe operation")
        }
        print("Sandbox settings \(operation) passed.")
    }
}
