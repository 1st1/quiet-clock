import Foundation

enum ClockTime {
    static func label(for date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        date.formatted(format(locale: locale, timeZone: timeZone))
    }

    static func format(locale: Locale = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent) -> Date.FormatStyle {
        Date.FormatStyle(locale: locale, timeZone: timeZone)
            .hour(.defaultDigits(amPM: .omitted))
            .minute(.twoDigits)
    }

    static func nextMinute(after date: Date) -> Date {
        Date(timeIntervalSince1970: (floor(date.timeIntervalSince1970 / 60) + 1) * 60)
    }
}
