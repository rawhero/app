import Foundation
import Core

extension Window {
    struct Info: CollectionItemInfo {
        var id: String {
            picture.id.absoluteString
        }
        
        let picture: Picture
        let publisher: Camera.Pub
        
        init(picture: Core.Picture, publisher: Camera.Pub) {
            self.picture = picture
            self.publisher = publisher
        }
        
        func height(for width: CGFloat) -> CGFloat {
            picture.size.width > 0 && picture.size.height > 0
            ? width / .init(picture.size.width) * .init(picture.size.height)
            : width
        }
        
        func hash(into: inout Hasher) {
            into.combine(picture.id.absoluteString)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.picture.id.absoluteString == rhs.picture.id.absoluteString
        }
    }
}