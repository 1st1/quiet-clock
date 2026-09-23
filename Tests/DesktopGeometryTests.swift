import Foundation
import CoreGraphics

@main struct DesktopGeometryTests {
    static func main() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let second = CGRect(x: -1200, y: 0, width: 1200, height: 900)
        let placed = CGRect(x: -900, y: 100, width: 344, height: 400)
        assert(DesktopGeometry.fit(placed, screens: [screen, second]) == placed)
        let recovered = DesktopGeometry.fit(placed, screens: [screen])
        assert(screen.contains(recovered), "Unplugged display must not strand the clock")
        let oversized = DesktopGeometry.fit(CGRect(x: 900, y: 700, width: 1400, height: 1200), screens: [screen])
        assert(oversized == screen)
        let invalid = DesktopGeometry.fit(CGRect(x: 0, y: 0, width: -1, height: 0), screens: [screen])
        assert(invalid.width == 344 && screen.contains(invalid))
        let laptop = DesktopDisplay(id: "laptop", frame: screen)
        let external = DesktopDisplay(id: "external", frame: second)
        assert(DesktopPlacement.groupKey([laptop, external]) == DesktopPlacement.groupKey([external, laptop]))
        let suite = "local.quietclock.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DesktopPlacementStore(defaults: defaults)
        let laptopFrame = CGRect(x: 100, y: 100, width: 300, height: 300)
        store.save(placed, for: [laptop, external])
        store.save(laptopFrame, for: [laptop])
        let reloaded = DesktopPlacementStore(defaults: defaults)
        assert(reloaded.frame(for: [external, laptop]) == placed, "Changing groups must preserve each placement")
        assert(reloaded.frame(for: [laptop]) == laptopFrame)
        assert(reloaded.frame(for: [external]) == nil, "Unseen monitor groups must not use another profile")
        let moved = DesktopDisplay(id: "external", frame: second.offsetBy(dx: 2200, dy: -300))
        assert(reloaded.frame(for: [laptop, moved]) == placed.offsetBy(dx: 2200, dy: -300),
               "Position must follow the same physical display when its desktop origin changes")
        let smaller = DesktopDisplay(id: "external", frame: CGRect(x: -600, y: 0, width: 600, height: 400))
        assert(smaller.frame.contains(reloaded.frame(for: [laptop, smaller])!))
        let different = DesktopDisplay(id: "other-external", frame: second)
        assert(reloaded.frame(for: [laptop, different]) == nil, "Same display count does not mean same monitor group")
        store.save(CGRect(x: 150, y: 100, width: 300, height: 300), for: [laptop])
        assert(store.frame(for: [laptop, external]) == placed, "Dragging in one setup cannot overwrite another")
        print("Desktop placement, monitor profiles, persistence, and display recovery tests passed.")
    }
}
