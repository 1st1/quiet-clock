import SwiftUI
import AppKit

struct CornerDisplay: Identifiable {
    let id: String
    let name: String
    let frame: CGRect
}

@MainActor
final class DesktopCornersController: NSObject, ObservableObject {
    @Published private(set) var displays: [CornerDisplay] = []
    @Published private var settings: [String: DesktopCornerSettings]
    private let store: DesktopCornerStore
    private var windows: [String: [NSPanel]] = [:]

    override init() {
        let store = DesktopCornerStore()
        self.store = store
        self.settings = store.load()
        super.init()
    }

    func start() {
        refreshDisplays()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDisplays),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshDisplays),
            name: NSWorkspace.didWakeNotification, object: nil)
    }

    func value(for id: String) -> DesktopCornerSettings { settings[id] ?? DesktopCornerSettings() }
    func update(_ id: String, _ value: DesktopCornerSettings) {
        guard value.isValid else { return }
        settings[id] = value
        store.save(settings)
        reconcile()
    }

    @objc private func refreshDisplays() {
        displays = NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                  let uuid = CGDisplayCreateUUIDFromDisplayID(number.uint32Value)?.takeRetainedValue() else { return nil }
            return CornerDisplay(id: CFUUIDCreateString(nil, uuid) as String,
                                 name: screen.localizedName, frame: screen.frame)
        }
        reconcile()
    }

    private func reconcile() {
        let enabled = Set(displays.filter { value(for: $0.id).enabled }.map(\.id))
        for id in Array(windows.keys) where !enabled.contains(id) {
            windows.removeValue(forKey: id)?.forEach { $0.close() }
        }
        for display in displays where enabled.contains(display.id) {
            let radius = value(for: display.id).radius
            let panels = windows[display.id] ?? DesktopCorner.allCases.map { corner in
                let panel = DesktopPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
                panel.title = "Desktop Corner"
                panel.isOpaque = false
                panel.backgroundColor = .clear
                panel.hasShadow = false
                panel.ignoresMouseEvents = true
                panel.hidesOnDeactivate = false
                panel.isReleasedWhenClosed = false
                panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 2)
                panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
                panel.contentView = CornerMaskView(corner: corner)
                return panel
            }
            windows[display.id] = panels
            for (corner, panel) in zip(DesktopCorner.allCases, panels) {
                panel.setFrame(corner.frame(in: display.frame, radius: radius), display: true)
                panel.contentView?.needsDisplay = true
                panel.orderFrontRegardless()
            }
        }
    }
}

final class CornerMaskView: NSView {
    let corner: DesktopCorner
    init(corner: DesktopCorner) {
        self.corner = corner
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isOpaque: Bool { false }
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(bounds)
        context.saveGState()
        context.clip(to: bounds)
        context.setFillColor(NSColor.black.cgColor)
        context.addPath(corner.mask(in: bounds))
        context.drawPath(using: .eoFill)
        context.restoreGState()
    }
}

struct DesktopCornersEditor: View {
    @ObservedObject var corners: DesktopCornersController
    var body: some View {
        Form {
            Section {
                Text("Round the wallpaper’s corners with black masks. Settings are saved separately for each monitor.")
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(corners.displays.enumerated()), id: \.element.id) { index, display in
                Section("\(index + 1). \(display.name) · \(Int(display.frame.width)) × \(Int(display.frame.height))") {
                    Toggle("Enable rounded corners", isOn: binding(display.id, \.enabled))
                    HStack {
                        SettingsSlider(value: binding(display.id, \.radius), in: DesktopCornerSettings.radiusRange, step: 1) {
                            Text("Corner radius")
                        }
                        Text("\(Int(corners.value(for: display.id).radius)) pt").monospacedDigit().frame(width: 58)
                    }
                    .disabled(!corners.value(for: display.id).enabled)
                }
            }
            Section {
                Text("Masks stay on the desktop, behind application windows, the menu bar, and Dock. Clicks pass through. Keep Quiet Clock running to display them.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 490, height: 645)
    }
    private func binding<Value>(_ id: String, _ key: WritableKeyPath<DesktopCornerSettings, Value>) -> Binding<Value> {
        Binding(get: { corners.value(for: id)[keyPath: key] }, set: { value in
            var settings = corners.value(for: id)
            settings[keyPath: key] = value
            corners.update(id, settings)
        })
    }
}

struct ClockPreferences: View {
    @ObservedObject var desktop: DesktopClockController
    @ObservedObject var corners: DesktopCornersController
    var body: some View {
        TabView {
            AppearanceEditor(desktop: desktop).tabItem { Label("Clock", systemImage: "clock") }
            DesktopCornersEditor(corners: corners).tabItem { Label("Desktop Corners", systemImage: "rectangle") }
        }
        .padding(12)
    }
}
