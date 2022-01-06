//
// Copyright (c) Bumble, 2021-present. All rights reserved.
//

import CoreGraphics

final class ChatCollectionItemsDiffer {

    struct Diff {
        let changes: CollectionChanges
        let itemCompanionCollection: ChatItemCompanionCollection
        let layoutModel: ChatCollectionViewLayoutModel
    }

    private let chatItemsDecorator: ChatItemsDecoratorProtocol
    private let chatItemPresenterFactory: ChatItemPresenterFactoryProtocol
    private let chatCollectionViewLayoutModelFactory: ChatCollectionViewLayoutModelFactoryProtocol

    init(
        chatItemsDecorator: ChatItemsDecoratorProtocol,
        chatItemPresenterFactory: ChatItemPresenterFactoryProtocol,
        chatCollectionViewLayoutModelFactory: ChatCollectionViewLayoutModelFactoryProtocol
    ) {
        self.chatItemsDecorator = chatItemsDecorator
        self.chatItemPresenterFactory = chatItemPresenterFactory
        self.chatCollectionViewLayoutModelFactory = chatCollectionViewLayoutModelFactory
    }

    func calculateChanges(
        newItems: [ChatItemProtocol],
        oldItems: ChatItemCompanionCollection,
        collectionViewWidth: CGFloat
    ) -> Diff {

        let newDecoratedItems = self.chatItemsDecorator.decorateItems(newItems)
        let changes = generateChanges(
            oldCollection: oldItems.map(HashableItem.init),
            newCollection: newDecoratedItems.map(HashableItem.init)
        )
        let itemCompanionCollection = self.createCompanionCollection(fromChatItems: newDecoratedItems, previousCompanionCollection: oldItems)
        let layoutModel = self.chatCollectionViewLayoutModelFactory.createLayoutModel(itemCompanionCollection, collectionViewWidth: collectionViewWidth)

        return Diff(
            changes: changes,
            itemCompanionCollection: itemCompanionCollection,
            layoutModel: layoutModel
        )
    }

    private func createCompanionCollection(fromChatItems newItems: [DecoratedChatItem], previousCompanionCollection oldItems: ChatItemCompanionCollection) -> ChatItemCompanionCollection {
        return ChatItemCompanionCollection(items: newItems.map { (decoratedChatItem) -> ChatItemCompanion in

            /*
             We use an assumption, that message having a specific messageId never changes its type.
             If such changes has to be supported, then generation of changes has to suppport reloading items.
             Otherwise, updateVisibleCells may try to update the existing cells with new presenters which aren't able to work with another types.
             */

            let presenter: ChatItemPresenterProtocol = {
                guard let oldChatItemCompanion = oldItems[decoratedChatItem.uid] ?? oldItems[decoratedChatItem.chatItem.uid],
                    oldChatItemCompanion.chatItem.type == decoratedChatItem.chatItem.type,
                    oldChatItemCompanion.presenter.isItemUpdateSupported else {
                        return self.chatItemPresenterFactory.createChatItemPresenter(decoratedChatItem.chatItem)
                }

                oldChatItemCompanion.presenter.update(with: decoratedChatItem.chatItem)
                return oldChatItemCompanion.presenter
            }()

            return ChatItemCompanion(uid: decoratedChatItem.uid, chatItem: decoratedChatItem.chatItem, presenter: presenter, decorationAttributes: decoratedChatItem.decorationAttributes)
        })
    }
}

private struct HashableItem: Hashable {
    private let uid: String
    private let type: String

    init(_ decoratedChatItem: DecoratedChatItem) {
        self.uid = decoratedChatItem.uid
        self.type = decoratedChatItem.chatItem.type
    }

    init(_ chatItemCompanion: ChatItemCompanion) {
        self.uid = chatItemCompanion.uid
        self.type = chatItemCompanion.chatItem.type
    }
}
