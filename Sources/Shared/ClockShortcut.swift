import Foundation

struct ServiceIcon: Identifiable, Codable {
    let id: String
    let name: String
    static let website = ServiceIcon(id: "globe", name: "Website")
    static let all: [ServiceIcon] = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "ServiceIcons"),
              let data = try? Data(contentsOf: url),
              let icons = try? JSONDecoder().decode([ServiceIcon].self, from: data) else { return [website] }
        return [website] + icons
    }()
}

enum ShortcutDisplay: String, Codable, CaseIterable {
    case icon, text, both
    var label: String { switch self { case .icon: "Icon"; case .text: "Text"; case .both: "Icon + text" } }
}

struct ClockShortcut: Codable, Equatable, Identifiable {
    var id = UUID()
    var label = ""
    var address = ""
    var icon = "globe"
    var display = ShortcutDisplay.both

    // Incomplete edits are saved as drafts; only complete web addresses become links.
    var destination: URL? {
        let raw = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, !raw.contains(where: { $0.isWhitespace }) else { return nil }
        let candidate = raw.contains(":") ? raw : "https://" + raw
        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        return url
    }
    var title: String {
        let value = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? (destination?.host ?? "Website") : value
    }
    var widgetURL: URL { URL(string: "quietclock://shortcut/\(id.uuidString)")! }
    static func id(from url: URL) -> UUID? {
        guard url.scheme == "quietclock", url.host == "shortcut",
              url.pathComponents.count == 2, url.query == nil, url.fragment == nil else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
    var isValid: Bool {
        label.count <= 80 && address.count <= 2048
            && !icon.isEmpty && icon.count <= 100
            && icon.utf8.allSatisfy { (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }
    }
}

// Widget launches must not implicitly create an appearance window.
enum ClockRoute: Equatable {
    case settings, idle, shortcut(UUID), invalid
    static func parse(_ url: URL) -> ClockRoute {
        guard url.scheme == "quietclock", url.query == nil, url.fragment == nil else { return .invalid }
        if let id = ClockShortcut.id(from: url) { return .shortcut(id) }
        guard url.path.isEmpty || url.path == "/" else { return .invalid }
        switch url.host {
        case "settings": return .settings
        case "idle": return .idle
        default: return .invalid
        }
    }
}
