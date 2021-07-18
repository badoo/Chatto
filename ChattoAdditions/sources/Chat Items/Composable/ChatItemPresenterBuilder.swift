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

import Chatto
import ChattoAdditions

public final class ChatItemPresenterBuilder<ChatItem>: ChatItemPresenterBuilderProtocol, ChatItemPresenterBuilderCollectionViewConfigurable {

    private let binder: Binder
    private let assembler: ViewAssembler
    private let layoutAssembler: LayoutAssembler
    private let factory: FactoryAggregate<ChatItem>
    private let reuseIdentifier: String

    public init(binder: Binder,
                assembler: ViewAssembler,
                layoutAssembler: LayoutAssembler,
                factory: FactoryAggregate<ChatItem>) {
        self.binder = binder
        self.assembler = assembler
        self.factory = factory
        self.layoutAssembler = layoutAssembler
        self.reuseIdentifier = assembler.reuseIdentifier
    }

    // TODO: Implement me #744
    public func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        guard let item = chatItem as? ChatItem else { return false }
        //return self.binder.canHandle(item: item)
        return true
    }

    public func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        guard let item = chatItem as? ChatItem else { fatalError() }
        return ChatItemPresenter(
            chatItem: item, 
            binder: self.binder,
            assembler: self.assembler,
            layoutAssembler: self.layoutAssembler,
            factory: self.factory,
            reuseIdentifier: self.reuseIdentifier
        )
    }

    public let presenterType: ChatItemPresenterProtocol.Type = ChatItemPresenter<ChatItemType>.self

    // MARK: - ChatItemPresenterBuilderCollectionViewConfigurable

    public func configure(with collectionView: UICollectionView) {
        ChatItemPresenter<ChatItemType>.registerCells(for: collectionView, with: self.reuseIdentifier)
    }

}
