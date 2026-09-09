import SwiftUI
import WidgetKit

@main
struct QuietClockApp: App {
    var body: some Scene {
        Window("Quiet Clock", id: "appearance") {
            AppearanceEditor()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Clock Appearance…") { NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil) }
                    .keyboardShortcut(",")
            }
        }
    }
}

struct AppearanceEditor: View {
    @State private var appearance = ClockAppearance()
    @State private var saved = ClockAppearance()
    @State private var message = "Changes save automatically"
    @State private var reloadTask: Task<Void, Never>?
    @State private var error: String?
    @State private var smallPreview = false
    private let families = NSFontManager.shared.availableFontFamilies.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    ClockFace(date: context.date, appearance: appearance)
                        .frame(width: smallPreview ? 164 : 344, height: 164)
                        .background(appearance.transparentBackground ? Color(.windowBackgroundColor) : appearance.background, in: RoundedRectangle(cornerRadius: 20))
                        .frame(width: 420, height: 190)
                        .background {
                            LinearGradient(colors: [Color(red: 0.32, green: 0.4, blue: 0.44), Color(red: 0.66, green: 0.63, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                Picker("Preview size", selection: $smallPreview) {
                    Text("Small").tag(true)
                    Text("Medium").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(24)

            Form {
                Section("Typography") {
                    Picker("Font", selection: $appearance.fontFamily) {
                        ForEach(ClockAppearance.systemFamilies, id: \.self) { Text($0).tag($0) }
                        Divider()
                        ForEach(families, id: \.self) { Text($0).tag($0) }
                    }
                    Toggle("Size automatically", isOn: $appearance.automaticSize)
                    if !appearance.automaticSize {
                        HStack {
                            Slider(value: $appearance.fontSize, in: 20...140, step: 1) { Text("Font size") }
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
                    Toggle("Use system widget background", isOn: $appearance.transparentBackground)
                    if !appearance.transparentBackground {
                        Toggle("Automatic background color", isOn: $appearance.automaticBackgroundColor)
                        if !appearance.automaticBackgroundColor {
                            ColorPicker("Background color", selection: colorBinding(\.backgroundColor), supportsOpacity: false)
                        }
                    }
                    Text("The system background still renders a tile on macOS 15. This is not wallpaper transparency. Its appearance depends on macOS; the preview is approximate.")
                        .font(.caption).foregroundStyle(.secondary)
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
            Text("Changes apply to all Quiet Clock widgets. You can quit the app afterward.")
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
