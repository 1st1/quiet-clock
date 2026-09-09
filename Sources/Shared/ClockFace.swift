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
    var background: Color {
        transparentBackground ? .clear : (automaticBackgroundColor ? Color(.windowBackgroundColor) : backgroundColor.color)
    }

    func font(size: Double) -> Font {
        let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        let selectedWeight = min(8, max(0, weight))
        let designs: [String: Font.Design] = ["System Rounded": .rounded, "System": .default, "System Serif": .serif, "System Monospaced": .monospaced]
        if let design = designs[fontFamily] {
            return .system(size: size, weight: weights[selectedWeight], design: design)
        }
        let nativeWeights = [1, 2, 3, 5, 6, 7, 9, 10, 12]
        if let native = NSFontManager.shared.font(withFamily: fontFamily, traits: [], weight: nativeWeights[selectedWeight], size: size) {
            return Font(native)
        }
        return .system(size: size, weight: weights[selectedWeight], design: .rounded)
    }
}

struct ClockFace: View {
    let date: Date
    var appearance = ClockAppearance()

    var body: some View {
        GeometryReader { geometry in
            Text(ClockTime.label(for: date))
                .font(appearance.font(size: appearance.automaticSize ? min(geometry.size.width * 0.29, 100) : appearance.fontSize))
                .monospacedDigit()
                .tracking(appearance.spacing)
                .foregroundStyle(appearance.automaticTextColor ? Color.primary : appearance.textColor.color)
                .shadow(color: .black.opacity(0.22), radius: 3, x: 0, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(date.formatted(date: .omitted, time: .shortened))
        }
    }
}
