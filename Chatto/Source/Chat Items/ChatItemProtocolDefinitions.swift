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

public typealias ChatItemType = String

public protocol ChatItemProtocol: class, UniqueIdentificable {
    var type: ChatItemType { get }
}

public protocol ChatItemDecorationAttributesProtocol {
    var bottomMargin: CGFloat { get }
}

public protocol ChatItemPresenterProtocol: class {
    static func registerCells(collectionView: UICollectionView)
    var canCalculateHeightInBackground: Bool { get } // Default is false
    func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat
    func dequeueCell(collectionView collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell
    func configureCell(cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?)
    func cellWillBeShown(cell: UICollectionViewCell) // optional
    func cellWasHidden(cell: UICollectionViewCell) // optional
    func shouldShowMenu() -> Bool // optional. Default is false
    func canPerformMenuControllerAction(action: Selector) -> Bool // optional. Default is false
    func performMenuControllerAction(action: Selector) // optional
}

public extension ChatItemPresenterProtocol { // Optionals
    var canCalculateHeightInBackground: Bool { return false }
    func cellWillBeShown(cell: UICollectionViewCell) {}
    func cellWasHidden(cell: UICollectionViewCell) {}
    func shouldShowMenu() -> Bool { return false }
    func canPerformMenuControllerAction(action: Selector) -> Bool { return false }
    func performMenuControllerAction(action: Selector) {}
}

public protocol ChatItemPresenterBuilderProtocol {
    func canHandleChatItem(chatItem: ChatItemProtocol) -> Bool
    func createPresenterWithChatItem(chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol
    var presenterType: ChatItemPresenterProtocol.Type { get }
}
