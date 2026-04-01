import SwiftUI

// MARK: - App definition
// Note: in an SPM executableTarget, @main is not used.
// We define the App struct here and call .main() explicitly.

struct TodoFlowApp: App {

    @StateObject private var store     = AppStore()
    @StateObject private var eLearning = ELearningService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(eLearning)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    eLearning.restoreSession()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {}   // hide default "New Window"
            CommandMenu("TodoFlow") {
                Button("日历") {}
                    .keyboardShortcut("1", modifiers: .command)
                Button("课程") {}
                    .keyboardShortcut("2", modifiers: .command)
                Button("活动 & 项目") {}
                    .keyboardShortcut("3", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
                .environmentObject(eLearning)
        }
    }
}

TodoFlowApp.main()
