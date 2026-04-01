import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: AppTab
    @Binding var showSettings: Bool
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eLearning: ELearningService

    var body: some View {
        VStack(spacing: 0) {

            // ── App logo ──────────────────────────────────────
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.accent)
                        .frame(width: 30, height: 30)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text("TodoFlow")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().padding(.horizontal, 10)

            // ── Navigation ────────────────────────────────────
            VStack(spacing: 2) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    SidebarItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        badge: tab == .courses ? store.upcomingCount : 0
                    )
                    .onTapGesture { selectedTab = tab }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            Divider().padding(.horizontal, 10)

            // ── Upcoming deadlines preview ────────────────────
            let upcoming = upcomingItems
            if !upcoming.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("即将到期")
                        .sectionHeader()
                        .padding(.horizontal, 10)
                        .padding(.top, 10)

                    ForEach(upcoming.prefix(5)) { event in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: event.colorHex))
                                .frame(width: 6, height: 6)
                            Text(event.title)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text(event.date, style: .relative)
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textTertiary)
                        }
                        .padding(.horizontal, 14)
                    }
                }
                .padding(.bottom, 8)
            }

            // ── eLearning new-items badge ─────────────────────
            let newCount = eLearning.resources.filter(\.isNew).count
            if newCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "link.badge.plus")
                        .foregroundColor(Theme.accent)
                        .font(.system(size: 12))
                    Text("\(newCount) 个 eLearning 新内容")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.accentLight)
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }

            Spacer()

            Divider().padding(.horizontal, 10)

            // ── Settings button ───────────────────────────────
            Button { showSettings = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                    Text("设置")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    if eLearning.isLoggedIn {
                        Circle().fill(Theme.success).frame(width: 7, height: 7)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
        }
        .background(Theme.sidebarBg)
    }

    private var upcomingItems: [CalendarEvent] {
        let horizon = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return store.calendarEvents.filter { $0.date >= Date() && $0.date <= horizon }
    }
}

// MARK: - Sidebar Item

struct SidebarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let badge: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: tab.icon)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
                .frame(width: 18)

            Text(tab.rawValue)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)

            Spacer()

            if badge > 0 {
                Text("\(min(badge, 99))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Theme.danger)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isSelected ? Theme.accent.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}
