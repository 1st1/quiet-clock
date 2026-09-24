import Foundation
import CoreGraphics

struct DesktopCornerSettings: Codable, Equatable {
    var enabled = false
    var radius = 17.0
    static let radiusRange = 1.0...200.0
    var isValid: Bool { radius.isFinite && Self.radiusRange.contains(radius) }
}

struct DesktopCornerStore {
    let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    private let key = "desktopCornerSettings"
    func load() -> [String: DesktopCornerSettings] {
        guard let data = defaults.data(forKey: key),
              let values = try? JSONDecoder().decode([String: DesktopCornerSettings].self, from: data) else { return [:] }
        return values.filter { $0.value.isValid }
    }
    func save(_ values: [String: DesktopCornerSettings]) {
        guard values.values.allSatisfy(\.isValid), let data = try? JSONEncoder().encode(values) else { return }
        defaults.set(data, forKey: key)
    }
}

enum DesktopCorner: Int, CaseIterable {
    case bottomLeft, bottomRight, topLeft, topRight

    func frame(in screen: CGRect, radius: CGFloat) -> CGRect {
        let size = min(max(0, radius), min(screen.width, screen.height) / 2)
        let right = self == .bottomRight || self == .topRight
        let top = self == .topLeft || self == .topRight
        return CGRect(x: right ? screen.maxX - size : screen.minX,
                      y: top ? screen.maxY - size : screen.minY, width: size, height: size)
    }

    // In each square, the clear quarter-circle is centered at the inward corner.
    func mask(in bounds: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addRect(bounds)
        let right = self == .bottomRight || self == .topRight
        let top = self == .topLeft || self == .topRight
        let center = CGPoint(x: right ? bounds.minX : bounds.maxX,
                             y: top ? bounds.minY : bounds.maxY)
        path.addEllipse(in: CGRect(x: center.x - bounds.width, y: center.y - bounds.height,
                                  width: bounds.width * 2, height: bounds.height * 2))
        return path
    }
}
