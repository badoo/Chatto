
import UIKit

public struct FactoryAggregate<ChatItem> {

    public typealias Key = AnyBindingKey

    private var viewFactories: [Key: AnyViewFactory] = [:]
    private var viewModelFactories: [Key: AnyViewModelFactory<ChatItem>] = [:]
    private var layoutProviderFactories: [Key: AnyLayoutProviderFactory] = [:]

    public init() {}

    public mutating func register<ViewFactory, ViewModelFactory, LayoutProviderFactory>(
        viewFactory: ViewFactory,
        viewModelFactory: ViewModelFactory,
        layoutProviderFactory: LayoutProviderFactory
    ) -> BindingKey<ViewFactory.View, ViewModelFactory.ViewModel, LayoutProviderFactory.LayoutProvider>
        where ViewFactory: ViewFactoryProtocol,
        ViewModelFactory: ViewModelFactoryProtocol,
        ViewModelFactory.ChatItem == ChatItem,
        LayoutProviderFactory: LayoutProviderFactoryProtocol,
        LayoutProviderFactory.ViewModel == ViewModelFactory.ViewModel {
        let key = BindingKey<ViewFactory.View, ViewModelFactory.ViewModel, LayoutProviderFactory.LayoutProvider>()
        let erasedKey = AnyBindingKey(key)
        self.viewFactories[erasedKey] = AnyViewFactory(viewFactory)
        self.viewModelFactories[erasedKey] = AnyViewModelFactory(viewModelFactory)
        self.layoutProviderFactories[erasedKey] = AnyLayoutProviderFactory(layoutProviderFactory)
        return key
    }

    func makeViews() -> [AnyBindingKey: UIView] {
        var subviews: [Key: UIView] = [:]
        for (key, factory) in self.viewFactories {
            let view = factory.makeView()
            subviews[key] = view
        }
        return subviews
    }

    public func makeViewModels(for item: ChatItem) -> [AnyBindingKey: Any] {
        var viewModels: [Key: Any] = [:]
        for (key, factory) in self.viewModelFactories {
            let viewModel = factory.makeViewModel(for: item)
            viewModels[key] = viewModel
        }
        return viewModels
    }

    public func makeLayoutProviders(for viewModels: [Key: Any]) -> [Key: Any] {
        var result: [Key: Any] = [:]

        for (key, viewModel) in viewModels {
            // TODO: Fix force unwrap #744
            let factory = self.layoutProviderFactories[key]!
            let layoutProvider = factory.makeLayoutProvider(for: viewModel)
            result[key] = layoutProvider
        }

        return result
    }
}
