import Foundation

@main
struct ClockTimeTests {
    static func main() {
        let utc = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        let date = ISO8601DateFormatter().date(from: "2026-09-09T23:59:42Z")!
        let dates = ClockTime.dates(from: date, calendar: calendar)
        assert(dates.count == 181)
        assert(dates.first == date)
        assert(calendar.component(.second, from: dates[1]) == 0)
        assert(calendar.component(.day, from: dates[1]) == 10)
        assert(dates[1].timeIntervalSince(date) == 18)
        assert(zip(dates.dropFirst(), dates.dropFirst(2)).allSatisfy { $1.timeIntervalSince($0) == 60 })
        assert(ClockTime.label(for: date, locale: Locale(identifier: "en_GB"), timeZone: utc) == "23:59")
        assert(ClockTime.label(for: date, locale: Locale(identifier: "en_US"), timeZone: utc) == "11:59")
        assert(ClockTime.label(for: dates[1], locale: Locale(identifier: "en_GB"), timeZone: utc) == "0:00")
        print("Clock formatting and minute-boundary tests passed.")
    }
}
