import Foundation

protocol CollectionItemInfo: Hashable {
    associatedtype ID : Hashable
    
    var id: ID { get }
}
