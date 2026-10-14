import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var library: Library?
    var isMissing = false
    var selection: ToolKind = .skills
    var libraryURL: URL

    init(libraryURL: URL = LibraryLoader.defaultURL) {
        self.libraryURL = libraryURL
        reload()
    }

    func reload() {
        do {
            library = try Library.load(from: libraryURL)
            isMissing = false
        } catch {
            library = nil
            isMissing = true
        }
    }

    var displayPath: String {
        (libraryURL.path as NSString).abbreviatingWithTildeInPath
    }

    func count(of kind: ToolKind) -> Int { library?.count(of: kind) ?? 0 }
}
