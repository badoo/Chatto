/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import Foundation

extension ChatViewController: ChatCollectionViewLayoutDelegate {

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.decoratedChatItems.count
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let presenter = self.presenterForIndexPath(indexPath)
        let cell = presenter.dequeueCell(collectionView: collectionView, indexPath: indexPath)
        let decorationAttributes = self.decorationAttributesForIndexPath(indexPath)
        presenter.configureCell(cell, decorationAttributes: decorationAttributes)
        return cell
    }

    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        // Carefull: this index path can refer to old data source after an update. Don't use it to grab items from the model
        // Instead let's use a mapping presenter <--> cell
        if let oldPresenterForCell = self.presentersByCell.objectForKey(cell) as? ChatItemPresenterProtocol {
            self.presentersByCell.removeObjectForKey(cell)
            oldPresenterForCell.cellWasHidden(cell)
        }
    }

    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        // Here indexPath should always referer to updated data source.
        let presenter = self.presenterForIndexPath(indexPath)
        self.presentersByCell.setObject(presenter, forKey: cell)
        presenter.cellWillBeShown(cell)
    }

    public func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.presenterForIndexPath(indexPath).shouldShowMenu() ?? false
    }

    public func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return self.presenterForIndexPath(indexPath).canPerformMenuControllerAction(action) ?? false
    }

    public func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        self.presenterForIndexPath(indexPath).performMenuControllerAction(action)
    }

    public func presenterForIndexPath(indexPath: NSIndexPath) -> ChatItemPresenterProtocol {
        return self.presenterForIndex(indexPath.item, decoratedChatItems: self.decoratedChatItems)
    }

    public func presenterForIndex(index: Int, decoratedChatItems: [DecoratedChatItem]) -> ChatItemPresenterProtocol {
        guard index < decoratedChatItems.count else {
            // This can happen from didEndDisplayingCell if we reloaded with less messages
            return DummyChatItemPresenter()
        }

        let chatItem = decoratedChatItems[index].chatItem
        if let presenter = self.presentersByChatItem.objectForKey(chatItem) as? ChatItemPresenterProtocol {
            return presenter
        }
        let presenter = self.createPresenterForChatItem(chatItem)
        self.presentersByChatItem.setObject(presenter, forKey: chatItem)
        return presenter
    }

    public func createPresenterForChatItem(chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        for builder in self.presenterBuildersByType[chatItem.type] ?? [] {
            if builder.canHandleChatItem(chatItem) {
                return builder.createPresenterWithChatItem(chatItem)
            }
        }
        return DummyChatItemPresenter()
    }

    public func decorationAttributesForIndexPath(indexPath: NSIndexPath) -> ChatItemDecorationAttributesProtocol? {
        return self.decoratedChatItems[indexPath.item].decorationAttributes
    }
}
