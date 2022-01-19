
public protocol ViewModelFactoryProtocol {
    associatedtype ChatItem
    associatedtype ViewModel
    func makeViewModel(for item: ChatItem) -> ViewModel
}

public struct AnyViewModelFactory<ChatItem>: ViewModelFactoryProtocol {

    private let _makeViewModel: (ChatItem) -> Any

    public init<Base: ViewModelFactoryProtocol>(_ base: Base) where Base.ChatItem == ChatItem {
        self._makeViewModel = { item in
            base.makeViewModel(for: item)
        }
    }

    public func makeViewModel(for item: ChatItem) -> Any {
        self._makeViewModel(item)
    }
}

public struct VoidViewModelFactory<ChatItem>: ViewModelFactoryProtocol {
    public init() {}
    public func makeViewModel(for item: ChatItem) {}
}

