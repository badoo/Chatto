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

extension BaseChatViewController: ChatCollectionViewLayoutDelegate {

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.chatItemCompanionCollection.count
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

        if self.isAdjustingInputContainer {
            UIView.performWithoutAnimation({
                // See https://github.com/badoo/Chatto/issues/133
                presenter.cellWillBeShown(cell)
                cell.layoutIfNeeded()
            })
        } else {
            presenter.cellWillBeShown(cell)
        }
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

    func presenterForIndexPath(indexPath: NSIndexPath) -> ChatItemPresenterProtocol {
        return self.presenterForIndex(indexPath.item, chatItemCompanionCollection: self.chatItemCompanionCollection)
    }

    func presenterForIndex(index: Int, chatItemCompanionCollection items: ChatItemCompanionCollection) -> ChatItemPresenterProtocol {
        guard index < items.count else {
            // This can happen from didEndDisplayingCell if we reloaded with less messages
            return DummyChatItemPresenter()
        }
        return items[index].presenter
    }

    public func createPresenterForChatItem(chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        return self.presenterFactory.createChatItemPresenter(chatItem)
    }

    public func decorationAttributesForIndexPath(indexPath: NSIndexPath) -> ChatItemDecorationAttributesProtocol? {
        return self.chatItemCompanionCollection[indexPath.item].decorationAttributes
    }
}
