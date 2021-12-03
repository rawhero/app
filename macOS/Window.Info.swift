import Foundation
import Core

extension Window {
    struct Info: CollectionItemInfo {
        var id: String {
            picture.id.absoluteString
        }
        
        let picture: Picture
        let thumbnail: Camera.Pub
        let hd: Camera.Pub
        
        init(picture: Core.Picture, thumbnail: Camera.Pub, hd: Camera.Pub) {
            self.picture = picture
            self.thumbnail = thumbnail
            self.hd = hd
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
