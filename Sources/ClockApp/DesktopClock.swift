import SwiftUI
import AppKit

final class DesktopPanel: NSPanel {
    var contextMenu: (() -> NSMenu)?
    override func sendEvent(_ event: NSEvent) {
        if event.type == .rightMouseDown || (event.type == .leftMouseDown && event.modifierFlags.contains(.control)),
           let view = contentView, let menu = contextMenu?() {
            NSMenu.popUpContextMenu(menu, with: event, for: view)
            return
        }
        super.sendEvent(event)
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class DesktopClockController: NSObject, ObservableObject, NSWindowDelegate {
    @Published var appearance = (try? AppearanceStore.shared.load()) ?? ClockAppearance() { didSet { measureContent() } }
    @Published var date = Date() { didSet { measureContent() } }
    @Published var moving = false
    @Published var width: Double = 344 { didSet { resize() } }
    @Published private(set) var height: Double = 344
    var openSettings: (() -> Void)?
    private var panel: DesktopPanel?
    private var timer: Timer?
    private let placements = DesktopPlacementStore()
    private var activeDisplays: [DesktopDisplay] = []
    private var restoring = false
    private var contentHeight: CGFloat?
    private var displayChangeTask: Task<Void, Never>?

    private func connectedDisplays() -> [DesktopDisplay] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                  let uuid = CGDisplayCreateUUIDFromDisplayID(number.uint32Value)?.takeRetainedValue() else { return nil }
            return DesktopDisplay(id: CFUUIDCreateString(nil, uuid) as String, frame: screen.visibleFrame)
        }.sorted { $0.id < $1.id }
    }

    func start() {
        guard panel == nil else { return }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        activeDisplays = connectedDisplays()
        let saved = placements.frame(for: activeDisplays) ?? UserDefaults.standard.string(forKey: "desktopFrame").map(NSRectFromString)
        let initial = saved ?? NSRect(x: screen.maxX - 364, y: screen.maxY - 364, width: 344, height: 344)
        let frame = DesktopGeometry.fit(initial, screens: NSScreen.screens.map(\.visibleFrame))
        width = frame.width; height = frame.height
        let window = DesktopPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        let hosting = NSHostingView(rootView: DesktopClockView(clock: self))
        hosting.sizingOptions = []
        window.contentView = hosting
        window.contextMenu = { [weak self] in self?.makeContextMenu() ?? NSMenu() }
        window.delegate = self
        panel = window
        window.orderFrontRegardless()
        saveFrame()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .NSSystemClockDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .NSSystemTimeZoneDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleep), name: NSWorkspace.willSleepNotification, object: nil)
        refresh()
    }

    @objc private func sleep() { timer?.invalidate(); timer = nil }
    @objc private func refresh() {
        timer?.invalidate()
        date = Date()
        let next = ClockTime.nextMinute(after: date)
        let timer = Timer(fire: next, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        timer.tolerance = 0.1
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    private func resize() {
        guard let panel, !restoring else { return }
        let frame = NSRect(x: panel.frame.minX, y: panel.frame.maxY - height, width: width, height: height)
        applyFrame(DesktopGeometry.fit(frame, screens: NSScreen.screens.map(\.visibleFrame)))
        measureContent()
        saveFrame()
    }
    private func measureContent() {
        guard panel != nil, !restoring else { return }
        let measuringView = NSHostingView(rootView: ClockFace(date: date, appearance: appearance, width: width))
        fitContentHeight(measuringView.fittingSize.height)
    }
    private func fitContentHeight(_ measured: CGFloat) {
        guard measured.isFinite, measured > 0, let panel, !restoring else { return }
        let desired = ceil(measured)
        contentHeight = desired
        guard abs(panel.frame.height - desired) >= 1 else { return }
        // Grow downward without feeding the window height back into text layout.
        applyFrame(NSRect(x: panel.frame.minX, y: panel.frame.maxY - desired,
                          width: panel.frame.width, height: desired))
        saveFrame()
    }
    private func applyFrame(_ proposed: NSRect) {
        guard let panel else { return }
        var frame = proposed
        if let contentHeight {
            frame.origin.y = proposed.maxY - contentHeight
            frame.size.height = contentHeight
        }
        restoring = true
        panel.setFrame(frame, display: true)
        width = frame.width; height = frame.height
        restoring = false
    }
    @objc private func screensChanged() {
        displayChangeTask?.cancel()
        displayChangeTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
            guard let self, let panel = self.panel else { return }
            let displays = connectedDisplays()
            guard !displays.isEmpty else { return }
            let frame = placements.frame(for: displays)
                ?? DesktopGeometry.fit(panel.frame, screens: displays.map(\.frame))
            activeDisplays = displays
            applyFrame(frame)
            measureContent()
            displayChangeTask = nil
            saveFrame()
        }
    }
    func resetPosition() {
        guard let panel, let screen = NSScreen.main?.visibleFrame else { return }
        let proposed = NSRect(x: screen.maxX - panel.frame.width - 20, y: screen.maxY - panel.frame.height - 20,
                              width: panel.frame.width, height: panel.frame.height)
        applyFrame(DesktopGeometry.fit(proposed, screens: [screen]))
        saveFrame()
    }
    func windowDidMove(_ notification: Notification) {
        // Ignore macOS repositioning windows while displays are being reconfigured.
        if moving { saveFrame() }
    }
    private func saveFrame() {
        guard !restoring, displayChangeTask == nil, activeDisplays == connectedDisplays(), let panel else { return }
        placements.save(panel.frame, for: activeDisplays)
    }
    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        let move = menu.addItem(withTitle: moving ? "Lock Position" : "Move Clock (Drag & Drop)",
                                action: #selector(toggleMoving), keyEquivalent: "")
        move.target = self
        let settings = menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: "Quit Quiet Clock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quit.target = NSApplication.shared
        return menu
    }
    @objc private func toggleMoving() { moving.toggle() }
    @objc private func showSettings() { openSettings?() }
    func open(_ url: URL) {
        switch ClockRoute.parse(url) {
        case .settings: openSettings?()
        case .shortcut: BrowserLauncher.handle(url)
        case .idle, .invalid: break
        }
    }
}

private struct DesktopClockView: View {
    @ObservedObject var clock: DesktopClockController
    var body: some View {
        ClockFace(date: clock.date, appearance: clock.appearance, width: clock.width)
            .environment(\.openURL, OpenURLAction { clock.open($0); return .handled })
            .allowsHitTesting(!clock.moving)
            .overlay {
                if clock.moving {
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        Text("Drag to move · right-click to lock")
                            .font(.caption).padding(6).background(.black.opacity(0.7)).foregroundStyle(.white)
                        DragSurface()
                    }
                }
            }
            .transaction { $0.animation = nil }
    }
}

private struct DragSurface: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}
    final class DragView: NSView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override func mouseDown(with event: NSEvent) { window?.performDrag(with: event) }
    }
}
