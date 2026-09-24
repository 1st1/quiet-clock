import Foundation
import CoreGraphics

@main struct DesktopCornersTests {
    static func main() {
        let display = CGRect(x: -1920, y: -300, width: 1920, height: 1080)
        let frames = DesktopCorner.allCases.map { $0.frame(in: display, radius: 40) }
        assert(frames.count == 4 && frames.allSatisfy { display.contains($0) && $0.width == 40 && $0.height == 40 })
        assert(frames[0].origin == display.origin)
        assert(frames[3].maxX == display.maxX && frames[3].maxY == display.maxY)
        let tiny = CGRect(x: 0, y: 0, width: 100, height: 80)
        assert(DesktopCorner.topRight.frame(in: tiny, radius: 200).width == 40)
        for corner in DesktopCorner.allCases {
            let right = corner == .bottomRight || corner == .topRight
            let top = corner == .topLeft || corner == .topRight
            let outer = CGPoint(x: right ? 39 : 1, y: top ? 39 : 1)
            let inner = CGPoint(x: right ? 1 : 39, y: top ? 1 : 39)
            let mask = corner.mask(in: CGRect(x: 0, y: 0, width: 40, height: 40))
            assert(mask.contains(outer, using: .evenOdd), "Outer screen corner must be black")
            assert(!mask.contains(inner, using: .evenOdd), "Interior must remain transparent")
            assert(!mask.contains(CGPoint(x: 20, y: 20), using: .evenOdd), "Most of corner square must remain clear")
        }
        let suite = "local.quietclock.corners.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DesktopCornerStore(defaults: defaults)
        assert(store.load().isEmpty && !DesktopCornerSettings().enabled)
        var first = DesktopCornerSettings(enabled: true, radius: 42)
        let second = DesktopCornerSettings(enabled: false, radius: 100)
        store.save(["displayA": first, "displayB": second])
        assert(DesktopCornerStore(defaults: defaults).load() == ["displayA": first, "displayB": second])
        first.radius = .nan
        store.save(["displayA": first])
        assert(store.load()["displayA"]?.radius == 42, "Invalid writes must preserve settings")
        for radius in [0.0, 201, .infinity, .nan] {
            assert(!DesktopCornerSettings(radius: radius).isValid)
        }
        assert(DesktopCornerSettings(radius: 1).isValid && DesktopCornerSettings(radius: 200).isValid)
        print("Desktop corner geometry, masks, per-display persistence, and validation passed.")
    }
}
