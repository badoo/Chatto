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

class ChatMessagesViewControllerTests: XCTestCase {

    func testThat_WhenViewControllerInitated_ThenViewsIsNotLoaded() {
        let chatMessageTestComponents = ChatMessageTestComponents()
        let messagesViewController = chatMessageTestComponents.viewController

        XCTAssertFalse(messagesViewController.isViewLoaded)
    }

    func testThat_GivenEmptyDataSource_ThenChatViewControllerLoadsCorrectly() {
        let chatMessageTestComponents = ChatMessageTestComponents()
        let messagesViewController = chatMessageTestComponents.viewController

        fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertNotNil(messagesViewController.view)
    }

    func testThat_GivenDataSourceWithItemsAndNoPresenters_ThenChatViewControllerLoadsCorrectly() {
        let fakeDataSource = FakeDataSource()
        let chatMessageTestComponents = ChatMessageTestComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageTestComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        fakeDidAppearAndLayout(controller: messagesViewController)

        XCTAssertNotNil(messagesViewController.view)
        XCTAssertEqual(2, messagesViewController.collectionView.numberOfItems(inSection: 0))
    }

    func testThat_PresentersAreCreated () {
        let fakeDataSource = FakeDataSource()
        let fakePresenterBuilder = FakePresenterBuilder()
        let chatMessageTestComponents = ChatMessageTestComponents(dataSource: fakeDataSource, presenterBuilder: fakePresenterBuilder)
        let messagesViewController = chatMessageTestComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)

        fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertEqual(2, fakePresenterBuilder.createdPresenters.count)
    }

    func testThat_WhenDataSourceChanges_ThenCollectionViewUpdatesAsynchronously() {
        let asyncExpectation = expectation(description: "update")

        let fakeDataSource = FakeDataSource()
        let chatMessageTestComponents = ChatMessageTestComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageTestComponents.viewController
        let updateQueue = chatMessageTestComponents.updateQueue

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        fakeDidAppearAndLayout(controller: messagesViewController)

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
        let chatMessageTestComponents = ChatMessageTestComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageTestComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertTrue(messagesViewController.collectionView.isCloseToBottom(threshold: 0.05))
    }

    func testThat_GivenManyItems_WhenScrollToTop_ThenLoadsPreviousPage() {
        let asyncExpectation = expectation(description: "update")
        let fakeDataSource = FakeDataSource()
        let chatMessageTestComponents = ChatMessageTestComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageTestComponents.viewController
        let updateQueue = chatMessageTestComponents.updateQueue

        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        fakeDidAppearAndLayout(controller: messagesViewController)
        XCTAssertTrue(messagesViewController.collectionView.isCloseToBottom(threshold: 0.05))

        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        fakeDidAppearAndLayout(controller: messagesViewController)
        let collectionView = messagesViewController.collectionView
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
        let chatMessageTestComponents = ChatMessageTestComponents(dataSource: fakeDataSource)
        let messagesViewController = chatMessageTestComponents.viewController
        let updateQueue = chatMessageTestComponents.updateQueue

        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        fakeDidAppearAndLayout(controller: messagesViewController)

        let collectionView = messagesViewController.collectionView
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
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )
        _ = chatMessageTestComponents

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
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )
        updateQueue.start()

        weak var weakChatMessageCollectionAdapter = chatMessageTestComponents.adapter
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
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource
        )

        weak var weakChatMessageCollectionAdapter = chatMessageTestComponents.adapter

        weakChatMessageCollectionAdapter = nil
        XCTAssertNil(weakChatMessageCollectionAdapter)
    }

    func testThat_GivenCoalescingIsEnabled_WhenMultipleUpdatesAreRequested_ThenUpdatesAreCoalesced() {
        let fakeDataSource = FakeDataSource()
        var adapterConfig = ChatMessageCollectionAdapter.Configuration.testConfig
        adapterConfig.coalesceUpdates = true
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageTestComponents = ChatMessageTestComponents(
            adapterConfig: adapterConfig,
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )
        fakeDidAppearAndLayout(controller: chatMessageTestComponents.viewController)
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
        let chatMessageTestComponents = ChatMessageTestComponents(
            adapterConfig: adapterConfig,
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )

        fakeDidAppearAndLayout(controller: chatMessageTestComponents.viewController)
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []
        fakeDataSource.chatItems = []

        XCTAssertEqual(3, updateQueue.tasksQueue.count)
    }

    // MARK: Same Items
    func testThat_GivenDataSourceWithNotUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithSameItems_ThenTwoPresentersAreCreated() {
        let fakeDataSource = FakeDataSource()
        let fakePresenterBuilder = FakePresenterBuilder()
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource,
            presenterBuilder: fakePresenterBuilder,
            updateQueue: updateQueue
        )
        let messagesViewController = chatMessageTestComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        fakeDidAppearAndLayout(controller: messagesViewController)
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
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource,
            presenterBuilder: fakePresenterBuilder
        )
        let messagesViewController = chatMessageTestComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)

        fakeDidAppearAndLayout(controller: messagesViewController)
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
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource,
            presenterBuilder: fakePresenterBuilder
        )
        let messagesViewController = chatMessageTestComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        fakeDidAppearAndLayout(controller: messagesViewController)
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
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource,
            presenterBuilder: fakePresenterBuilder
        )
        let messagesViewController = chatMessageTestComponents.viewController

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        fakeDidAppearAndLayout(controller: messagesViewController)
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
