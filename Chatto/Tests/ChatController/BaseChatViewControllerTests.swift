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

import UIKit
import XCTest
@testable import Chatto

class ChatViewControllerTests: XCTestCase {

    func testThat_WhenChatViewControllerInitated_ThenViewsIsNotLoaded() {
        let chatMessageComponents = ChatMessageComponents()
        let messagesViewController = chatMessageComponents.viewController

        XCTAssertFalse(messagesViewController.isViewLoaded)
        XCTAssertNotNil(messagesViewController.collectionView)
    }

    func testThat_GivenNoDataSource_ThenChatViewControllerLoadsCorrectly() {
        let chatMessageComponents = ChatMessageComponents()
        let messagesViewController = chatMessageComponents.viewController

        self.fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertNotNil(messagesViewController.view)
        XCTAssertNotNil(messagesViewController.collectionView)
    }

    func testThat_GivenDataSourceWithItemsAndNoPresenters_ThenChatViewControllerLoadsCorrectly() {
        let fakeDataSource = FakeDataSource()
        let chatMessageComponents = ChatMessageComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        self.fakeDidAppearAndLayout(controller: messagesViewController)

        XCTAssertNotNil(messagesViewController.view)
        XCTAssertNotNil(messagesViewController.collectionView)
        XCTAssertEqual(2, messagesViewController.collectionView.numberOfItems(inSection: 0))
    }

    func testThat_PresentersAreCreated () {
        let fakeDataSource = FakeDataSource()
        let fakePresenterBuilder = FakePresenterBuilder()
        let chatMessageComponents = ChatMessageComponents(dataSource: fakeDataSource, presenterBuilder: fakePresenterBuilder)
        let messagesViewController = chatMessageComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)

        self.fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertEqual(2, fakePresenterBuilder.createdPresenters.count)
    }

    func testThat_WhenDataSourceChanges_ThenCollectionViewUpdatesAsynchronously() {
        let asyncExpectation = expectation(description: "update")

        let fakeDataSource = FakeDataSource()
        let chatMessageComponents = ChatMessageComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageComponents.viewController
        let updateQueue = chatMessageComponents.updateQueue

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        self.fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertNotNil(messagesViewController.collectionView)

        fakeDataSource.chatItems = createFakeChatItems(count: 3)
        updateQueue.addTask { completion in
            asyncExpectation.fulfill()
            completion()
        }

        self.waitForExpectations(timeout: 1) { (_) -> Void in
            XCTAssertEqual(3, messagesViewController.collectionView.numberOfItems(inSection: 0))
        }
    }

    func testThat_CollectionIsScrolledAtBottomAfterFirstLoad() {
        let fakeDataSource = FakeDataSource()
        let chatMessageComponents = ChatMessageComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        self.fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertTrue(messagesViewController.collectionView.isCloseToBottom(threshold: 0.05))
    }

    func testThat_GivenManyItems_WhenScrollToTop_ThenLoadsPreviousPage() {
        let asyncExpectation = expectation(description: "update")
        let fakeDataSource = FakeDataSource()
        let chatMessageComponents = ChatMessageComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageComponents.viewController
        let updateQueue = chatMessageComponents.updateQueue

        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        self.fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertTrue(messagesViewController.collectionView.isCloseToBottom(threshold: 0.05))

        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        self.fakeDidAppearAndLayout(controller: messagesViewController)
        let collectionView = messagesViewController.collectionView!
        updateQueue.addTask { completion in
            fakeDataSource.hasMorePrevious = true
            collectionView.contentOffset = CGPoint.zero
            messagesViewController.scrollViewDidScrollToTop(collectionView)
            completion()
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { _ in
            XCTAssertTrue(fakeDataSource.wasRequestedForPrevious)
        }
    }

    func testThat_WhenLoadsNextPage_ThenPreservesScrollPosition() {
        let asyncExpectation = expectation(description: "update")
        let fakeDataSource = FakeDataSource()
        let chatMessageComponents = ChatMessageComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageComponents.viewController
        let updateQueue = chatMessageComponents.updateQueue

        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        self.fakeDidAppearAndLayout(controller: messagesViewController)
        
        let collectionView = messagesViewController.collectionView!
        let contentOffset = collectionView.contentOffset
        fakeDataSource.hasMoreNext = true
        fakeDataSource.chatItemsForLoadNext = createFakeChatItems(count: 3000)
        messagesViewController.autoLoadMoreContentIfNeeded()

        updateQueue.addTask { completion in
            asyncExpectation.fulfill()
            completion()
        }

        self.waitForExpectations(timeout: 1) { _ in
            XCTAssertEqual(3000, messagesViewController.collectionView.numberOfItems(inSection: 0))
            XCTAssertEqual(contentOffset, collectionView.contentOffset)
        }
    }

    func testThat_WhenManyMessagesAreLoaded_ThenRequestForMessageCountContention() {
        let asyncExpectation = expectation(description: "update")
        let fakeDataSource = FakeDataSource()
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )
        _ = chatMessageComponents

        updateQueue.start()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        updateQueue.onAllTasksFinished = {
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { (_) -> Void in
            XCTAssertTrue(fakeDataSource.wasRequestedForMessageCountContention)
        }
    }

    func testThat_WhenUpdatesFinish_ControllerIsNotRetained() {
        let fakeDataSource = FakeDataSource()
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )
        updateQueue.start()

        weak var weakChatMessageCollectionAdapter = chatMessageComponents.adapter
        let asyncExpectation = expectation(description: "update")
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)

        updateQueue.onAllTasksFinished = {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { (_) -> Void in
            weakChatMessageCollectionAdapter = nil
            XCTAssertNil(weakChatMessageCollectionAdapter)
        }
    }

    func testThat_WhenLayoutFinishes_ControllerIsNotRetained() {
        let fakeDataSource = FakeDataSource()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource
        )

        weak var weakChatMessageCollectionAdapter = chatMessageComponents.adapter

        weakChatMessageCollectionAdapter = nil
        XCTAssertNil(weakChatMessageCollectionAdapter)
    }

    func testThat_LayoutAdaptsWhenKeyboardIsShown() {
        let fakeDataSource = FakeDataSource()
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )
        let controller = TesteableChatViewController(messagesViewController: chatMessageComponents.viewController)
        let notificationCenter = NotificationCenter()
        controller.notificationCenter = notificationCenter
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        self.fakeDidAppearAndLayout(controller: controller)
        notificationCenter.post(name: UIResponder.keyboardWillShowNotification, object: self, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        XCTAssertEqual(400, controller.view.convert(controller.chatInputView.bounds, from: controller.chatInputView).maxY)
    }

    func testThat_LayoutAdaptsWhenKeyboardIsHidden() {
        let fakeDataSource = FakeDataSource()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource
        )
        let controller = TesteableChatViewController(messagesViewController: chatMessageComponents.viewController)
        let notificationCenter = NotificationCenter()
        controller.notificationCenter = notificationCenter

        fakeDataSource.chatItems = createFakeChatItems(count: 2)

        self.fakeDidAppearAndLayout(controller: controller)
        notificationCenter.post(name: UIResponder.keyboardWillShowNotification, object: self, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        notificationCenter.post(name: UIResponder.keyboardDidShowNotification, object: self, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        notificationCenter.post(name: UIResponder.keyboardWillHideNotification, object: self, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        XCTAssertEqual(900, controller.view.convert(controller.chatInputView.bounds, from: controller.chatInputView).maxY)
    }

    func testThat_GivenCoalescingIsEnabled_WhenMultipleUpdatesAreRequested_ThenUpdatesAreCoalesced() {
        let fakeDataSource = FakeDataSource()
        var adapterConfig = ChatMessageCollectionAdapter.Configuration.testConfig
        adapterConfig.coalesceUpdates = true
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageComponents = ChatMessageComponents(
            adapterConfig: adapterConfig,
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )
        self.fakeDidAppearAndLayout(controller: chatMessageComponents.viewController)
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []

        XCTAssertEqual(1, updateQueue.tasksQueue.count)
    }

    func testThat_GivenCoalescingIsDisabled_WhenMultipleUpdatesAreRequested_ThenUpdatesAreQueued() {
        let fakeDataSource = FakeDataSource()
        var adapterConfig = ChatMessageCollectionAdapter.Configuration.testConfig
        adapterConfig.coalesceUpdates = false
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageComponents = ChatMessageComponents(
            adapterConfig: adapterConfig,
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )

        self.fakeDidAppearAndLayout(controller: chatMessageComponents.viewController)
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []

        XCTAssertEqual(3, updateQueue.tasksQueue.count)
    }

    // MARK: helpers

    fileprivate func fakeDidAppearAndLayout(controller: UIViewController) {
        controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 900)
        controller.viewWillAppear(true)
        controller.viewDidAppear(true)
        controller.view.layoutIfNeeded()
    }
}

extension ChatViewControllerTests {

    // MARK: Same Items
    func testThat_GivenDataSourceWithNotUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithSameItems_ThenTwoPresentersAreCreated() {
        let fakeDataSource = FakeDataSource()
        let fakePresenterBuilder = FakePresenterBuilder()
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource,
            presenterBuilder: fakePresenterBuilder,
            updateQueue: updateQueue
        )
        let messagesViewController = chatMessageComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        self.fakeDidAppearAndLayout(controller: messagesViewController)
        let numberOfCreatedPresentersBeforeUpdate = fakePresenterBuilder.createdPresenters.count

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        let asyncExpectation = expectation(description: "update")
        messagesViewController.refreshContent {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { _ in
            let numberOfCreatedPresentersAfterUpdate = fakePresenterBuilder.createdPresenters.count
            let numberOfCreatedPresenters = numberOfCreatedPresentersAfterUpdate - numberOfCreatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfCreatedPresenters, 2)
        }
    }

    func testThat_GivenDataSourceWithUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithSameItems_ThenTwoPresentersAreUpdated() {
        let fakeDataSource = FakeDataSource()
        let fakePresenterBuilder = FakeUpdatablePresenterBuilder()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource,
            presenterBuilder: fakePresenterBuilder
        )
        let messagesViewController = chatMessageComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)

        self.fakeDidAppearAndLayout(controller: messagesViewController)
        let numberOfUpdatedPresentersBeforeUpdate = fakePresenterBuilder.updatedPresentersCount
        let numberOfCreatedPresentersBeforeUpdate = fakePresenterBuilder.createdPresenters.count

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        let asyncExpectation = expectation(description: "update")
        messagesViewController.refreshContent {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { _ in
            let numberOfUpdatedPresentersAfterUpdate = fakePresenterBuilder.updatedPresentersCount
            let numberOfUpdatedPresenters = numberOfUpdatedPresentersAfterUpdate - numberOfUpdatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfUpdatedPresenters, 2)

            let numberOfCreatedPresentersAfterUpdate = fakePresenterBuilder.createdPresenters.count
            let numberOfCreatedPresenters = numberOfCreatedPresentersAfterUpdate - numberOfCreatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfCreatedPresenters, 0)
        }
    }

    // MARK: New Items

    func testThat_GivenDataSourceWithNotUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithOneNewItem_ThenThreePresentersAreCreated() {
        let fakeDataSource = FakeDataSource()
        let fakePresenterBuilder = FakePresenterBuilder()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource,
            presenterBuilder: fakePresenterBuilder
        )
        let messagesViewController = chatMessageComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        self.fakeDidAppearAndLayout(controller: messagesViewController)
        let numberOfCreatedPresentersBeforeUpdate = fakePresenterBuilder.createdPresenters.count

        fakeDataSource.chatItems = createFakeChatItems(count: 3)
        let asyncExpectation = expectation(description: "update")
        messagesViewController.refreshContent {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { _ in
            let numberOfCreatedPresentersAfterUpdate = fakePresenterBuilder.createdPresenters.count
            let numberOfCreatedPresenters = numberOfCreatedPresentersAfterUpdate - numberOfCreatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfCreatedPresenters, 3)
        }
    }

    func testThat_GivenDataSourceWithUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithOneNewItem_ThenTwoPresentersAreUpdated_AndOnePresenterIsCreated() {
        let fakeDataSource = FakeDataSource()
        let fakePresenterBuilder = FakeUpdatablePresenterBuilder()
        let chatMessageComponents = ChatMessageComponents(
            dataSource: fakeDataSource,
            presenterBuilder: fakePresenterBuilder
        )
        let messagesViewController = chatMessageComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        self.fakeDidAppearAndLayout(controller: messagesViewController)
        let numberOfUpdatedPresentersBeforeUpdate = fakePresenterBuilder.updatedPresentersCount
        let numberOfCreatedPresentersBeforeUpdate = fakePresenterBuilder.createdPresenters.count

        fakeDataSource.chatItems = createFakeChatItems(count: 3)
        let asyncExpectation = expectation(description: "update")
        messagesViewController.refreshContent {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { _ in
            let numberOfUpdatedPresentersAfterUpdate = fakePresenterBuilder.updatedPresentersCount
            let numberOfUpdatedPresenters = numberOfUpdatedPresentersAfterUpdate - numberOfUpdatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfUpdatedPresenters, 2)

            let numberOfCreatedPresentersAfterUpdate = fakePresenterBuilder.createdPresenters.count
            let numberOfCreatedPresenters = numberOfCreatedPresentersAfterUpdate - numberOfCreatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfCreatedPresenters, 1)
        }
    }
}

private extension ChatMessageCollectionAdapter.Configuration {
    static var testConfig: Self {
        let defaultBaseChatViewControllerConfig = BaseChatViewController.Configuration.default

        return .init(
            autoloadingFractionalThreshold: defaultBaseChatViewControllerConfig.updates.autoloadingFractionalThreshold,
            coalesceUpdates: defaultBaseChatViewControllerConfig.updates.coalesceUpdates,
            fastUpdates: defaultBaseChatViewControllerConfig.updates.fastUpdates,
            preferredMaxMessageCount: defaultBaseChatViewControllerConfig.messages.preferredMaxMessageCount,
            preferredMaxMessageCountAdjustment: defaultBaseChatViewControllerConfig.messages.preferredMaxMessageCountAdjustment,
            updatesAnimationDuration: defaultBaseChatViewControllerConfig.animation.updatesAnimationDuration
        )
    }
}

private struct ChatMessageComponents {
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
            updateQueue: updateQueue
        )
        self.layout.delegate = self.adapter
        self.viewController = ChatMessagesViewController(
            config: .default,
            layout: layout,
            messagesAdapter: self.adapter,
            presenterFactory: chatItemPresenterFactory,
            style: .default,
            viewModel: dataSource
        )
    }
}
