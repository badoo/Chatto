
// MARK: - Protocols

public protocol BinderProtocol {
    typealias Key = AnyBindingKey
    typealias Subviews = IndexedSubviews<Key>
    typealias ViewModels = [Key: Any]

    func bind(subviews: Subviews, viewModels: ViewModels) throws
}

public protocol BinderRegistryProtocol {
    mutating func register<Binding: ViewModelBinding, Key: BindingKeyProtocol>(
        binding: Binding,
        for key: Key
    ) where Binding.View == Key.View, Binding.ViewModel == Key.ViewModel
}

// MARK: - Implementation

public struct Binder: BinderProtocol, BinderRegistryProtocol {

    // MARK: - Type declarations

    public enum Error: Swift.Error {
        case keysMismatch
        case noView(key: String)
        case noViewModel(key: String)
    }

    // MARK: - Private properties

    private var bindings: [AnyBindingKey: AnyViewModelBinding] = [:]

    // MARK: - Instantiation

    public init() {}

    // MARK: - BinderRegistryProtocol

    public mutating func register<Binding: ViewModelBinding, Key: BindingKeyProtocol>(binding: Binding, for key: Key)
        where Binding.View == Key.View, Binding.ViewModel == Key.ViewModel {
        self.bindings[.init(key)] = AnyViewModelBinding(binding)
    }

    // MARK: - BinderProtocol

    public func bind(subviews: Subviews, viewModels: ViewModels) throws {
        try self.checkKeys(subviews: subviews, viewModels: viewModels)

        for (key, binding) in self.bindings {
            guard let view = subviews.subviews[key] else {
                throw Error.noView(key: key.description)
            }
            guard let viewModel = viewModels[key] else {
                throw Error.noViewModel(key: key.description)
            }
            try binding.bind(view: view, to: viewModel)
        }
    }

    // MARK: - Private

    private func checkKeys(subviews: Subviews, viewModels: ViewModels) throws {
        let bindingKeys = Set(bindings.keys)
        let subviewsKeys = Set(subviews.subviews.keys)
        let viewModelsKeys = Set(viewModels.keys)
        guard bindingKeys == subviewsKeys && subviewsKeys == viewModelsKeys else {
            throw Error.keysMismatch
        }
    }
}

