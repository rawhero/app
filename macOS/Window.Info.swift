import Foundation
import Core

extension Window {
    struct Info: CollectionItemInfo {
        let id: String
        let publisher: Camera.Pub
        let width: CGFloat
        
        init(picture: Core.Picture, publisher: Camera.Pub) {
            id = picture.id.absoluteString
            width = picture.size.width > 0 && picture.size.height > 0
                ? ceil(Cell.height / .init(picture.size.height) * .init(picture.size.width))
            : Cell.height
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


