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
import UIKit
import Chatto

public class TimeSeparatorPresenterBuilder: ChatItemPresenterBuilderProtocol {

    public func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem is TimeSeparatorModel
    }

    public func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(self.canHandleChatItem(chatItem))
        return TimeSeparatorPresenter(timeSeparatorModel: chatItem as! TimeSeparatorModel)
    }

    public var presenterType: ChatItemPresenterProtocol.Type {
        return TimeSeparatorPresenter.self
    }
}

class TimeSeparatorPresenter: ChatItemPresenterProtocol {

    let timeSeparatorModel: TimeSeparatorModel
    init (timeSeparatorModel: TimeSeparatorModel) {
        self.timeSeparatorModel = timeSeparatorModel
    }

    private static let cellReuseIdentifier = TimeSeparatorCollectionViewCell.self.description()

    static func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(TimeSeparatorCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }

    let isItemUpdateSupported = false

    func update(with chatItem: ChatItemProtocol) {}

    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: TimeSeparatorPresenter.cellReuseIdentifier, for: indexPath)
    }

    func configureCell(_ cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        guard let timeSeparatorCell = cell as? TimeSeparatorCollectionViewCell else {
            assert(false, "expecting status cell")
            return
        }

        timeSeparatorCell.text = self.timeSeparatorModel.date
    }

    var canCalculateHeightInBackground: Bool {
        return true
    }

    func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 24
    }
}
