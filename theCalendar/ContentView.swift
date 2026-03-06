import SwiftUI
import EventKit
import AppKit

struct ContentView: View {
    @StateObject private var store = CalendarStore()
    @AppStorage("app_language") private var appLanguageRawValue = AppLanguage.system.rawValue
    @State private var selectedDate = Date()
    @State private var sidebarSelectedDate = Date()
    @State private var sidebarDisplayedMonth = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var searchText = ""
    @State private var showingAddEventSheet = false
    @State private var eventPreviewItem: EventPreviewItem?
    @State private var editingEventItem: EventPreviewItem?
    @State private var deleteCandidate: DeleteEventCandidate?

    private var appCalendar: Calendar {
        var calendar = Calendar(identifier: .persian)
        calendar.locale = currentLocale
        calendar.firstWeekday = 7
        return calendar
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    private var currentLocale: Locale {
        appLanguage.locale
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                calendar: appCalendar,
                sidebarDate: $sidebarSelectedDate,
                sidebarDisplayedMonth: $sidebarDisplayedMonth,
                calendars: store.calendars,
                selectedCalendarIDs: $store.selectedCalendarIDs,
                onSelectDate: { date in
                    selectedDate = date
                }
            )
            .navigationSplitViewColumnWidth(min: 230, ideal: 260)
        } detail: {
            VStack(spacing: 0) {
                navigationBar
                contentView
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .searchable(text: $searchText, placement: .toolbar, prompt: Text("search_events_placeholder"))
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: { showingAddEventSheet = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(!store.hasReadAccess || store.writableCalendars.isEmpty)
                    .help(String(localized: "help_add_event"))
                    .keyboardShortcut("n", modifiers: .command)
                }

                ToolbarItem(placement: .principal) {
                    Picker("", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
            }
            .toolbar(removing: .sidebarToggle)
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventSheet(
                    date: selectedDate,
                    calendars: store.writableCalendars,
                    pickerCalendar: appCalendar,
                    onSave: { draft in
                        store.addEvent(draft)
                        refreshEvents()
                    }
                )
            }
            .sheet(item: $eventPreviewItem) { item in
                EventPreviewSheet(
                    event: item.event,
                    calendar: appCalendar,
                    onEdit: {
                        eventPreviewItem = nil
                        editingEventItem = item
                    },
                    onDelete: {
                        eventPreviewItem = nil
                        deleteCandidate = DeleteEventCandidate(
                            eventIdentifier: item.event.eventIdentifier,
                            eventTitle: item.event.title
                        )
                    }
                )
            }
            .sheet(item: $editingEventItem) { item in
                EditEventSheet(
                    event: item.event,
                    calendars: store.writableCalendars,
                    pickerCalendar: appCalendar,
                    onSave: { draft in
                        guard let eventIdentifier = item.event.eventIdentifier else { return }
                        store.updateEvent(eventIdentifier: eventIdentifier, with: draft)
                        refreshEvents()
                    }
                )
            }
            .alert(
                String(localized: "delete_event_confirm_title"),
                isPresented: Binding(
                    get: { deleteCandidate != nil },
                    set: { isPresented in
                        if !isPresented { deleteCandidate = nil }
                    }
                ),
                presenting: deleteCandidate
            ) { candidate in
                Button("delete_button", role: .destructive) {
                    store.deleteEvent(eventIdentifier: candidate.eventIdentifier)
                    refreshEvents()
                    deleteCandidate = nil
                }
                Button("cancel_button", role: .cancel) {
                    deleteCandidate = nil
                }
            } message: { candidate in
                Text("\(String(localized: "delete_event_confirm_message"))\n\(candidate.eventTitle)")
            }
            .task {
                await store.requestAccessIfNeeded()
                refreshEvents()
            }
            .onChange(of: selectedDate) { _, _ in refreshEvents() }
            .onChange(of: viewMode) { _, _ in refreshEvents() }
            .onChange(of: searchText) { _, _ in refreshEvents() }
            .onChange(of: store.selectedCalendarIDs) { _, _ in
                store.persistSelectedCalendars()
                refreshEvents()
            }
        }
    }

    private var navigationBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(gregorianContextText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(0.8)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: { move(by: -1) }) {
                    Image(systemName: "chevron.backward")
                }
                .buttonStyle(.bordered)

                Button("today_button") {
                    selectedDate = Date()
                }
                .buttonStyle(.bordered)

                Button(action: { move(by: 1) }) {
                    Image(systemName: "chevron.forward")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var contentView: some View {
        if !store.hasReadAccess {
            AccessRequiredView()
        } else {
            switch viewMode {
            case .day:
                DayView(
                    date: selectedDate,
                    calendar: appCalendar,
                    events: store.filteredEvents,
                    onEventTap: { event in
                        eventPreviewItem = EventPreviewItem(event: event)
                    }
                )
            case .week:
                WeekView(
                    date: selectedDate,
                    calendar: appCalendar,
                    events: store.filteredEvents,
                    onSelectDay: { day in
                        selectedDate = day
                        viewMode = .day
                    },
                    onEventTap: { event in
                        eventPreviewItem = EventPreviewItem(event: event)
                    }
                )
            case .month:
                MonthView(
                    date: selectedDate,
                    calendar: appCalendar,
                    events: store.filteredEvents,
                    onSelectDay: { day in
                        selectedDate = day
                        viewMode = .day
                    },
                    onEventTap: { event in
                        eventPreviewItem = EventPreviewItem(event: event)
                    }
                )
            case .year:
                YearView(
                    date: selectedDate,
                    calendar: appCalendar,
                    events: store.filteredEvents,
                    onSelectMonth: { month in
                        selectedDate = month
                        viewMode = .month
                    }
                )
            }
        }
    }

    private var titleText: String {
        TitleFormatter.title(for: selectedDate, mode: viewMode, calendar: appCalendar)
    }

    private var gregorianContextText: String {
        GregorianFormatter.context(for: selectedDate, mode: viewMode, calendar: appCalendar)
    }

    private func move(by delta: Int) {
        let component: Calendar.Component
        switch viewMode {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }

        if let newDate = appCalendar.date(byAdding: component, value: delta, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func refreshEvents() {
        let range = DateRangeBuilder.visibleRange(for: selectedDate, mode: viewMode, calendar: appCalendar)
        store.loadEvents(in: range, searchText: searchText)
    }

}

private enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .day: return "view_mode_day"
        case .week: return "view_mode_week"
        case .month: return "view_mode_month"
        case .year: return "view_mode_year"
        }
    }
}

@MainActor
private final class CalendarStore: ObservableObject {
    @Published var calendars: [EKCalendar] = []
    @Published var selectedCalendarIDs: Set<String> = []
    @Published var filteredEvents: [EKEvent] = []
    @Published var authorization: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)

    private let eventStore = EKEventStore()
    private let defaults = UserDefaults.standard
    private let selectedCalendarIDsKey = "selected_calendar_ids"

    var writableCalendars: [EKCalendar] {
        calendars.filter(\.allowsContentModifications)
    }

    var hasReadAccess: Bool {
        authorization == .fullAccess
    }

    func requestAccessIfNeeded() async {
        authorization = EKEventStore.authorizationStatus(for: .event)
        if authorization == .notDetermined {
            do {
                _ = try await eventStore.requestFullAccessToEvents()
            } catch {
                // Keep status handling centralized below.
            }
            authorization = EKEventStore.authorizationStatus(for: .event)
        }

        if hasReadAccess {
            reloadCalendars()
        }
    }

    func reloadCalendars() {
        calendars = eventStore.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        if selectedCalendarIDs.isEmpty {
            let persistedIDs = Set(defaults.stringArray(forKey: selectedCalendarIDsKey) ?? [])
            if persistedIDs.isEmpty {
                selectedCalendarIDs = Set(calendars.map(\.calendarIdentifier))
            } else {
                let available = Set(calendars.map(\.calendarIdentifier))
                selectedCalendarIDs = persistedIDs.intersection(available)
                if selectedCalendarIDs.isEmpty {
                    selectedCalendarIDs = Set(calendars.map(\.calendarIdentifier))
                }
            }
        } else {
            let available = Set(calendars.map(\.calendarIdentifier))
            selectedCalendarIDs = selectedCalendarIDs.intersection(available)
        }

        persistSelectedCalendars()
    }

    func persistSelectedCalendars() {
        defaults.set(Array(selectedCalendarIDs), forKey: selectedCalendarIDsKey)
    }

    func loadEvents(in range: DateInterval, searchText: String) {
        guard hasReadAccess else {
            filteredEvents = []
            return
        }

        let activeCalendars = calendars.filter { selectedCalendarIDs.contains($0.calendarIdentifier) }
        let predicate = eventStore.predicateForEvents(withStart: range.start, end: range.end, calendars: activeCalendars)

        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        filteredEvents = eventStore.events(matching: predicate)
            .filter { event in
                guard !normalizedSearch.isEmpty else { return true }
                let haystack = [event.title, event.location, event.notes]
                    .compactMap { $0?.lowercased() }
                    .joined(separator: " ")
                return haystack.contains(normalizedSearch.lowercased())
            }
            .sorted(by: { $0.startDate < $1.startDate })
    }

    func addEvent(_ draft: EventDraft) {
        guard hasReadAccess else { return }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = draft.calendar
        event.title = draft.title.isEmpty ? String(localized: "new_event_default_title") : draft.title
        event.startDate = draft.startDate
        event.endDate = max(draft.endDate, draft.startDate.addingTimeInterval(60 * 15))
        event.isAllDay = draft.isAllDay
        event.notes = draft.notes.isEmpty ? nil : draft.notes

        do {
            try eventStore.save(event, span: .thisEvent)
            reloadCalendars()
        } catch {
            // Intentionally ignored; production apps should log to analytics.
        }
    }

    func updateEvent(eventIdentifier: String, with draft: EventDraft) {
        guard hasReadAccess else { return }
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else { return }
        guard event.calendar.allowsContentModifications else { return }

        event.calendar = draft.calendar
        event.title = draft.title.isEmpty ? String(localized: "new_event_default_title") : draft.title
        event.startDate = draft.startDate
        event.endDate = max(draft.endDate, draft.startDate.addingTimeInterval(60 * 15))
        event.isAllDay = draft.isAllDay
        event.notes = draft.notes.isEmpty ? nil : draft.notes

        do {
            try eventStore.save(event, span: .thisEvent)
            reloadCalendars()
        } catch {
            // Intentionally ignored; production apps should log to analytics.
        }
    }

    func deleteEvent(eventIdentifier: String) {
        guard hasReadAccess else { return }
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else { return }
        guard event.calendar.allowsContentModifications else { return }

        do {
            try eventStore.remove(event, span: .thisEvent)
            reloadCalendars()
        } catch {
            // Intentionally ignored; production apps should log to analytics.
        }
    }
}

private struct SidebarView: View {
    let calendar: Calendar
    @Binding var sidebarDate: Date
    @Binding var sidebarDisplayedMonth: Date
    let calendars: [EKCalendar]
    @Binding var selectedCalendarIDs: Set<String>
    let onSelectDate: (Date) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("calendars_section_title")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(calendars, id: \.calendarIdentifier) { source in
                        Toggle(isOn: binding(for: source.calendarIdentifier)) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(nsColor: NSColor(cgColor: source.cgColor) ?? .systemBlue))
                                    .frame(width: 8, height: 8)
                                Text(source.title)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Divider()
                .padding(.top, 8)

            MiniMonthView(
                selectedDate: $sidebarDate,
                displayedMonth: $sidebarDisplayedMonth,
                calendar: calendar,
                onSelectDate: onSelectDate
            )
            .padding(12)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { selectedCalendarIDs.contains(id) },
            set: { isEnabled in
                if isEnabled {
                    selectedCalendarIDs.insert(id)
                } else {
                    selectedCalendarIDs.remove(id)
                }
            }
        )
    }
}

private struct MiniMonthView: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    let calendar: Calendar
    let onSelectDate: (Date) -> Void

    private var days: [Date] {
        DateGridBuilder.monthGrid(for: displayedMonth, calendar: calendar)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: { moveMonth(by: -1) }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 1) {
                    Text(TitleFormatter.monthOnly(for: displayedMonth, calendar: calendar))
                        .font(.headline)
                    Text(GregorianFormatter.monthYear(for: displayedMonth))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .opacity(0.8)
                }

                Spacer()

                Button(action: { moveMonth(by: 1) }) {
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
            }

            WeekdayHeader(calendar: calendar)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let isCurrentMonth = calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
                    let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                    VStack(spacing: 0) {
                        Text(DayNumberFormatter.value(for: day, calendar: calendar))
                            .font(.caption2)
                        Text(GregorianFormatter.dayNumber(for: day))
                            .font(.system(size: 8))
                            .opacity(0.65)
                    }
                    .foregroundStyle(isCurrentMonth ? .primary : .secondary)
                    .frame(maxWidth: .infinity, minHeight: 22)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor.opacity(0.25) : .clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = day
                        displayedMonth = day
                        onSelectDate(day)
                    }
                }
            }
        }
    }

    private func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
}

private struct DayView: View {
    let date: Date
    let calendar: Calendar
    let events: [EKEvent]
    let onEventTap: (EKEvent) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text(TitleFormatter.title(for: date, mode: .day, calendar: calendar))
                    .font(.title2.bold())
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                Text(GregorianFormatter.fullDate(for: date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(0.8)
                    .padding(.horizontal, 16)

                ForEach(eventsForDay, id: \.eventIdentifier) { event in
                    EventRow(event: event, calendar: calendar, onTap: {
                        onEventTap(event)
                    })
                    .padding(.horizontal, 16)
                }

                if eventsForDay.isEmpty {
                    Text("no_events_text")
                        .foregroundStyle(.secondary)
                        .padding(.top, 24)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 10)
        }
    }

    private var eventsForDay: [EKEvent] {
        events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
    }
}

private struct WeekView: View {
    let date: Date
    let calendar: Calendar
    let events: [EKEvent]
    let onSelectDay: (Date) -> Void
    let onEventTap: (EKEvent) -> Void

    private var weekDays: [Date] {
        DateGridBuilder.weekDays(containing: date, calendar: calendar)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(TitleFormatter.weekdayAndDay(for: day, calendar: calendar))
                                .font(.headline)
                                .foregroundColor(calendar.isDateInToday(day) ? .accentColor : .primary)
                            Text(GregorianFormatter.weekdayDay(for: day))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .opacity(0.75)
                        }

                        ForEach(events.filter { calendar.isDate($0.startDate, inSameDayAs: day) }, id: \.eventIdentifier) { event in
                            EventChip(event: event, onTap: {
                                onEventTap(event)
                            })
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectDay(day)
                    }
                }
            }
            .padding(12)
        }
    }
}

private struct MonthView: View {
    let date: Date
    let calendar: Calendar
    let events: [EKEvent]
    let onSelectDay: (Date) -> Void
    let onEventTap: (EKEvent) -> Void

    private var days: [Date] {
        DateGridBuilder.monthGrid(for: date, calendar: calendar)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                WeekdayHeader(calendar: calendar)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(GregorianFormatter.dayWithOptionalMonth(for: day))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .opacity(0.7)
                                Spacer()
                                Text(DayNumberFormatter.value(for: day, calendar: calendar))
                                    .font(.headline)
                                    .foregroundStyle(calendar.isDate(day, equalTo: date, toGranularity: .month) ? .primary : .secondary)
                                    .padding(6)
                                    .background(
                                        Circle().fill(calendar.isDateInToday(day) ? Color.accentColor.opacity(0.25) : .clear)
                                    )
                            }

                            ForEach(eventsForDay(day).prefix(3), id: \.eventIdentifier) { event in
                                EventChip(event: event, onTap: {
                                    onEventTap(event)
                                })
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(6)
                        .frame(minHeight: 110, alignment: .top)
                        .overlay {
                            Rectangle().stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectDay(day)
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    private func eventsForDay(_ day: Date) -> [EKEvent] {
        events.filter { calendar.isDate($0.startDate, inSameDayAs: day) }
    }
}

private struct YearView: View {
    let date: Date
    let calendar: Calendar
    let events: [EKEvent]
    let onSelectMonth: (Date) -> Void

    private var months: [Date] {
        DateGridBuilder.yearMonths(containing: date, calendar: calendar)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(months, id: \.self) { month in
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: { onSelectMonth(month) }) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(TitleFormatter.monthOnly(for: month, calendar: calendar))
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                Text(GregorianFormatter.monthYear(for: month))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .opacity(0.75)
                            }
                        }
                        .buttonStyle(.plain)

                        WeekdayHeader(calendar: calendar)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                            ForEach(DateGridBuilder.monthGrid(for: month, calendar: calendar), id: \.self) { day in
                                VStack(spacing: 0) {
                                    Text(DayNumberFormatter.value(for: day, calendar: calendar))
                                        .font(.caption2)
                                    Text(GregorianFormatter.dayNumber(for: day))
                                        .font(.system(size: 8))
                                        .opacity(0.65)
                                }
                                .foregroundStyle(calendar.isDate(day, equalTo: month, toGranularity: .month) ? .primary : .secondary)
                                .frame(maxWidth: .infinity, minHeight: 22)
                                .background(
                                    Circle().fill(calendar.isDateInToday(day) ? Color.accentColor.opacity(0.25) : .clear)
                                )
                            }
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.quaternary.opacity(0.08)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectMonth(month)
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct WeekdayHeader: View {
    let calendar: Calendar

    var body: some View {
        let symbols = calendar.veryShortWeekdaySymbols.shifted(startingAt: calendar.firstWeekday - 1)
        HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct EventRow: View {
    let event: EKEvent
    let calendar: Calendar
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color(nsColor: NSColor(cgColor: event.calendar.cgColor) ?? .systemBlue))
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)

                    Text(TimeFormatter.range(for: event, calendar: calendar))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let location = event.location, !location.isEmpty {
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.quaternary.opacity(0.14))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AccessRequiredView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text("calendar_access_required")
                .font(.headline)
            Button("open_settings_button") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EventChip: View {
    let event: EKEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(nsColor: NSColor(cgColor: event.calendar.cgColor) ?? .systemBlue))
                    .frame(width: 6, height: 6)
                Text(event.title)
                    .lineLimit(1)
                    .font(.caption)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Capsule().fill(.quaternary.opacity(0.2)))
        }
        .buttonStyle(.plain)
    }
}

private struct AddEventSheet: View {
    let date: Date
    let calendars: [EKCalendar]
    let pickerCalendar: Calendar
    let onSave: (EventDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes = ""
    @State private var isAllDay = false
    @State private var selectedCalendarID: String = ""

    init(date: Date, calendars: [EKCalendar], pickerCalendar: Calendar, onSave: @escaping (EventDraft) -> Void) {
        self.date = date
        self.calendars = calendars
        self.pickerCalendar = pickerCalendar
        self.onSave = onSave
        _startDate = State(initialValue: date)
        _endDate = State(initialValue: date.addingTimeInterval(60 * 60))
        _selectedCalendarID = State(initialValue: calendars.first?.calendarIdentifier ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("new_event_title")
                .font(.title2.bold())

            TextField("event_title_placeholder", text: $title)
                .textFieldStyle(.roundedBorder)

            Toggle("all_day_toggle", isOn: $isAllDay)

            DatePicker("starts_label", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
            DatePicker("ends_label", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])

            Picker("calendar_label", selection: $selectedCalendarID) {
                ForEach(calendars, id: \.calendarIdentifier) { calendar in
                    Text(calendar.title).tag(calendar.calendarIdentifier)
                }
            }

            TextField("notes_placeholder", text: $notes, axis: .vertical)
                .lineLimit(3...6)

            HStack {
                Spacer()
                Button("cancel_button", role: .cancel) {
                    dismiss()
                }
                Button("add_button") {
                    guard let calendar = calendars.first(where: { $0.calendarIdentifier == selectedCalendarID }) else {
                        return
                    }

                    onSave(EventDraft(
                        title: title,
                        startDate: startDate,
                        endDate: endDate,
                        isAllDay: isAllDay,
                        notes: notes,
                        calendar: calendar
                    ))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 6)
        }
        .padding(16)
        .frame(width: 420)
        .environment(\.calendar, pickerCalendar)
    }
}

private struct EventPreviewItem: Identifiable {
    let id = UUID()
    let event: EKEvent
}

private struct DeleteEventCandidate {
    let eventIdentifier: String
    let eventTitle: String
}

private struct EventPreviewSheet: View {
    let event: EKEvent
    let calendar: Calendar
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var isEditable: Bool {
        event.calendar.allowsContentModifications
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.title)
                .font(.title2.bold())

            Label(TimeFormatter.range(for: event, calendar: calendar), systemImage: "clock")
                .foregroundStyle(.secondary)

            if let location = event.location, !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
                    .foregroundStyle(.secondary)
            }

            Label(event.calendar.title, systemImage: "calendar")
                .foregroundStyle(.secondary)

            if let notes = event.notes, !notes.isEmpty {
                Divider()
                Text(notes)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                if isEditable {
                    Button("edit_button") {
                        dismiss()
                        onEdit()
                    }
                    Button("delete_button", role: .destructive) {
                        dismiss()
                        onDelete()
                    }
                }

                Spacer()
                Button("close_button") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 420)
    }
}

private struct EditEventSheet: View {
    let event: EKEvent
    let calendars: [EKCalendar]
    let pickerCalendar: Calendar
    let onSave: (EventDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var isAllDay: Bool
    @State private var selectedCalendarID: String

    init(event: EKEvent, calendars: [EKCalendar], pickerCalendar: Calendar, onSave: @escaping (EventDraft) -> Void) {
        self.event = event
        self.calendars = calendars
        self.pickerCalendar = pickerCalendar
        self.onSave = onSave

        _title = State(initialValue: event.title)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
        _notes = State(initialValue: event.notes ?? "")
        _isAllDay = State(initialValue: event.isAllDay)
        _selectedCalendarID = State(initialValue: event.calendar.calendarIdentifier)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("edit_event_title")
                .font(.title2.bold())

            TextField("event_title_placeholder", text: $title)
                .textFieldStyle(.roundedBorder)

            Toggle("all_day_toggle", isOn: $isAllDay)

            DatePicker("starts_label", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
            DatePicker("ends_label", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])

            Picker("calendar_label", selection: $selectedCalendarID) {
                ForEach(calendars, id: \.calendarIdentifier) { calendar in
                    Text(calendar.title).tag(calendar.calendarIdentifier)
                }
            }

            TextField("notes_placeholder", text: $notes, axis: .vertical)
                .lineLimit(3...6)

            HStack {
                Spacer()
                Button("cancel_button", role: .cancel) {
                    dismiss()
                }
                Button("save_button") {
                    guard let calendar = calendars.first(where: { $0.calendarIdentifier == selectedCalendarID }) else {
                        return
                    }

                    onSave(EventDraft(
                        title: title,
                        startDate: startDate,
                        endDate: endDate,
                        isAllDay: isAllDay,
                        notes: notes,
                        calendar: calendar
                    ))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 6)
        }
        .padding(16)
        .frame(width: 420)
        .environment(\.calendar, pickerCalendar)
    }
}

private struct EventDraft {
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let notes: String
    let calendar: EKCalendar
}

private enum TitleFormatter {
    static func title(for date: Date, mode: CalendarViewMode, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale

        switch mode {
        case .day:
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: date)
        case .week:
            let weekDays = DateGridBuilder.weekDays(containing: date, calendar: calendar)
            guard let start = weekDays.first, let end = weekDays.last else { return "" }
            formatter.dateFormat = "d MMM"
            let startText = formatter.string(from: start)
            let endText = formatter.string(from: end)
            return "\(startText) - \(endText)"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }

    static func monthOnly(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }

    static func weekdayAndDay(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }
}

private enum GregorianFormatter {
    private static var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    private static var locale: Locale {
        Locale(identifier: "en_US_POSIX")
    }

    static func context(for date: Date, mode: CalendarViewMode, calendar: Calendar) -> String {
        switch mode {
        case .day:
            return fullDate(for: date)
        case .week:
            let days = DateGridBuilder.weekDays(containing: date, calendar: calendar)
            guard let start = days.first, let end = days.last else { return "" }
            let formatter = DateFormatter()
            formatter.calendar = self.calendar
            formatter.locale = locale
            formatter.dateFormat = "d MMM"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .month:
            let visibleDays = DateGridBuilder.monthGrid(for: date, calendar: calendar)
            guard let start = visibleDays.first, let end = visibleDays.last else {
                return monthYear(for: date)
            }
            return monthYearRange(from: start, to: end)
        case .year:
            let formatter = DateFormatter()
            formatter.calendar = self.calendar
            formatter.locale = locale
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }

    static func monthYear(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    static func fullDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    static func weekdayDay(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }

    static func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    static func dayWithOptionalMonth(for date: Date) -> String {
        let includeMonth = calendar.component(.day, from: date) == 1
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = includeMonth ? "d MMM" : "d"
        return formatter.string(from: date)
    }

    static func monthYearRange(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateFormat = "MMM yyyy"

        let startText = formatter.string(from: start)
        let endText = formatter.string(from: end)
        return startText == endText ? startText : "\(startText) - \(endText)"
    }
}

private enum TimeFormatter {
    static func range(for event: EKEvent, calendar: Calendar) -> String {
        if event.isAllDay {
            return String(localized: "all_day_text")
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}

private enum DayNumberFormatter {
    static func value(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
private enum DateRangeBuilder {
    static func visibleRange(for date: Date, mode: CalendarViewMode, calendar: Calendar) -> DateInterval {
        switch mode {
        case .day:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return DateInterval(start: start, end: end)
        case .week:
            let days = DateGridBuilder.weekDays(containing: date, calendar: calendar)
            let start = calendar.startOfDay(for: days.first ?? date)
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
            return DateInterval(start: start, end: end)
        case .month:
            let days = DateGridBuilder.monthGrid(for: date, calendar: calendar)
            let start = calendar.startOfDay(for: days.first ?? date)
            let end = calendar.date(byAdding: .day, value: days.count, to: start) ?? start
            return DateInterval(start: start, end: end)
        case .year:
            let months = DateGridBuilder.yearMonths(containing: date, calendar: calendar)
            let start = calendar.startOfDay(for: months.first ?? date)
            let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start
            return DateInterval(start: start, end: end)
        }
    }
}

private enum DateGridBuilder {
    static func weekDays(containing date: Date, calendar: Calendar) -> [Date] {
        let reference = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: reference)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -offset, to: reference) ?? reference
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func monthGrid(for date: Date, calendar: Calendar) -> [Date] {
        let monthComponents = calendar.dateComponents([.year, .month], from: date)
        guard let monthStart = calendar.date(from: monthComponents),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        var result: [Date] = []
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let leading = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        for dayOffset in stride(from: leading, to: 0, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: monthStart) {
                result.append(date)
            }
        }

        for day in dayRange {
            if let current = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                result.append(current)
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

    static func yearMonths(containing date: Date, calendar: Calendar) -> [Date] {
        let year = calendar.component(.year, from: date)
        return (1...12).compactMap { month in
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            return calendar.date(from: components)
        }
    }
}

private extension Array where Element == String {
    func shifted(startingAt index: Int) -> [String] {
        guard indices.contains(index) else { return self }
        return Array(self[index...] + self[..<index])
    }
}
