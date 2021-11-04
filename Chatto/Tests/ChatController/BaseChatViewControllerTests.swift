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

class BaseChatViewControllerTests: XCTestCase {

    func testThat_LayoutAdaptsWhenKeyboardIsShown() {
        let fakeDataSource = FakeDataSource()
        let updateQueue = SerialTaskQueueTestHelper()
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource,
            updateQueue: updateQueue
        )
        let notificationCenter = NotificationCenter()
        let chatInputViewPresenter = FakeChatInputBarPresenter(inputView: UIView())
        let controller = BaseChatViewController.makeBaseChatViewController(
            messagesViewController: chatMessageTestComponents.viewController,
            chatInputViewPresenter: chatInputViewPresenter,
            notificationCenter: notificationCenter
        )
        fakeDataSource.chatItems = createFakeChatItems(count: 2)
        fakeDidAppearAndLayout(controller: controller)
        notificationCenter.post(name: UIResponder.keyboardWillShowNotification, object: self, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        XCTAssertEqual(400, controller.view.convert(chatInputViewPresenter.inputView.bounds, from: chatInputViewPresenter.inputView).maxY)
    }

    func testThat_LayoutAdaptsWhenKeyboardIsHidden() {
        let fakeDataSource = FakeDataSource()
        let chatMessageTestComponents = ChatMessageTestComponents(
            dataSource: fakeDataSource
        )
        let notificationCenter = NotificationCenter()
        let chatInputViewPresenter = FakeChatInputBarPresenter(inputView: UIView())
        let controller = BaseChatViewController.makeBaseChatViewController(
            messagesViewController: chatMessageTestComponents.viewController,
            chatInputViewPresenter: chatInputViewPresenter,
            notificationCenter: notificationCenter
        )

        fakeDataSource.chatItems = createFakeChatItems(count: 2)

        fakeDidAppearAndLayout(controller: controller)
        notificationCenter.post(name: UIResponder.keyboardWillShowNotification, object: self, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        notificationCenter.post(name: UIResponder.keyboardDidShowNotification, object: self, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        notificationCenter.post(name: UIResponder.keyboardWillHideNotification, object: self, userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 400, width: 400, height: 500))])
        XCTAssertEqual(900, controller.view.convert(chatInputViewPresenter.inputView.bounds, from: chatInputViewPresenter.inputView).maxY)
    }
}

private final class FakeChatInputBarPresenter: BaseChatInputBarPresenterProtocol {
    let inputView: UIView

    weak var viewController: ChatInputBarPresentingController? {
        didSet {
            guard let viewController = self.viewController else { return }

            viewController.setup(inputView: self.inputView)
        }
    }

    init(inputView: UIView) {
        self.inputView = inputView
    }

    func onViewDidUpdate() { }
}
