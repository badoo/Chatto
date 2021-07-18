
public protocol ChatItemContentView: AnyObject {
    associatedtype ViewModel
    func subscribe(for viewModel: ViewModel)
}

// MARK: - Automatic binding

private struct ChatItemContentViewModelBinding<View: ChatItemContentView>: ViewModelBinding {
    func bind(view: View, to viewModel: View.ViewModel) {
        view.subscribe(for: viewModel)
    }
}

public extension Binder {
    mutating func registerBinding<Key: BindingKeyProtocol>(for key: Key) where Key.View: ChatItemContentView, Key.ViewModel == Key.View.ViewModel {
        self.register(binding: ChatItemContentViewModelBinding(), for: key)
    }
}


