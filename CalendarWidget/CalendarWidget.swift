import WidgetKit
import SwiftUI

struct CalendarEntry: TimelineEntry {
    let date: Date
}

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(CalendarEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        var entries: [CalendarEntry] = []
        let startOfToday = Calendar.current.startOfDay(for: now)

        // Populate a week worth of entries so timeline preview can step through days.
        for offset in 0..<7 {
            if let day = Calendar.current.date(byAdding: .day, value: offset, to: startOfToday) {
                entries.append(CalendarEntry(date: day))
            }
        }

        let nextRefresh = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86400)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
}

private enum WidgetLanguageStyle {
    case english
    case persian

    var locale: Locale {
        switch self {
        case .english:
            return Locale(identifier: "en_US_POSIX")
        case .persian:
            return Locale(identifier: "fa_IR")
        }
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .english:
            return .leftToRight
        case .persian:
            return .rightToLeft
        }
    }

    var title: String {
        switch self {
        case .english:
            return "Persian Calendar"
        case .persian:
            return "تقویم پارسی"
        }
    }

    var subtitle: String {
        switch self {
        case .english:
            return "Today"
        case .persian:
            return "امروز"
        }
    }
}

private struct NativeCalendarWidgetView: View {
    let entry: CalendarEntry
    let style: WidgetLanguageStyle
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private var calendar: Calendar {
        var c = Calendar(identifier: .persian)
        c.locale = style.locale
        c.firstWeekday = 7
        return c
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallBody
            case .systemMedium:
                mediumBody
            default:
                smallBody
            }
        }
        .environment(\.layoutDirection, style.layoutDirection)
        .padding(family == .systemSmall ? 6 : 8)
        .background(backgroundGradient)
    }

    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(.sRGB, white: 0.12, opacity: 1.0),
                    Color(.sRGB, white: 0.09, opacity: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color(.sRGB, white: 0.98, opacity: 1.0),
                Color(.sRGB, white: 0.93, opacity: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.75) : .black.opacity(0.62)
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.62) : .black.opacity(0.5)
    }

    private var subtleSurface: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
    }

    private var smallBody: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(FormatterCache.weekdayFull.string(from: entry.date, calendar: calendar, locale: style.locale))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(primaryTextColor.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)

            Text(FormatterCache.day.string(from: entry.date, calendar: calendar, locale: style.locale))
                .font(.system(size: 66, weight: .bold, design: .rounded))
                .foregroundColor(primaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)

            VStack(alignment: .center, spacing: 2) {
                Text(FormatterCache.monthYear.string(from: entry.date, calendar: calendar, locale: style.locale))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(primaryTextColor.opacity(0.86))
                Text(FormatterCache.gregorianDayMonth.string(from: entry.date, calendar: FormatterCache.gregorianCalendar, locale: FormatterCache.gregorianLocale))
                    .font(.caption2)
                    .foregroundColor(tertiaryTextColor)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var mediumBody: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(FormatterCache.day.string(from: entry.date, calendar: calendar, locale: style.locale))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(FormatterCache.weekdayFull.string(from: entry.date, calendar: calendar, locale: style.locale))
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)

                Text(FormatterCache.monthYear.string(from: entry.date, calendar: calendar, locale: style.locale))
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                Text(FormatterCache.gregorianDayMonth.string(from: entry.date, calendar: FormatterCache.gregorianCalendar, locale: FormatterCache.gregorianLocale))
                    .font(.caption2)
                    .foregroundColor(tertiaryTextColor)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            monthGrid
                .frame(maxWidth: .infinity)
        }
    }

    private var header: some View {
        HStack {
            Text(style.title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Text(style.subtitle)
                .font(.caption2.weight(.medium))
                .foregroundColor(.white.opacity(0.65))
        }
    }

    private var monthGrid: some View {
        let days = DateGrid.monthGrid(containing: entry.date, calendar: calendar)
        let weekdaySymbols = calendar.veryShortWeekdaySymbols.shifted(startingAt: calendar.firstWeekday - 1)

        return VStack(spacing: 5) {
            HStack(spacing: 2) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(tertiaryTextColor)
                            .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
                ForEach(days, id: \.self) { day in
                    let inMonth = calendar.isDate(day, equalTo: entry.date, toGranularity: .month)
                    let isToday = calendar.isDateInToday(day)

                    Text(FormatterCache.day.string(from: day, calendar: calendar, locale: style.locale))
                        .font(.system(size: 10, weight: isToday ? .bold : .regular))
                        .foregroundColor(
                            isToday ? .white :
                                (inMonth ? primaryTextColor.opacity(0.88) : tertiaryTextColor.opacity(0.7))
                        )
                        .frame(maxWidth: .infinity, minHeight: 16)
                        .background(
                            Circle().fill(isToday ? Color.accentColor.opacity(0.95) : .clear)
                        )
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(subtleSurface)
        )
    }
}

private enum DateGrid {
    static func week(containing date: Date, calendar: Calendar) -> [Date] {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func monthGrid(containing date: Date, calendar: Calendar) -> [Date] {
        let monthComponents = calendar.dateComponents([.year, .month], from: date)
        guard let monthStart = calendar.date(from: monthComponents),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        var result: [Date] = []
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let leading = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        for offset in stride(from: leading, to: 0, by: -1) {
            if let d = calendar.date(byAdding: .day, value: -offset, to: monthStart) {
                result.append(d)
            }
        }

        for day in dayRange {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                result.append(d)
            }
        }

        while result.count % 7 != 0 || result.count < 42 {
            if let last = result.last,
               let next = calendar.date(byAdding: .day, value: 1, to: last) {
                result.append(next)
            } else {
                break
            }
        }

        return result
    }
}

private enum FormatterCache {
    static let gregorianCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en_US_POSIX")
        return c
    }()
    static let gregorianLocale = Locale(identifier: "en_US_POSIX")
    static let weekdayFull = CachedFormatter(format: "EEEE")
    static let weekdayShort = CachedFormatter(format: "EEE")
    static let day = CachedFormatter(format: "d")
    static let monthYear = CachedFormatter(format: "LLLL yyyy")
    static let gregorianDayMonth = CachedFormatter(format: "d MMMM")
}

private struct CachedFormatter {
    let format: String

    func string(from date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

private extension Array where Element == String {
    func shifted(startingAt index: Int) -> [String] {
        guard indices.contains(index) else { return self }
        return Array(self[index...] + self[..<index])
    }
}

struct CalendarWidgetPersian: Widget {
    let kind = "CalendarWidgetPersian"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            NativeCalendarWidgetView(entry: entry, style: .persian)
        }
        .configurationDisplayName("Calendar FA (Persian Digits)")
        .description("Persian calendar widget with Persian text and digits")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CalendarWidgetEnglish: Widget {
    let kind = "CalendarWidgetEnglish"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            NativeCalendarWidgetView(entry: entry, style: .english)
        }
        .configurationDisplayName("Calendar EN (English Digits)")
        .description("Persian calendar widget with English text and digits")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalendarWidgetPersian()
        CalendarWidgetEnglish()
    }
}
