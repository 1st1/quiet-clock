import Foundation

@main
struct ClockTimeTests {
    static func main() {
        let utc = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        let date = ISO8601DateFormatter().date(from: "2026-09-09T23:59:42Z")!
        let next = ClockTime.nextMinute(after: date)
        assert(calendar.component(.second, from: next) == 0)
        assert(calendar.component(.day, from: next) == 10)
        assert(next.timeIntervalSince(date) == 18)
        assert(ClockTime.nextMinute(after: next).timeIntervalSince(next) == 60)
        assert(ClockTime.nextMinute(after: next.addingTimeInterval(0.5)) == next.addingTimeInterval(60))
        assert(ClockTime.label(for: date, locale: Locale(identifier: "en_GB"), timeZone: utc) == "23:59")
        assert(ClockTime.label(for: date, locale: Locale(identifier: "en_US"), timeZone: utc) == "11:59")
        assert(ClockTime.label(for: next, locale: Locale(identifier: "en_GB"), timeZone: utc) == "0:00")
        let liveStyle = ClockTime.format(locale: Locale(identifier: "en_GB"), timeZone: utc)
        assert(liveStyle.format(date) == "23:59")
        assert(liveStyle.format(next) == "0:00")
        assert(liveStyle.format(date.addingTimeInterval(10)) == liveStyle.format(date),
               "Seconds must not appear in the live clock")
        print("Clock formatting and minute-boundary tests passed.")
    }
}
