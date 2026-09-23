import Foundation
import CoreGraphics

enum DesktopGeometry {
    static func fit(_ proposed: CGRect, screens: [CGRect]) -> CGRect {
        guard let fallback = screens.first else { return proposed }
        let valid = [proposed.minX, proposed.minY, proposed.width, proposed.height].allSatisfy(\.isFinite)
        let frame = valid && proposed.width > 0 && proposed.height > 0 ? proposed : CGRect(x: fallback.minX, y: fallback.minY, width: 344, height: 344)
        let screen = screens.max { a, b in
            let a = a.intersection(frame), b = b.intersection(frame)
            return (a.isNull ? 0 : a.width * a.height) < (b.isNull ? 0 : b.width * b.height)
        } ?? fallback
        let width = min(max(frame.width, 160), screen.width)
        let height = min(max(frame.height, 80), screen.height)
        return CGRect(x: min(max(frame.minX, screen.minX), screen.maxX - width),
                      y: min(max(frame.minY, screen.minY), screen.maxY - height), width: width, height: height)
    }
}
