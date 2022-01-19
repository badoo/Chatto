
import UIKit

public protocol MultipleViewComposition: BaseViewComposition {
    func add(children: [UIView], to: View)
}

public struct AnyMultipleViewComposition: MultipleViewComposition {

    private let _add: ([UIView], Any) -> Void

    public init<Base: MultipleViewComposition>(_ base: Base) {
        self._add = { views, any in
            guard let to = any as? Base.View else { fatalError() }
            base.add(children: views, to: to)
        }
    }

    // MARK: - MultipleViewComposition

    public typealias View = Any

    public func add(children: [UIView], to: View) {
        self._add(children, to)
    }
}

