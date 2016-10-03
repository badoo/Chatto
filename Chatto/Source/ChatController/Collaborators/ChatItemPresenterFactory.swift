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

public protocol ChatItemPresenterFactoryProtocol {
    func createChatItemPresenter(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol
    func configure(withCollectionView collectionView: UICollectionView)
}

final class ChatItemPresenterFactory: ChatItemPresenterFactoryProtocol {
    var presenterBuildersByType = [ChatItemType: [ChatItemPresenterBuilderProtocol]]()

    init(presenterBuildersByType: [ChatItemType: [ChatItemPresenterBuilderProtocol]]) {
        self.presenterBuildersByType = presenterBuildersByType
    }

    func createChatItemPresenter(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        for builder in self.presenterBuildersByType[chatItem.type] ?? [] {
            if builder.canHandleChatItem(chatItem) {
                return builder.createPresenterWithChatItem(chatItem)
            }
        }
        return DummyChatItemPresenter()
    }

    func configure(withCollectionView collectionView: UICollectionView) {
        for presenterBuilder in self.presenterBuildersByType.flatMap({ $0.1 }) {
            presenterBuilder.presenterType.registerCells(collectionView)
        }
        DummyChatItemPresenter.registerCells(collectionView)
    }
}
