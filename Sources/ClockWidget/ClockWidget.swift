import SwiftUI
import WidgetKit

struct ClockEntry: TimelineEntry {
    let date: Date
    var appearance = ClockAppearance()
}

struct ClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(ClockEntry(date: Date(), appearance: (try? AppearanceStore.shared.load()) ?? ClockAppearance()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        let now = Date()
        let appearance = (try? AppearanceStore.shared.load()) ?? ClockAppearance()
        completion(Timeline(
            entries: ClockTime.dates(from: now).map { ClockEntry(date: $0, appearance: appearance) },
            policy: .after(now.addingTimeInterval(3600))
        ))
    }
}

@main
struct QuietClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuietClock", provider: ClockProvider()) { entry in
            ClockFace(date: entry.date, appearance: entry.appearance)
                .widgetURL(URL(string: "quietclock://idle")!)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Quiet Clock")
        .description("Just the hours and minutes. A little quieter.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(true)
    }
}
