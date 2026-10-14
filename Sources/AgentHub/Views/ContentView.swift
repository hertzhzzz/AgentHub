import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            Group {
                if model.isMissing {
                    MissingLibraryView()
                } else {
                    ItemListView(kind: model.selection)
                }
            }
            .navigationTitle(model.selection.title)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Label(model.displayPath, systemImage: "books.vertical")
                    .labelStyle(.titleAndIcon)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .help(model.libraryURL.path)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { model.reload() } label: {
                    Label(String(localized: "Reload", bundle: .module), systemImage: "arrow.clockwise")
                }
                .help(String(localized: "Reload", bundle: .module))
            }
        }
    }
}

struct SidebarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List(ToolKind.allCases, selection: $model.selection) { kind in
            HStack {
                Label(kind.title, systemImage: kind.symbol)
                Spacer()
                Text("\(model.count(of: kind))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .tag(kind)
        }
        .listStyle(.sidebar)
    }
}

struct MissingLibraryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "No tool library yet", bundle: .module), systemImage: "books.vertical")
        } description: {
            Text("Create a library at \(model.displayPath) to see your skills, agents and more here.", bundle: .module)
        } actions: {
            Button(String(localized: "Reload", bundle: .module)) { model.reload() }
        }
    }
}
