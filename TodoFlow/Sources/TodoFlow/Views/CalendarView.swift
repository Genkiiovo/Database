import SwiftUI

// MARK: - CalendarView

struct CalendarView: View {
    @EnvironmentObject var store: AppStore

    @State private var displayMonth = Date()
    @State private var selectedDate: Date?

    private let cal      = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    private let columns  = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {

                // ── Header ─────────────────────────────────────
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayMonth, formatter: monthYearFmt)
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.textPrimary)
                        Text(subtitleText)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        navButton("chevron.left") { shiftMonth(-1) }
                        Button("今天") { displayMonth = Date(); selectedDate = Date() }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.accent)
                            .buttonStyle(.plain)
                        navButton("chevron.right") { shiftMonth(1) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // ── Calendar grid ──────────────────────────────
                VStack(spacing: 0) {
                    // Weekday labels
                    HStack(spacing: 0) {
                        ForEach(weekdays, id: \.self) { d in
                            Text(d)
                                .font(Theme.captionFont)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.textTertiary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)

                    Divider().padding(.horizontal, 8)

                    // Day cells
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(gridDays.indices, id: \.self) { idx in
                            if let date = gridDays[idx] {
                                DayCell(
                                    date:           date,
                                    events:         eventsOn(date),
                                    isToday:        cal.isDateInToday(date),
                                    isSelected:     selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false,
                                    isCurrentMonth: cal.isDate(date, equalTo: displayMonth, toGranularity: .month)
                                )
                                .onTapGesture { selectedDate = date }
                            } else {
                                Color.clear.frame(height: 68)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }
                .cardStyle()
                .padding(.horizontal, 24)

                // ── Events for selected date ───────────────────
                if let sel = selectedDate {
                    let dayEvents = eventsOn(sel)
                    if !dayEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(sel, formatter: dayFmt)
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, 24)

                            ForEach(dayEvents) { ev in
                                EventRow(event: ev).padding(.horizontal, 24)
                            }
                        }
                    }
                }

                // ── Upcoming list ──────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("全部待办 (\(upcomingAll.count))")
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, 24)

                    if upcomingAll.isEmpty {
                        Text("暂无待办事项")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textTertiary)
                            .padding(.horizontal, 24)
                    } else {
                        ForEach(upcomingAll.prefix(20)) { ev in
                            EventRow(event: ev).padding(.horizontal, 24)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .background(Theme.background)
    }

    // MARK: - Computed

    private var subtitleText: String {
        let n = store.upcomingCount
        return n == 0 ? "本周无截止" : "本周 \(n) 项截止"
    }

    private var upcomingAll: [CalendarEvent] {
        store.calendarEvents.filter { $0.date >= Date() }
    }

    private var gridDays: [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: displayMonth),
              let firstWeekday = cal.dateComponents([.weekday], from: interval.start).weekday
        else { return [] }

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        var cursor = interval.start
        while cursor < interval.end {
            days.append(cursor)
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func eventsOn(_ date: Date) -> [CalendarEvent] {
        store.calendarEvents.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    private func shiftMonth(_ delta: Int) {
        displayMonth = cal.date(byAdding: .month, value: delta, to: displayMonth) ?? displayMonth
    }

    private func navButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(Theme.inputBg)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Formatters

    private var monthYearFmt: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "yyyy年 M月"; return f
    }
    private var dayFmt: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "M月d日 EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }
}

// MARK: - DayCell

struct DayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let isToday: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                if isSelected {
                    Circle().fill(Theme.accent).frame(width: 26, height: 26)
                } else if isToday {
                    Circle().fill(Theme.accent.opacity(0.15)).frame(width: 26, height: 26)
                }
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 12, weight: isToday || isSelected ? .semibold : .regular))
                    .foregroundColor(
                        isSelected       ? .white :
                        isToday          ? Theme.accent :
                        isCurrentMonth   ? Theme.textPrimary : Theme.textTertiary
                    )
            }

            // Up to 3 event dots
            HStack(spacing: 2) {
                ForEach(events.prefix(3)) { ev in
                    Circle()
                        .fill(Color(hex: ev.colorHex))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .contentShape(Rectangle())
    }
}

// MARK: - EventRow

struct EventRow: View {
    let event: CalendarEvent

    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: .now, to: event.date).day ?? 0
    }

    private var daysLabel: String {
        if daysUntil < 0  { return "已过期" }
        if daysUntil == 0 { return "今天" }
        return "\(daysUntil) 天后"
    }

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(hex: event.colorHex))
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(event.date, style: .date)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Text(daysLabel)
                .font(Theme.captionFont)
                .foregroundColor(Theme.urgencyColor(daysUntil: daysUntil))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Theme.urgencyColor(daysUntil: daysUntil).opacity(0.1))
                .cornerRadius(6)
        }
        .padding(12)
        .cardStyle()
    }
}
