import SwiftUI

/// Keep discrete values without the dense automatic tick marks of stepped sliders.
struct SettingsSlider<Label: View>: View {
    let value: Binding<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    let label: Label

    init(value: Binding<Double>, in bounds: ClosedRange<Double>, step: Double, @ViewBuilder label: () -> Label) {
        self.value = value
        self.bounds = bounds
        self.step = step
        self.label = label()
    }

    var body: some View {
        Slider(value: Binding(get: { value.wrappedValue }, set: { proposed in
            let snapped = bounds.lowerBound + ((proposed - bounds.lowerBound) / step).rounded() * step
            value.wrappedValue = min(bounds.upperBound, max(bounds.lowerBound, snapped))
        }), in: bounds) { label }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value.wrappedValue = min(bounds.upperBound, value.wrappedValue + step)
            case .decrement: value.wrappedValue = max(bounds.lowerBound, value.wrappedValue - step)
            @unknown default: break
            }
        }
    }
}
