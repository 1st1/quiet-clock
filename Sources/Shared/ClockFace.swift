import SwiftUI

extension ClockRGB {
    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }

    init(color: Color) {
        let rgb = NSColor(color).usingColorSpace(.sRGB) ?? .white
        red = min(1, max(0, rgb.redComponent))
        green = min(1, max(0, rgb.greenComponent))
        blue = min(1, max(0, rgb.blueComponent))
    }
}

extension ClockAppearance {
    func font(size: Double) -> Font {
        Self.typeface(family: fontFamily, weight: weight, size: size)
    }

    static func typeface(family: String, weight: Int, size: Double) -> Font {
        let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        let selectedWeight = min(8, max(0, weight))
        let designs: [String: Font.Design] = ["System Rounded": .rounded, "System": .default, "System Serif": .serif, "System Monospaced": .monospaced]
        if let design = designs[family] {
            return .system(size: size, weight: weights[selectedWeight], design: design)
        }
        let nativeWeights = [1, 2, 3, 5, 6, 7, 9, 10, 12]
        if let native = NSFontManager.shared.font(withFamily: family, traits: [], weight: nativeWeights[selectedWeight], size: size) {
            return Font(native)
        }
        return .system(size: size, weight: weights[selectedWeight], design: .rounded)
    }
}

extension ClockAlignment {
    var horizontal: HorizontalAlignment { switch self { case .left: .leading; case .center: .center; case .right: .trailing } }
    var frame: Alignment { switch self { case .left: .leading; case .center: .center; case .right: .trailing } }
    var text: TextAlignment { switch self { case .left: .leading; case .center: .center; case .right: .trailing } }
}

struct ClockFace: View {
    let date: Date
    var appearance = ClockAppearance()

    var body: some View {
        GeometryReader { geometry in
            let links = appearance.shortcuts.filter { $0.destination != nil }
            VStack(alignment: appearance.alignment.horizontal, spacing: links.isEmpty ? 0 : 8) {
                Link(destination: URL(string: "quietclock://settings")!) {
                    clockText(width: geometry.size.width)
                }
                    .buttonStyle(.plain)
                    .accessibilityHint("Open clock settings")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: appearance.alignment.frame)
                if !links.isEmpty {
                    DottedDivider()
                        .stroke(style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 4]))
                        .opacity(appearance.dividerLength == 0 ? 0 : appearance.dividerBrightness)
                        .frame(width: max(0, geometry.size.width - 24) * appearance.dividerLength, height: 1)
                        .frame(maxWidth: .infinity, alignment: appearance.alignment.frame)
                    ViewThatFits(in: .vertical) {
                        ForEach([1.0, 0.85, 0.7, 0.55, 0.4, 0.3, 0.2], id: \.self) { scale in
                            VStack(alignment: appearance.alignment.horizontal, spacing: appearance.linkSpacing * scale) {
                                ForEach(links) { shortcut in
                                    Link(destination: shortcut.widgetURL) {
                                        ShortcutLabel(shortcut: shortcut, size: appearance.linkSize, scale: scale, family: appearance.linkFontFamily, weight: appearance.linkWeight, iconSize: appearance.iconSize, iconGap: appearance.iconGap)
                                            .multilineTextAlignment(appearance.alignment.text)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: appearance.alignment.frame)
                                    .help(shortcut.destination?.absoluteString ?? "")
                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxHeight: geometry.size.height * 0.46)
                    .padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 12)
            .foregroundStyle(appearance.automaticTextColor ? Color.primary : appearance.textColor.color)
        }
    }

    private func clockText(width: CGFloat) -> some View {
        Text(ClockTime.label(for: date))
            .font(appearance.font(size: appearance.automaticSize ? min(width * 0.29, 100) : appearance.fontSize))
            .contentTransition(.identity)
            .transition(.identity)
            .animation(nil, value: date)
            .monospacedDigit()
            .tracking(appearance.spacing)
            .shadow(color: .black.opacity(0.22), radius: 3, x: 0, y: 2)
            .lineLimit(1)
            .minimumScaleFactor(0.2)
            .accessibilityLabel(date.formatted(date: .omitted, time: .shortened))
    }
}

struct DottedDivider: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

struct ServiceIconView: View {
    let name: String
    // A bounded cache keeps the full catalog inexpensive; only visible icons load.
    private static let images: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 64
        return cache
    }()
    private var icon: NSImage? {
        if let cached = Self.images.object(forKey: name as NSString) { return cached }
        guard let url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "ServiceIcons"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        Self.images.setObject(image, forKey: name as NSString)
        return image
    }
    var body: some View {
        if let image = icon {
            Image(nsImage: image).resizable().renderingMode(.template).scaledToFit()
        } else {
            Image(systemName: "globe").resizable().scaledToFit()
        }
    }
}

struct ShortcutLabel: View {
    let shortcut: ClockShortcut
    var size = 16.0
    var scale = 1.0
    var family = "System"
    var weight = 4
    var iconSize = 16.0
    var iconGap = 5.0
    var body: some View {
        HStack(spacing: iconGap * scale) {
            if shortcut.display != .text {
                ServiceIconView(name: shortcut.icon).frame(width: iconSize * scale, height: iconSize * scale)
            }
            if shortcut.display != .icon {
                Text(shortcut.title).font(ClockAppearance.typeface(family: family, weight: weight, size: size * scale))
                    .lineLimit(nil).fixedSize(horizontal: false, vertical: true)
            }
        }
        .shadow(color: .black.opacity(0.22), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shortcut.title)
    }
}
