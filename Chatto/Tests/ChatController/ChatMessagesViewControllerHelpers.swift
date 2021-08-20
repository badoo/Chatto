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
import XCTest
@testable import Chatto

extension ChatMessageCollectionAdapter.Configuration {
    static var testConfig: Self {
        return Self.default
    }
}

struct ChatMessageTestComponents {
    var adapter: ChatMessageCollectionAdapter
    var dataSource: ChatMessagesViewModelProtocol
    var itemsDecorator: ChatItemsDecoratorProtocol
    var layout: UICollectionViewLayout & ChatCollectionViewLayoutProtocol
    var presenterBuilder: ChatItemPresenterBuilderProtocol = FakePresenterBuilder()
    var viewController: ChatMessagesViewController
    var updateQueue: SerialTaskQueueProtocol


    init(
        adapterConfig: ChatMessageCollectionAdapter.Configuration = .testConfig,
        dataSource: ChatMessagesViewModelProtocol = FakeDataSource(),
        itemsDecorator: ChatItemsDecoratorProtocol = FakeChatItemsDecorator(),
        layout: (UICollectionViewLayout & ChatCollectionViewLayoutProtocol) = ChatCollectionViewLayout(),
        presenterBuilder: ChatItemPresenterBuilderProtocol = FakePresenterBuilder(),
        updateQueue: SerialTaskQueueProtocol = SerialTaskQueue()
    ) {
        self.dataSource = dataSource
        self.itemsDecorator = itemsDecorator
        self.layout = layout
        self.presenterBuilder = presenterBuilder
        self.updateQueue = updateQueue

        let presentBuilderByTypeBlock: [ChatItemType: [ChatItemPresenterBuilderProtocol]] = ["fake-type": [presenterBuilder]]
        let chatItemPresenterFactory = ChatItemPresenterFactory(
            presenterBuildersByType: presentBuilderByTypeBlock
        )
        self.adapter = ChatMessageCollectionAdapter(
            chatItemsDecorator: itemsDecorator,
            chatItemPresenterFactory: chatItemPresenterFactory,
            chatMessagesViewModel: dataSource,
            configuration: adapterConfig,
            referenceIndexPathRestoreProvider: ReferenceIndexPathRestoreProviderFactory.makeDefault(),
            updateQueue: updateQueue
        )
        self.layout.delegate = self.adapter
        self.viewController = ChatMessagesViewController(
            config: .default,
            layout: layout,
            messagesAdapter: self.adapter,
            style: .default,
            viewModel: dataSource
        )
        self.adapter.delegate = self.viewController
    }
}

func fakeDidAppearAndLayout(controller: UIViewController) {
    controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 900)
    controller.viewWillAppear(true)
    controller.viewDidAppear(true)
    controller.view.layoutIfNeeded()
}
