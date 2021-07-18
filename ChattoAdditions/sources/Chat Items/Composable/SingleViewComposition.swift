
import UIKit

public protocol SingleViewComposition: BaseViewComposition {
    func add(child: UIView, to: View)
}

public struct AnySingleViewComposition: SingleViewComposition {

    private let _add: (UIView, Any) -> Void

    public init<Base: SingleViewComposition>(_ base: Base) {
        self._add = { view, any in
            guard let to = any as? Base.View else { fatalError() }
            base.add(child: view, to: to)
        }
    }

    // MARK: - SingleViewComposition

    public typealias View = Any

    public func add(child: UIView, to: View) {
        self._add(child, to)
    }
}

