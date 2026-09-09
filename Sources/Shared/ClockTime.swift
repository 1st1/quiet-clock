import Foundation

enum ClockTime {
    static func label(for date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        date.formatted(
            Date.FormatStyle(locale: locale, timeZone: timeZone)
                .hour(.defaultDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
    }

    // Three hours of runway allow for delayed timeline reloads without a resident process.
    static func dates(from now: Date, calendar: Calendar = .current) -> [Date] {
        let minute = calendar.dateInterval(of: .minute, for: now)!.start
        return [now] + (1...180).map { minute.addingTimeInterval(Double($0) * 60) }
    }
}
