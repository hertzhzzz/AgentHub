import SwiftUI

@main
struct AgentHubApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .frame(minWidth: 820, minHeight: 520)
        }
        .defaultSize(width: 1040, height: 700)
        .commands {
            CommandGroup(after: .toolbar) {
                Button(String(localized: "Reload", bundle: .module)) { model.reload() }
                    .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
