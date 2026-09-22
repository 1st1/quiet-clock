import SwiftUI
import WidgetKit
import Carbon

@main
struct QuietClockApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = ClockApplicationDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) }
    }
}

@MainActor
final class ClockApplicationDelegate: NSObject, NSApplicationDelegate {
    private var editor: NSWindow?

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
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        if UserDefaults.standard.string(forKey: "lastWidgetBuild") != build {
            WidgetCenter.shared.reloadTimelines(ofKind: "QuietClock")
            UserDefaults.standard.set(build, forKey: "lastWidgetBuild")
        }
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
            let controller = NSHostingController(rootView: AppearanceEditor())
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
    @State private var appearance = ClockAppearance()
    @State private var saved = ClockAppearance()
    @State private var message = "Changes save automatically"
    @State private var reloadTask: Task<Void, Never>?
    @State private var error: String?
    @State private var previewSize = "Medium"
    private let families = NSFontManager.shared.availableFontFamilies.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    ClockFace(date: context.date, appearance: appearance)
                        .frame(width: previewSize == "Small" ? 164 : 344, height: previewSize == "Large" ? 344 : 164)
                        .scaleEffect(previewSize == "Large" ? 0.65 : 1)
                        .frame(width: 420, height: 240)
                        .background {
                            LinearGradient(colors: [Color(red: 0.32, green: 0.4, blue: 0.44), Color(red: 0.66, green: 0.63, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                Picker("Preview size", selection: $previewSize) {
                    ForEach(["Small", "Medium", "Large"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }
            .padding(24)

            Form {
                Section("Layout") {
                    Text("For more room, right-click the desktop widget and choose Large. The preview selector does not resize the desktop widget.")
                        .font(.caption).foregroundStyle(.secondary)
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
                        Text("Large text scales down when needed to fit the widget.").font(.caption).foregroundStyle(.secondary)
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
                Section("Colors") {
                    Toggle("Automatic text color", isOn: $appearance.automaticTextColor)
                    if !appearance.automaticTextColor {
                        ColorPicker("Text color", selection: colorBinding(\.textColor), supportsOpacity: false)
                    }
                }
                Section("Shortcuts") {
                    HStack {
                        Slider(value: $appearance.linkSize, in: ClockAppearance.linkSizeRange, step: 1) { Text("All link sizes") }
                        Text("\(Int(appearance.linkSize)) pt").monospacedDigit().frame(width: 42)
                    }
                    HStack {
                        Slider(value: $appearance.linkSpacing, in: ClockAppearance.linkSpacingRange, step: 1) { Text("Link spacing") }
                        Text("\(Int(appearance.linkSpacing)) pt").monospacedDigit().frame(width: 42)
                    }
                    HStack {
                        Slider(value: $appearance.dividerBrightness, in: 0...1, step: 0.05) { Text("Divider brightness") }
                        Text("\(Int((appearance.dividerBrightness * 100).rounded()))%").monospacedDigit().frame(width: 42)
                    }
                    Text("Up to six links below the clock. Icons and labels follow the clock’s text color.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach($appearance.shortcuts) { $shortcut in
                        ShortcutEditor(shortcut: $shortcut, linkSize: appearance.linkSize,
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
            .frame(height: 420)

            HStack {
                Button("Reset") { appearance = ClockAppearance(); save() }
                Spacer()
                Text(appearance != saved ? "Not saved" : message)
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
            Text("Always transparent. Changes apply to all Quiet Clock widgets.")
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
        .onDisappear { flushReload() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            flushReload()
        }
        .alert("Couldn’t update appearance", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
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
            // Persist immediately so closing the app cannot lose the latest edit.
            // Only the WidgetKit request is debounced during continuous adjustments.
            reloadTask?.cancel()
            reloadTask = Task { @MainActor in
                do { try await Task.sleep(for: .milliseconds(400)) }
                catch { return }
                WidgetCenter.shared.reloadTimelines(ofKind: "QuietClock")
                reloadTask = nil
            }
        } catch { self.error = error.localizedDescription }
    }

    private func flushReload() {
        guard let pending = reloadTask else { return }
        pending.cancel()
        reloadTask = nil
        WidgetCenter.shared.reloadTimelines(ofKind: "QuietClock")
    }
}
