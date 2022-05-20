//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Chatto
import ChattoAdditions

public final class ChatItemPresenter<ChatItem>: ChatItemPresenterProtocol {

    private typealias Key = AnyBindingKey
    private typealias ViewModels = [Key: Any]
    private typealias LayoutProviders = [Key: Any]
    private typealias Cell = ChatItemCell

    private let chatItem: ChatItem
    private let binder: Binder
    private let assembler: ViewAssembler
    private let layoutAssembler: LayoutAssembler
    private let factory: FactoryAggregate<ChatItem>
    private let reuseIdentifier: String

    private var viewModels: ViewModels?
    private var rootViewSizeProvider: AnySizeProvider?
    private var layoutProviders: LayoutProviders?
    private var lifecycleObservers: [ChatItemLifecycleViewModel] = []

    public init(chatItem: ChatItem,
                binder: Binder,
                assembler: ViewAssembler,
                layoutAssembler: LayoutAssembler,
                factory: FactoryAggregate<ChatItem>,
                reuseIdentifier: String) {
        self.chatItem = chatItem
        self.binder = binder
        self.assembler = assembler
        self.layoutAssembler = layoutAssembler
        self.factory = factory
        self.reuseIdentifier = reuseIdentifier
    }

    public static func registerCells(_ collectionView: UICollectionView) {
        fatalError("This method should not be called")
    }

    public static func registerCells(for collectionView: UICollectionView, with reuseID: String) {
        collectionView.register(Cell.self, forCellWithReuseIdentifier: reuseID)
    }

    public let isItemUpdateSupported: Bool = true

    // TODO: Implement support for updating #742
    public func update(with chatItem: ChatItemProtocol) {}

    public func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        let context = LayoutContext(maxWidth: width)
        let provider = self.makeRootViewSizeProvider()
        do {
            return try provider.height(for: context)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
    }

    public func configureCell(_ cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        guard let cell = cell as? Cell else { fatalError() }
        do {
            let subviews = try self.setupSubviews(of: cell)
            let viewModels = self.makeViewModels()
            self.lifecycleObservers = viewModels.values.compactMap { $0 as? ChatItemLifecycleViewModel }
            try self.binder.bind(subviews: subviews, viewModels: viewModels)
            let layoutProviders = self.makeLayoutProviders()
            let rootContext = LayoutContext(maxWidth: cell.bounds.width)
            try self.layoutAssembler.applyLayout(with: rootContext, views: subviews.subviews, layoutProviders: layoutProviders)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public func cellWillBeShown(_ cell: UICollectionViewCell) {
        for observer in self.lifecycleObservers {
            observer.willShow()
        }
    }

    // TODO: Unify viewModels instantiation. We need to create everything at once #743
    private func makeViewModels() -> [Key: Any] {
        if let viewModels = self.viewModels {
            return viewModels
        }

        let viewModels = self.factory.makeViewModels(for: self.chatItem)
        self.viewModels = viewModels
        return viewModels
    }

    private func makeLayoutProviders() -> LayoutProviders {
        if let providers = self.layoutProviders {
            return providers
        }
        let viewModels = self.makeViewModels()
        let layoutProviders = self.factory.makeLayoutProviders(for: viewModels)
        self.layoutProviders = layoutProviders
        return layoutProviders
    }

    private func makeRootViewSizeProvider() -> AnySizeProvider {
        if let provider = self.rootViewSizeProvider {
            return provider
        }

        do {
            let viewModels = self.makeViewModels()
            let providers = self.factory.makeLayoutProviders(for: viewModels)
            let rootViewSizeProvider = try self.layoutAssembler.assembleRootSizeProvider(layoutProviders: providers)
            self.rootViewSizeProvider = rootViewSizeProvider
            return rootViewSizeProvider
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func setupSubviews(of cell: Cell) throws -> AnyIndexedSubviews {
        if let indexed = cell.indexed {
            return indexed
        }

        let subviews = self.factory.makeViews()
        let indexed = try self.assembler.assemble(subviews: subviews)
        cell.indexed = indexed
        return indexed
    }
}

private extension LayoutProviderProtocol where Layout: SizeContainer {
    func height(for context: LayoutContext) throws -> CGFloat {
        let layout = try self.layout(for: context)
        return layout.size.height
    }
}
