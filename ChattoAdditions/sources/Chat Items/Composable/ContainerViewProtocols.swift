
import UIKit

// MARK: - Single

public protocol SingleContainerViewProtocol {
    func addChild(view: UIView)
}

public struct DefaultSingleViewComposition<View: SingleContainerViewProtocol>: SingleViewComposition {
    init() {}
    public func add(child: UIView, to parent: View) {
        parent.addChild(view: child)
    }
}

extension ViewAssembler {
    public mutating func register<Key: BindingKeyProtocol>(child: AnyBindingKey, parent: Key)
        where Key.View: SingleContainerViewProtocol {
        self.register(viewComposition: DefaultSingleViewComposition(), key: child, to: parent)
    }

    public mutating func register<Child: BindingKeyProtocol, Parent: BindingKeyProtocol>(child: Child, parent: Parent)
        where Parent.View: SingleContainerViewProtocol {
        self.register(child: .init(child), parent: parent)
    }
}

// MARK: - Multiple

public protocol MultipleContainerViewProtocol {
    func addChildren(children: [UIView])
}

public struct DefaultMultipleViewComposition<View: MultipleContainerViewProtocol>: MultipleViewComposition {
    init() {}
    public func add(children: [UIView], to parent: View) {
        parent.addChildren(children: children)
    }
}

extension ViewAssembler {
    public mutating func register<Key: BindingKeyProtocol>(children: [AnyBindingKey], parent: Key)
        where Key.View: MultipleContainerViewProtocol {
        self.register(viewComposition: DefaultMultipleViewComposition(), keys: children, to: parent)
    }
}

