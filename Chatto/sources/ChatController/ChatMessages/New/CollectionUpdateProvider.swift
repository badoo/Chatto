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

// TODO: Rename
public final class CollectionUpdateProvider: CollectionUpdateProviderProtocol {

    public struct Configuration {
        let isRegisteringPresentersAutomatically: Bool

        public init(isRegisteringPresentersAutomatically: Bool) {
            self.isRegisteringPresentersAutomatically = isRegisteringPresentersAutomatically
        }
    }

    // MARK: - Private properties

    private let configuration: Configuration
    private let chatItemPresenterFactory: ChatItemPresenterFactoryProtocol
    private let chatMessagesViewModel: ChatMessagesViewModelProtocol
    private let chatItemsDecorator: ChatItemsDecoratorProtocol

    // MARK: - State

    private var isFirstUpdate: Bool = true

    private weak var collectionView: UICollectionView?

    // MARK: - Instantiation

    public init(configuration: Configuration,
                chatItemsDecorator: ChatItemsDecoratorProtocol,
                chatItemPresenterFactory: ChatItemPresenterFactoryProtocol,
                chatMessagesViewModel: ChatMessagesViewModelProtocol) {
        self.configuration = configuration
        self.chatItemsDecorator = chatItemsDecorator
        self.chatItemPresenterFactory = chatItemPresenterFactory
        self.chatMessagesViewModel = chatMessagesViewModel
    }

    // MARK: - CellPresenterProviderProtocol

    public func updateCollection(old: ChatItemCompanionCollection) -> ChatItemCompanionCollection {
        let decoratedNewItems = self.chatItemsDecorator.decorateItems(self.chatMessagesViewModel.chatItems)

        // TODO: Move this logic somewhere else
        let companionItems: [ChatItemCompanion] = decoratedNewItems.map { decoratedChatItem in
            ChatItemCompanion(uid: decoratedChatItem.uid,
                         chatItem: decoratedChatItem.chatItem,
                        presenter: self.presenter(for: decoratedChatItem, from: old),
             decorationAttributes: decoratedChatItem.decorationAttributes)
        }

        return ChatItemCompanionCollection(items: companionItems)
    }

    public func setup(in collectionView: UICollectionView) {
        self.collectionView = collectionView
        if self.configuration.isRegisteringPresentersAutomatically {
            self.chatItemPresenterFactory.configure(withCollectionView: collectionView)
        }
    }

    // TODO: Subscribe for chat data source updates
    private func didUpdateDataSource() {
        guard !self.configuration.isRegisteringPresentersAutomatically
              && self.isFirstUpdate,
              let collectionView = self.collectionView else { return }
        self.chatItemPresenterFactory.configure(withCollectionView: collectionView)
        self.isFirstUpdate = false
    }

    // MARK: - Private methods

    private func presenter(for decoratedItem: DecoratedChatItem, from oldItems: ChatItemCompanionCollection) -> ChatItemPresenterProtocol {
        /*
            We use an assumption, that message having a specific messageId never changes its type.
            If such changes has to be supported, then generation of changes has to suppport reloading items.
            Otherwise, updateVisibleCells may try to update the existing cells with new presenters which aren't able to work with another types.
        */

        guard let oldChatItemCompanion = oldItems[decoratedItem.uid] ?? oldItems[decoratedItem.chatItem.uid],
            oldChatItemCompanion.chatItem.type == decoratedItem.chatItem.type,
            oldChatItemCompanion.presenter.isItemUpdateSupported else {
                return self.chatItemPresenterFactory.createChatItemPresenter(decoratedItem.chatItem)
        }

        oldChatItemCompanion.presenter.update(with: decoratedItem.chatItem)
        return oldChatItemCompanion.presenter
    }
}

