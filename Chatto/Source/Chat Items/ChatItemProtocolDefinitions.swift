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

public protocol ChatItemProtocol: AnyObject, UniqueIdentificable {
    var type: ChatItemType { get }
}

public protocol ChatItemDecorationAttributesProtocol {
    var bottomMargin: CGFloat { get }
}

public protocol ChatItemMenuPresenterProtocol {
    func shouldShowMenu() -> Bool
    func canPerformMenuControllerAction(_ action: Selector) -> Bool
    func performMenuControllerAction(_ action: Selector)
}

public protocol ChatItemPresenterProtocol: AnyObject, ChatItemMenuPresenterProtocol {
    static func registerCells(_ collectionView: UICollectionView)

    var isItemUpdateSupported: Bool { get }
    func update(with chatItem: ChatItemProtocol)

    var canCalculateHeightInBackground: Bool { get } // Default is false
    func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat
    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell
    func configureCell(_ cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?)
    func cellWillBeShown(_ cell: UICollectionViewCell) // optional
    func cellWasHidden(_ cell: UICollectionViewCell) // optional
}

public extension ChatItemPresenterProtocol { // Optionals
    var canCalculateHeightInBackground: Bool { return false }
    func cellWillBeShown(_ cell: UICollectionViewCell) {}
    func cellWasHidden(_ cell: UICollectionViewCell) {}
    func shouldShowMenu() -> Bool { return false }
    func canPerformMenuControllerAction(_ action: Selector) -> Bool { return false }
    func performMenuControllerAction(_ action: Selector) {}
}

public protocol ChatItemPresenterBuilderProtocol {
    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool
    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol
    var presenterType: ChatItemPresenterProtocol.Type { get }
}

// MARK: - Updatable Chat Items

public protocol ContentEquatableChatItemProtocol: ChatItemProtocol {
    func hasSameContent(as anotherItem: ChatItemProtocol) -> Bool
}
