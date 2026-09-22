import SwiftUI

struct ShortcutEditor: View {
    @Binding var shortcut: ClockShortcut
    let linkSize: Double
    let moveUp: () -> Void
    let moveDown: () -> Void
    let canMoveUp: Bool
    let canMoveDown: Bool
    let remove: () -> Void
    @State private var choosingIcon = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ShortcutLabel(shortcut: shortcut, size: linkSize)
                Spacer()
                Button(action: moveUp) { Image(systemName: "arrow.up") }.disabled(!canMoveUp).help("Move up")
                Button(action: moveDown) { Image(systemName: "arrow.down") }.disabled(!canMoveDown).help("Move down")
                Button(role: .destructive, action: remove) { Image(systemName: "trash") }.help("Remove shortcut")
            }
            TextField("URL", text: $shortcut.address, prompt: Text("https://linear.app"))
            TextField("Label", text: $shortcut.label, prompt: Text("Uses the website name if empty"))
            Picker("Display", selection: $shortcut.display) {
                ForEach(ShortcutDisplay.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            if shortcut.display != .text {
                HStack {
                    Text("Icon")
                    Spacer()
                    Button {
                        choosingIcon = true
                    } label: {
                        HStack {
                            ServiceIconView(name: shortcut.icon).frame(width: 18, height: 18)
                            Text(ServiceIcon.all.first(where: { $0.id == shortcut.icon })?.name ?? "Website")
                            Image(systemName: "chevron.down")
                        }
                    }
                    .popover(isPresented: $choosingIcon) {
                        IconPicker(selection: $shortcut.icon) { choosingIcon = false }
                    }
                }
            }
            HStack {
                Button("Open") { BrowserLauncher.open(shortcut) }.disabled(shortcut.destination == nil)
            }
            if shortcut.destination == nil {
                Text(shortcut.address.isEmpty ? "Add a URL to show this shortcut on the widget." : "Enter a valid http or https website address.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct IconPicker: View {
    @Binding var selection: String
    let close: () -> Void
    @State private var search = ""
    private var matches: [ServiceIcon] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? ServiceIcon.all : ServiceIcon.all.filter {
            $0.name.localizedStandardContains(query) || $0.id.localizedStandardContains(query)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search \(ServiceIcon.all.count - 1) service icons", text: $search)
                .textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(matches) { icon in
                        Button {
                            selection = icon.id
                            close()
                        } label: {
                            VStack(spacing: 7) {
                                ServiceIconView(name: icon.id).frame(width: 24, height: 24)
                                Text(icon.name).font(.caption).lineLimit(nil).fixedSize(horizontal: false, vertical: true).frame(minHeight: 28)
                            }
                            .frame(maxWidth: .infinity).padding(8)
                            .background(selection == icon.id ? Color.accentColor.opacity(0.16) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(icon.name)
                    }
                }
                if matches.isEmpty { Text("No matching icons").foregroundStyle(.secondary).padding() }
            }
            Text("Simple Icons · bundled locally").font(.caption).foregroundStyle(.secondary)
        }
        .padding(16).frame(width: 420, height: 380)
    }
}

enum BrowserLauncher {
    static func open(_ shortcut: ClockShortcut) {
        guard let url = shortcut.destination else { return }
        // Resolve the HTTPS browser independently of the destination's app associations.
        guard let browser = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) else {
            NSWorkspace.shared.open(url)
            return
        }
        NSWorkspace.shared.open([url], withApplicationAt: browser, configuration: NSWorkspace.OpenConfiguration())
    }
    static func handle(_ url: URL) {
        guard let id = ClockShortcut.id(from: url),
              let settings = try? AppearanceStore.shared.load(),
              let shortcut = settings.shortcuts.first(where: { $0.id == id }) else { return }
        open(shortcut)
    }
}
