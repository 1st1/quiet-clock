import SwiftUI

@main struct ClockLayoutTests {
    @MainActor static func main() {
        _ = NSApplication.shared
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        func measure(_ appearance: ClockAppearance, width: CGFloat = 344) -> CGSize {
            let host = NSHostingView(rootView: ClockFace(date: date, appearance: appearance, width: width))
            return host.fittingSize
        }
        var appearance = ClockAppearance()
        appearance.automaticSize = false
        appearance.fontSize = 60
        appearance.automaticLineHeight = false
        appearance.clockLineHeight = 80
        let short = measure(appearance)
        appearance.clockLineHeight = 160
        let tall = measure(appearance)
        assert(abs(tall.height - short.height - 80) < 1, "Line height must add vertical space without fitting into a fixed box")
        appearance.automaticLineHeight = true
        let smallType = measure(appearance)
        appearance.fontSize = 120
        assert(measure(appearance).height > smallType.height, "Larger type must grow the natural height")
        appearance.shortcuts = (0..<6).map { ClockShortcut(label: "A long link label that wraps onto multiple lines number \($0)", address: "https://example.com", display: .text) }
        let links = measure(appearance)
        assert(links.height > measure(ClockAppearance()).height + 100, "Links must add their full height")
        assert(measure(appearance, width: 200).height > links.height, "Wrapping should increase height instead of shrinking text")
        appearance.showDivider = false
        let noDivider = measure(appearance)
        assert(abs(links.height - noDivider.height - 17) < 1, "Hidden divider removes line and padding")
        appearance.linkSize = 32
        assert(measure(appearance).height > noDivider.height, "Link size must grow layout at full scale")
        print("Intrinsic clock layout, line height, wrapping, and divider checks passed.")
    }
}
