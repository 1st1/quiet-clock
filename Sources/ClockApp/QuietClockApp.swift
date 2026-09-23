import SwiftUI
import Carbon

// Select the property wrapper, not the SDK 27 State macro whose plugin
// is not bundled with the current Command Line Tools.
typealias StoredState<Value> = State<Value>

@main
struct QuietClockApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = ClockApplicationDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) }
    }
}

@MainActor
final class ClockApplicationDelegate: NSObject, NSApplicationDelegate {
    private var editor: NSWindow?
    private let desktop = DesktopClockController()
    @objc func openApplication(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        showSettings()
    }
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(self,
            andSelector: #selector(openApplication(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass), andEventID: AEEventID(kAEOpenApplication))
        let menu = NSMenu()
        let appItem = NSMenuItem()
        menu.addItem(appItem)
        let appMenu = NSMenu(title: "Quiet Clock")
        appItem.submenu = appMenu
        let settings = appMenu.addItem(withTitle: "Clock Appearance…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Quiet Clock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem()
        menu.addItem(editItem)
        editItem.submenu = NSMenu(title: "Edit")
        for (title, action, key) in [("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            editItem.submenu?.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        NSApplication.shared.mainMenu = menu
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        desktop.openSettings = { [weak self] in self?.showSettings() }
        desktop.start()
        if notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool == true {
            showSettings()
        }
    }
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { true }
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        showSettings()
        return true
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            switch ClockRoute.parse(url) {
            case .settings: showSettings()
            case .shortcut: BrowserLauncher.handle(url)
            case .idle, .invalid: break
            }
        }
    }
    @objc private func showSettings() {
        if editor == nil {
            let controller = NSHostingController(rootView: AppearanceEditor(desktop: desktop))
            let window = NSWindow(contentViewController: controller)
            window.title = "Quiet Clock"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            editor = window
        }
        editor?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

struct AppearanceEditor: View {
    @ObservedObject var desktop: DesktopClockController
    @StoredState private var appearance = ClockAppearance()
    @StoredState private var saved = ClockAppearance()
    @StoredState private var message = "Changes save automatically"
    @StoredState private var error: String?
    private let families = NSFontManager.shared.availableFontFamilies.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Layout") {
                    Toggle("Move clock (drag on desktop)", isOn: $desktop.moving)
                    HStack {
                        Slider(value: $desktop.width, in: 160...1200, step: 1) { Text("Width") }
                        Text("\(Int(desktop.width)) pt").monospacedDigit().frame(width: 58)
                    }
                    Text("Height follows the content automatically.").font(.caption).foregroundStyle(.secondary)
                    Button("Reset desktop position") { desktop.resetPosition() }
                    Picker("Alignment", selection: $appearance.alignment) {
                        ForEach(ClockAlignment.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Typography") {
                    Picker("Font", selection: $appearance.fontFamily) {
                        ForEach(ClockAppearance.systemFamilies, id: \.self) { Text($0).tag($0) }
                        Divider()
                        ForEach(families, id: \.self) { Text($0).tag($0) }
                    }
                    Toggle("Size automatically", isOn: $appearance.automaticSize)
                    if !appearance.automaticSize {
                        HStack {
                            Slider(value: $appearance.fontSize, in: ClockAppearance.clockSizeRange, step: 1) { Text("Font size") }
                            Text("\(Int(appearance.fontSize)) pt").monospacedDigit().frame(width: 52, alignment: .trailing)
                        }
                        Text("Font size stays fixed. Increase the window width if the clock is too wide.").font(.caption).foregroundStyle(.secondary)
                    }
                    Toggle("Automatic line height", isOn: $appearance.automaticLineHeight)
                    if !appearance.automaticLineHeight {
                        HStack {
                            Slider(value: $appearance.clockLineHeight, in: ClockAppearance.clockLineHeightRange, step: 1) { Text("Clock line height") }
                            Text("\(Int(appearance.clockLineHeight)) pt").monospacedDigit().frame(width: 52, alignment: .trailing)
                        }
                        Text("Sets the clock’s vertical space independently of font size. Small heights can overlap nearby content.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Picker("Weight", selection: $appearance.weight) {
                        ForEach(0..<ClockAppearance.weightNames.count, id: \.self) { Text(ClockAppearance.weightNames[$0]).tag($0) }
                    }
                    HStack {
                        Slider(value: $appearance.spacing, in: -8...16, step: 0.5) { Text("Letter spacing") }
                        Text(appearance.spacing.formatted(.number.precision(.fractionLength(1))) + " pt")
                            .monospacedDigit().frame(width: 52, alignment: .trailing)
                    }
                }
                Section("Padding") {
                    paddingSlider("Clock top padding", value: $appearance.clockTopPadding)
                    paddingSlider("Clock bottom padding", value: $appearance.clockBottomPadding)
                    paddingSlider("Divider bottom padding", value: $appearance.dividerBottomPadding)
                }
                Section("Colors") {
                    Toggle("Automatic text color", isOn: $appearance.automaticTextColor)
                    if !appearance.automaticTextColor {
                        ColorPicker("Text color", selection: colorBinding(\.textColor), supportsOpacity: false)
                    }
                }
                Section("Shortcuts") {
                    Picker("Link font", selection: $appearance.linkFontFamily) {
                        ForEach(ClockAppearance.systemFamilies, id: \.self) { Text($0).tag($0) }
                        Divider()
                        ForEach(families, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Link weight", selection: $appearance.linkWeight) {
                        ForEach(0..<ClockAppearance.weightNames.count, id: \.self) { Text(ClockAppearance.weightNames[$0]).tag($0) }
                    }
                    HStack {
                        Slider(value: $appearance.linkSize, in: ClockAppearance.linkSizeRange, step: 1) { Text("Link text size") }
                        Text("\(Int(appearance.linkSize)) pt").monospacedDigit().frame(width: 42)
                    }
                    HStack {
                        Slider(value: $appearance.iconSize, in: ClockAppearance.iconSizeRange, step: 1) { Text("Icon size") }
                        Text("\(Int(appearance.iconSize)) pt").monospacedDigit().frame(width: 42)
                    }
                    HStack {
                        Slider(value: $appearance.iconGap, in: ClockAppearance.iconGapRange, step: 1) { Text("Icon–text gap") }
                        Text("\(Int(appearance.iconGap)) pt").monospacedDigit().frame(width: 42)
                    }
                    HStack {
                        Slider(value: $appearance.linkSpacing, in: ClockAppearance.linkSpacingRange, step: 1) { Text("Link spacing") }
                        Text("\(Int(appearance.linkSpacing)) pt").monospacedDigit().frame(width: 42)
                    }
                    Toggle("Show divider", isOn: $appearance.showDivider)
                    HStack {
                        Slider(value: $appearance.dividerLength, in: 0...1, step: 0.05) { Text("Divider length") }
                        Text("\(Int((appearance.dividerLength * 100).rounded()))%").monospacedDigit().frame(width: 42)
                    }
                    HStack {
                        Slider(value: $appearance.dividerBrightness, in: 0...1, step: 0.05) { Text("Divider brightness") }
                        Text("\(Int((appearance.dividerBrightness * 100).rounded()))%").monospacedDigit().frame(width: 42)
                    }
                    Text("Up to six links below the clock. Icons and labels follow the clock’s text color.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach($appearance.shortcuts) { $shortcut in
                        ShortcutEditor(shortcut: $shortcut,
                            moveUp: { moveShortcut(shortcut.id, by: -1) },
                            moveDown: { moveShortcut(shortcut.id, by: 1) },
                            canMoveUp: appearance.shortcuts.first?.id != shortcut.id,
                            canMoveDown: appearance.shortcuts.last?.id != shortcut.id,
                            remove: { appearance.shortcuts.removeAll { $0.id == shortcut.id } })
                    }
                    Button("Add shortcut", systemImage: "plus") {
                        appearance.shortcuts.append(ClockShortcut())
                    }
                    .disabled(appearance.shortcuts.count >= 6)
                }
            }
            .formStyle(.grouped)
            .frame(height: 560)

            HStack {
                Button("Reset") { appearance = ClockAppearance(); save() }
                Spacer()
                Text(appearance != saved ? "Not saved" : message)
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
            Text("Always transparent. Keep Quiet Clock running to show the clock.")
                .font(.caption).foregroundStyle(.secondary).padding(.bottom, 16)
        }
        .frame(width: 490)
        .onAppear {
            do { appearance = try AppearanceStore.shared.load(); saved = appearance }
            catch { self.error = "Couldn’t read your saved appearance. \(error.localizedDescription)" }
        }
        .onChange(of: appearance) { _, value in
            if value != saved { save() }
        }
        .alert("Couldn’t update appearance", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }

    private func paddingSlider(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Slider(value: value, in: ClockAppearance.paddingRange, step: 1) { Text(title) }
            Text("\(Int(value.wrappedValue)) pt").monospacedDigit().frame(width: 42)
        }
    }

    private func moveShortcut(_ id: UUID, by offset: Int) {
        guard let index = appearance.shortcuts.firstIndex(where: { $0.id == id }),
              appearance.shortcuts.indices.contains(index + offset) else { return }
        appearance.shortcuts.swapAt(index, index + offset)
    }

    private func colorBinding(_ keyPath: WritableKeyPath<ClockAppearance, ClockRGB>) -> Binding<Color> {
        Binding(get: { appearance[keyPath: keyPath].color }, set: { appearance[keyPath: keyPath] = ClockRGB(color: $0) })
    }

    private func save() {
        do {
            try AppearanceStore.shared.save(appearance)
            saved = appearance
            message = "Saved"
            desktop.appearance = appearance
        } catch { self.error = error.localizedDescription }
    }

}
