import Foundation
import CoreGraphics

struct DesktopDisplay: Equatable {
    let id: String
    let frame: CGRect
}

struct DesktopPlacement: Codable, Equatable {
    let displayID: String
    let left: Double
    let top: Double
    let width: Double
    let height: Double

    static func groupKey(_ displays: [DesktopDisplay]) -> String {
        displays.map(\.id).sorted().joined(separator: "|")
    }

    init(frame: CGRect, displays: [DesktopDisplay]) {
        let display = displays.max { a, b in
            func area(_ rect: CGRect) -> CGFloat {
                let overlap = rect.intersection(frame)
                return overlap.isNull ? 0 : overlap.width * overlap.height
            }
            return area(a.frame) < area(b.frame)
        }!
        displayID = display.id
        left = frame.minX - display.frame.minX
        top = display.frame.maxY - frame.maxY
        width = frame.width
        height = frame.height
    }

    func restored(on displays: [DesktopDisplay]) -> CGRect? {
        guard let display = displays.first(where: { $0.id == displayID }) else { return nil }
        let proposed = CGRect(x: display.frame.minX + left, y: display.frame.maxY - top - height,
                              width: width, height: height)
        return DesktopGeometry.fit(proposed, screens: [display.frame])
    }
}

struct DesktopPlacementStore {
    private let defaults: UserDefaults
    private let key = "desktopMonitorPlacements"
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    private var placements: [String: DesktopPlacement] {
        guard let data = defaults.data(forKey: key),
              let result = try? JSONDecoder().decode([String: DesktopPlacement].self, from: data) else { return [:] }
        return result
    }
    func frame(for displays: [DesktopDisplay]) -> CGRect? {
        placements[DesktopPlacement.groupKey(displays)]?.restored(on: displays)
    }
    func save(_ frame: CGRect, for displays: [DesktopDisplay]) {
        guard !displays.isEmpty else { return }
        var all = placements
        all[DesktopPlacement.groupKey(displays)] = DesktopPlacement(frame: frame, displays: displays)
        if let data = try? JSONEncoder().encode(all) { defaults.set(data, forKey: key) }
    }
}
