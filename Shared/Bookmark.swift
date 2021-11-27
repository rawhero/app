import Foundation

struct Bookmark: Codable, Equatable, Identifiable {
    let id: String
    private let data: Data
    
    init?(url: URL) {
        guard let data = try? url.bookmarkData(options: .withSecurityScope) else { return nil }
        id = url.absoluteString
        self.data = data
    }
    
    var url: URL? {
        var stale = false
        
        guard
            let access = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &stale),
            access.startAccessingSecurityScopedResource()
        else { return nil }
            
        guard
            FileManager.default.fileExists(atPath: access.path),
            !access.pathComponents.map(\.localizedLowercase).contains(".trash")
        else {
            access.stopAccessingSecurityScopedResource()
            return nil
        }
        
        return access
    }
}
