import SwiftUI

// MARK: - Navigation tabs

enum AppTab: String, CaseIterable, Hashable {
    case calendar   = "日历"
    case courses    = "课程"
    case activities = "活动 & 项目"

    var icon: String {
        switch self {
        case .calendar:   return "calendar"
        case .courses:    return "books.vertical"
        case .activities: return "target"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eLearning: ELearningService

    @State private var selectedTab: AppTab = .courses
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selectedTab: $selectedTab, showSettings: $showSettings)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            switch selectedTab {
            case .calendar:   CalendarView()
            case .courses:    CoursesView()
            case .activities: ActivitiesView()
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .environmentObject(eLearning)
        }
    }
}
