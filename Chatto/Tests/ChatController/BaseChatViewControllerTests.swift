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

    func testThat_GivenNoDataSource_ThenChatViewControllerLoadsCorrectly() {
        let controller = TesteableChatViewController()
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertNotNil(controller.view)
    }

    func testThat_GivenEmptyDataSource_ThenChatViewControllerLoadsCorrectly() {
        let controller = TesteableChatViewController()
        controller.chatDataSource = FakeDataSource()
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertNotNil(controller.view)
    }

    func testThat_GivenDataSourceWithItemsAndNoPresenters_ThenChatViewControllerLoadsCorrectly() {
        let controller = TesteableChatViewController()
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertNotNil(controller.view)
        XCTAssertEqual(2, controller.collectionView(controller.collectionView, numberOfItemsInSection: 0))
    }

    func testThat_PresentersAreCreated () {
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        XCTAssertEqual(2, presenterBuilder.presentersCreatedCount)
    }

    func testThat_WhenDataSourceChanges_ThenCollectionViewUpdatesAsynchronously() {
        let asyncExpectation = expectationWithDescription("update")
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        fakeDataSource.chatItems = createFakeChatItems(count: 3)
        fakeDataSource.delegate?.chatDataSourceDidUpdate(fakeDataSource)
        controller.updateQueue.addTask { (completion) -> Void in
            asyncExpectation.fulfill()
            completion()
        }
        self.waitForExpectationsWithTimeout(1) { (error) -> Void in
            XCTAssertEqual(3, controller.collectionView(controller.collectionView, numberOfItemsInSection: 0))
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
        let asyncExpectation = expectationWithDescription("update")
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        controller.updateQueue.addTask { (completion) -> Void in
            fakeDataSource.hasMorePrevious = true
            controller.collectionView.contentOffset = CGPoint.zero
            controller.scrollViewDidScrollToTop(controller.collectionView)
            completion()
            asyncExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1) { (error) -> Void in
            XCTAssertTrue(fakeDataSource.wasRequestedForPrevious)
        }
    }

    func testThat_WhenLoadsNextPage_ThenPreservesScrollPosition() {
        let asyncExpectation = expectationWithDescription("update")
        let presenterBuilder = FakePresenterBuilder()
        let controller = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        let contentOffset = controller.collectionView.contentOffset
        fakeDataSource.hasMoreNext = true
        fakeDataSource.chatItemsForLoadNext = createFakeChatItems(count: 3000)
        controller.autoLoadingEnabled = true // It will be false until first update finishes, let's fake it
        controller.autoLoadMoreContentIfNeeded()

        controller.updateQueue.addTask { (completion) -> Void in
            asyncExpectation.fulfill()
            completion()
        }

        self.waitForExpectationsWithTimeout(1) { (error) -> Void in
            XCTAssertEqual(3000, controller.collectionView(controller.collectionView, numberOfItemsInSection: 0))
            XCTAssertEqual(contentOffset, controller.collectionView.contentOffset)
        }
    }

    func testThat_WhenManyMessagesAreLoaded_ThenRequestForMessageCountContention() {
        let asyncExpectation = expectationWithDescription("update")
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
        self.waitForExpectationsWithTimeout(1) { (error) -> Void in
            XCTAssertTrue(fakeDataSource.wasRequestedForMessageCountContention)
        }
    }

    func testThat_ControllerDoesNotLeak() {
        let asyncExpectation = expectationWithDescription("update")
        let updateQueue = SerialTaskQueueTestHelper()
        let presenterBuilder = FakePresenterBuilder()
        var controller: TesteableChatViewController! = TesteableChatViewController(presenterBuilders: ["fake-type": [presenterBuilder]])
        weak var weakController = controller
        controller.updateQueue = updateQueue
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2000)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        updateQueue.onAllTasksFinished = {
            asyncExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1) { (error) -> Void in
            controller = nil
            XCTAssertNil(weakController)
        }
    }


    func testThat_LayoutAdaptsWhenKeyboardIsShown() {
        let controller = TesteableChatViewController()
        let notificationCenter = NSNotificationCenter()
        controller.notificationCenter = notificationCenter
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        notificationCenter.postNotificationName(UIKeyboardWillShowNotification, object: self, userInfo: [UIKeyboardFrameEndUserInfoKey: NSValue(CGRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        XCTAssertEqual(400, controller.view.convertRect(controller.chatInputView.bounds, fromView: controller.chatInputView).maxY)
    }

    func testThat_LayoutAdaptsWhenKeyboardIsHidden() {
        let controller = TesteableChatViewController()
        let notificationCenter = NSNotificationCenter()
        controller.notificationCenter = notificationCenter
        let fakeDataSource = FakeDataSource()
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        controller.chatDataSource = fakeDataSource
        self.fakeDidAppearAndLayout(controller: controller)
        notificationCenter.postNotificationName(UIKeyboardWillShowNotification, object: self, userInfo: [UIKeyboardFrameEndUserInfoKey: NSValue(CGRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        notificationCenter.postNotificationName(UIKeyboardDidShowNotification, object: self, userInfo: [UIKeyboardFrameEndUserInfoKey: NSValue(CGRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        notificationCenter.postNotificationName(UIKeyboardWillHideNotification, object: self, userInfo: [UIKeyboardFrameEndUserInfoKey: NSValue(CGRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        XCTAssertEqual(900, controller.view.convertRect(controller.chatInputView.bounds, fromView: controller.chatInputView).maxY)
    }


    // MARK: helpers

    private func fakeDidAppearAndLayout(controller controller: TesteableChatViewController) {
        controller.view.frame = CGRect(x: 0, y: 0, width: 400, height: 900)
        controller.viewWillAppear(true)
        controller.viewDidAppear(true)
        controller.view.layoutIfNeeded()
    }
}
