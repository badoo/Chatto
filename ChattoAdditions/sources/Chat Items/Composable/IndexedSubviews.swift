
import UIKit

public struct IndexedSubviews<Key: Hashable> {
    let rootKey: Key
    let subviews: [Key: UIView]

    var root: UIView { self.subviews[self.rootKey]! }
}

public typealias AnyIndexedSubviews = IndexedSubviews<AnyBindingKey>

