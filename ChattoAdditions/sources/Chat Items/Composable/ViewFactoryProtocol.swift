
import UIKit

public protocol ViewFactoryProtocol {
    associatedtype View: UIView
    func makeView() -> View
}

public struct AnyViewFactory: ViewFactoryProtocol {

    private let _makeView: () -> UIView

    public init<Base: ViewFactoryProtocol>(_ base: Base) {
        self._makeView = { base.makeView() }
    }

    public func makeView() -> UIView {
        self._makeView()
    }
}

