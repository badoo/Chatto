
// MARK: - Protocol

public protocol ViewModelBinding {
    associatedtype View
    associatedtype ViewModel
    func bind(view: View, to viewModel: ViewModel)
}

// MARK: - Type Erased

public final class AnyViewModelBinding {

    public enum Error: Swift.Error {
        case typeMismatch(Any.Type, Any.Type)
    }

    private let _bind: (Any, Any) throws -> Void

    public init<Base: ViewModelBinding>(_ base: Base) {
        self._bind = { anyView, anyViewModel in
            guard let view = anyView as? Base.View else {
                throw Error.typeMismatch(type(of: anyView), Base.View.self)
            }
            guard let viewModel = anyViewModel as? Base.ViewModel else {
                throw Error.typeMismatch(type(of: anyViewModel), Base.ViewModel.self)
            }
            base.bind(view: view, to: viewModel)
        }
    }

    public func bind(view: Any, to viewModel: Any) throws {
        try self._bind(view, viewModel)
    }
}

// MARK: - Block based

public struct BlockBinding<View, ViewModel>: ViewModelBinding {

    public typealias Block = (View, ViewModel) -> Void
    private let block: Block

    public init(block: @escaping Block) {
        self.block = block
    }

    public func bind(view: View, to viewModel: ViewModel) {
        self.block(view, viewModel)
    }
}

extension Binder {
    public mutating func registerBlockBinding<Key: BindingKeyProtocol>(for key: Key, block: @escaping (Key.View, Key.ViewModel) -> Void) {
        self.register(binding: BlockBinding(block: block), for: key)
    }
}

// MARK: - Noop

public struct NoopBinding<View, ViewModel>: ViewModelBinding {
    public func bind(view: View, to viewModel: ViewModel) {}
}

extension Binder {
    public mutating func registerNoopBinding<Key: BindingKeyProtocol>(for key: Key) {
        self.register(binding: NoopBinding(), for: key)
    }
}

