import Foundation
import Core

extension Window {
    struct Info: CollectionItemInfo {
        let id: String
        let size: Picture.Size
        let publisher: Camera.Pub
        
        init(picture: Core.Picture, publisher: Camera.Pub) {
            id = picture.id.absoluteString
            size = picture.size
            self.publisher = publisher
        }
        
        func hash(into: inout Hasher) {
            into.combine(id)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }
}


