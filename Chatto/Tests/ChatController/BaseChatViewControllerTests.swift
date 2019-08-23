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

import XCTest
@testable import Chatto

class ChatViewControllerTests: XCTestCase {

    func testThat_WhenChatViewControllerInitated_ThenViewsIsNotLoaded() {
        let controller = TesteableChatViewController()
        XCTAssertFalse(controller.isViewLoaded)
        XCTAssertNil(controller.collectionView)
    }

    func testThat_GivenNoDataSource_ThenChatViewControllerLoadsCorrectly() {
        let controller = TesteableChatViewController()
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertNotNil(controller.view)
        XCTAssertNotNil(controller.collectionView)
    }

    func testThat_GivenEmptyDataSource_ThenChatViewControllerLoadsCorrectly() {
        let controller = TesteableChatViewController()
        controller.chatDataSource = FakeDataSource()
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertNotNil(controller.view)
        XCTAssertNotNil(controller.collectionView)
    }

    func testThat_GivenDataSourceWithItemsAndNoPresenters_ThenChatViewControllerLoadsCorrectly() {
        let controller = TesteableChatViewController()
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertNotNil(controller.view)
        XCTAssertNotNil(controller.collectionView)
        let collectionView = controller.collectionView!
        XCTAssertEqual(2, controller.collectionView(collectionView, numberOfItemsInSection: 0))
    }

    func testThat_PresentersAreCreated () {
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertEqual(2, presenterBuilder.createdPresenters.count)
    }

    func testThat_WhenDataSourceChanges_ThenCollectionViewUpdatesAsynchronously() {
        let asyncExpectation = expectation(description: "update")
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertNotNil(controller.collectionView)
        let collectionView = controller.collectionView!
        fakeDataSource.chatItems = createFakeChatItems(count: 3)
        fakeDataSource.delegate?.chatDataSourceDidUpdate(fakeDataSource)
        controller.updateQueue.addTask { (completion) -> Void in
            asyncExpectation.fulfill()
            completion()
        }
        self.waitForExpectations(timeout: 1) { (_) -> Void in
            XCTAssertEqual(3, controller.collectionView(collectionView, numberOfItemsInSection: 0))
        }
    }

    func testThat_CollectionIsScrolledAtBottomAfterFirstLoad() {
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        fakeDataSource.delegate?.chatDataSourceDidUpdate(fakeDataSource)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertTrue(controller.isCloseToBottom())
    }

    func testThat_GivenManyItems_WhenScrollToTop_ThenLoadsPreviousPage() {
        let asyncExpectation = expectation(description: "update")
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        let collectionView = controller.collectionView!
        controller.updateQueue.addTask { (completion) -> Void in
            fakeDataSource.hasMorePrevious = true
            collectionView.contentOffset = CGPoint.zero
            controller.scrollViewDidScrollToTop(collectionView)
            completion()
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { (_) -> Void in
            XCTAssertTrue(fakeDataSource.wasRequestedForPrevious)
        }
    }

    func testThat_WhenLoadsNextPage_ThenPreservesScrollPosition() {
        let asyncExpectation = expectation(description: "update")
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        let collectionView = controller.collectionView!
        let contentOffset = collectionView.contentOffset
        fakeDataSource.hasMoreNext = true
        fakeDataSource.chatItemsForLoadNext = createFakeChatItems(count: 3000)
        controller.autoLoadingEnabled = true // It will be false until first update finishes, let's fake it
        controller.autoLoadMoreContentIfNeeded()

        controller.updateQueue.addTask { (completion) -> Void in
            asyncExpectation.fulfill()
            completion()
        }

        self.waitForExpectations(timeout: 1) { (_) -> Void in
            XCTAssertEqual(3000, controller.collectionView(collectionView, numberOfItemsInSection: 0))
            XCTAssertEqual(contentOffset, collectionView.contentOffset)
        }
    }

    func testThat_WhenManyMessagesAreLoaded_ThenRequestForMessageCountContention() {
        let asyncExpectation = expectation(description: "update")
        let updateQueue = SerialTaskQueueTestHelper()
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        controller.updateQueue = updateQueue
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        updateQueue.onAllTasksFinished = {
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { (_) -> Void in
            XCTAssertTrue(fakeDataSource.wasRequestedForMessageCountContention)
        }
    }

    func testThat_WhenUpdatesFinish_ControllerIsNotRetained() {
        let asyncExpectation = expectation(description: "update")
        let updateQueue = SerialTaskQueueTestHelper()
        var controller: TesteableChatViewController! = TesteableChatViewController(presenterBuilders: ["fake-type": [FakePresenterBuilder()]])
        weak var weakController = controller
        controller.updateQueue = updateQueue
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        controller.chatDataSource = fakeDataSource

        // See https://github.com/badoo/Chatto/issues/163
        autoreleasepool {
            self.fakeDidAppearAndLayout(controller: controller)
        }

        updateQueue.onAllTasksFinished = {
            asyncExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 1) { (_) -> Void in
            controller = nil
            XCTAssertNil(weakController)
        }
    }

    func testThat_WhenLayoutFinishes_ControllerIsNotRetained() {
        var controller: TesteableChatViewController! = TesteableChatViewController(presenterBuilders: ["fake-type": [FakePresenterBuilder()]])
        weak var weakController = controller
        controller.chatDataSource = FakeDataSource()

        // See https://github.com/badoo/Chatto/issues/163
        autoreleasepool {
            self.fakeDidAppearAndLayout(controller: controller)
        }

        controller = nil
        XCTAssertNil(weakController)
    }

    func testThat_LayoutAdaptsWhenKeyboardIsShown() {
        let controller = TesteableChatViewController()
        let notificationCenter = NotificationCenter()
        controller.notificationCenter = notificationCenter
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        notificationCenter.post(name: NSNotification.Name.UIKeyboardWillShow, object: self, userInfo: [UIKeyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        XCTAssertEqual(400, controller.view.convert(controller.chatInputView.bounds, from: controller.chatInputView).maxY)
    }

    func testThat_LayoutAdaptsWhenKeyboardIsHidden() {
        let controller = TesteableChatViewController()
        let notificationCenter = NotificationCenter()
        controller.notificationCenter = notificationCenter
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        notificationCenter.post(name: NSNotification.Name.UIKeyboardWillShow, object: self, userInfo: [UIKeyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        notificationCenter.post(name: NSNotification.Name.UIKeyboardDidShow, object: self, userInfo: [UIKeyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        notificationCenter.post(name: NSNotification.Name.UIKeyboardWillHide, object: self, userInfo: [UIKeyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        XCTAssertEqual(900, controller.view.convert(controller.chatInputView.bounds, from: controller.chatInputView).maxY)
    }

    func testThat_GivenCoalescingIsEnabled_WhenMultipleUpdatesAreRequested_ThenUpdatesAreCoalesced() {
        let controller = TesteableChatViewController()
        controller.updatesConfig.coalesceUpdates = true
        self.fakeDidAppearAndLayout(controller: controller)
        let fakeDataSource = FakeDataSource()
        let updateQueue = SerialTaskQueueTestHelper()
        controller.updateQueue = updateQueue

        controller.setChatDataSource(fakeDataSource, triggeringUpdateType: .none)
        controller.chatDataSourceDidUpdate(fakeDataSource) // running
        controller.chatDataSourceDidUpdate(fakeDataSource) // discarded
        controller.chatDataSourceDidUpdate(fakeDataSource) // discarded
        controller.chatDataSourceDidUpdate(fakeDataSource) // queued

        XCTAssertEqual(1, updateQueue.tasksQueue.count)
    }

    func testThat_GivenCoalescingIsDisabled_WhenMultipleUpdatesAreRequested_ThenUpdatesAreQueued() {
        let controller = TesteableChatViewController()
        controller.updatesConfig.coalesceUpdates = false
        self.fakeDidAppearAndLayout(controller: controller)
        let fakeDataSource = FakeDataSource()
        let updateQueue = SerialTaskQueueTestHelper()
        controller.updateQueue = updateQueue

        updateQueue.start()
        controller.setChatDataSource(fakeDataSource, triggeringUpdateType: .none)
        controller.chatDataSourceDidUpdate(fakeDataSource) // running
        controller.chatDataSourceDidUpdate(fakeDataSource) // queued
        controller.chatDataSourceDidUpdate(fakeDataSource) // queued
        controller.chatDataSourceDidUpdate(fakeDataSource) // queued

        XCTAssertEqual(3, updateQueue.tasksQueue.count)
    }

    // MARK: helpers

    fileprivate func fakeDidAppearAndLayout(controller: TesteableChatViewController) {
        controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 900)
        controller.viewWillAppear(true)
        controller.viewDidAppear(true)
        controller.view.layoutIfNeeded()
    }
}

extension ChatViewControllerTests {

    // MARK: Same Items

    func testThat_GivenDataSourceWithNotUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithSameItems_ThenTwoPresentersAreCreated() {
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        let numberOfCreatedPresentersBeforeUpdate = presenterBuilder.createdPresenters.count

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        let asyncExpectation = expectation(description: "update")
        controller.enqueueModelUpdate(updateType: .normal) {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { _ in
            let numberOfCreatedPresentersAfterUpdate = presenterBuilder.createdPresenters.count
            let numberOfCreatedPresenters = numberOfCreatedPresentersAfterUpdate - numberOfCreatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfCreatedPresenters, 2)
        }
    }

    func testThat_GivenDataSourceWithUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithSameItems_ThenTwoPresentersAreUpdated() {
        let presenterBuilder = FakeUpdatablePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        let numberOfUpdatedPresentersBeforeUpdate = presenterBuilder.updatedPresentersCount
        let numberOfCreatedPresentersBeforeUpdate = presenterBuilder.createdPresenters.count

        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        let asyncExpectation = expectation(description: "update")
        controller.enqueueModelUpdate(updateType: .normal) {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { _ in
            let numberOfUpdatedPresentersAfterUpdate = presenterBuilder.updatedPresentersCount
            let numberOfUpdatedPresenters = numberOfUpdatedPresentersAfterUpdate - numberOfUpdatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfUpdatedPresenters, 2)

            let numberOfCreatedPresentersAfterUpdate = presenterBuilder.createdPresenters.count
            let numberOfCreatedPresenters = numberOfCreatedPresentersAfterUpdate - numberOfCreatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfCreatedPresenters, 0)
        }
    }

    // MARK: New Items

    func testThat_GivenDataSourceWithNotUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithOneNewItem_ThenThreePresentersAreCreated() {
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        let numberOfCreatedPresentersBeforeUpdate = presenterBuilder.createdPresenters.count

        fakeDataSource.chatItems = createFakeChatItems(count: 3)
        let asyncExpectation = expectation(description: "update")
        controller.enqueueModelUpdate(updateType: .normal) {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { _ in
            let numberOfCreatedPresentersAfterUpdate = presenterBuilder.createdPresenters.count
            let numberOfCreatedPresenters = numberOfCreatedPresentersAfterUpdate - numberOfCreatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfCreatedPresenters, 3)
        }
    }

    func testThat_GivenDataSourceWithUpdatableItemPresenters_AndTwoItems_WhenItIsUpdatedWithOneNewItem_ThenTwoPresentersAreUpdated_AndOnePresenterIsCreated() {
        let presenterBuilder = FakeUpdatablePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        let numberOfUpdatedPresentersBeforeUpdate = presenterBuilder.updatedPresentersCount
        let numberOfCreatedPresentersBeforeUpdate = presenterBuilder.createdPresenters.count

        fakeDataSource.chatItems = createFakeChatItems(count: 3)
        let asyncExpectation = expectation(description: "update")
        controller.enqueueModelUpdate(updateType: .normal) {
            asyncExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { _ in
            let numberOfUpdatedPresentersAfterUpdate = presenterBuilder.updatedPresentersCount
            let numberOfUpdatedPresenters = numberOfUpdatedPresentersAfterUpdate - numberOfUpdatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfUpdatedPresenters, 2)

            let numberOfCreatedPresentersAfterUpdate = presenterBuilder.createdPresenters.count
            let numberOfCreatedPresenters = numberOfCreatedPresentersAfterUpdate - numberOfCreatedPresentersBeforeUpdate
            XCTAssertEqual(numberOfCreatedPresenters, 1)
        }
    }
}
