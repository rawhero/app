import Foundation
import Core

extension Window {
    struct Info: CollectionItemInfo {
        let id: String
        let publisher: Camera.Pub
        let width: CGFloat
        
        init(picture: Core.Picture, publisher: Camera.Pub) {
            id = picture.id.absoluteString
            width = (Cell.height_margin / .init(picture.size.height) * .init(picture.size.width)) + Cell.margin2
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


