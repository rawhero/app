import Foundation

enum Defaults: String {
    case
    _bookmarks,
    _current
    
    static var bookmarks: [Bookmark] {
        guard
            let data = self[._bookmarks] as? Data,
            let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data)
        else { return [] }
        return bookmarks
    }
    
    static var current: Bookmark? {
        get {
            guard
                let data = self[._current] as? Data,
                let current = try? JSONDecoder().decode(Bookmark.self, from: data)
            else { return nil }
            return current
        }
        set {
            guard
                let bookmark = newValue,
                let data = try? JSONEncoder().encode(bookmark)
            else { return }
            self[._current] = data
        }
    }
    
    static func add(bookmark: Bookmark) {
        var bookmarks = bookmarks
            .filter {
                $0.id != bookmark.id
            }
        bookmarks.insert(bookmark, at: 0)
        guard let data = try? JSONEncoder().encode([bookmark]) else { return }
        self[._bookmarks] = data
    }
    
    static func clear(bookmark: Bookmark) {
        guard
            let current = current,
            current.id == bookmark.id
        else { return }
        self[._current] = nil
    }
    
    private static subscript(_ key: Self) -> Any? {
        get { UserDefaults.standard.object(forKey: key.rawValue) }
        set { UserDefaults.standard.setValue(newValue, forKey: key.rawValue) }
    }
}
