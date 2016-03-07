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
@testable import ChattoAdditions

class ChatInputBarTests: XCTestCase {
    private var bar: ChatInputBar!
    private var presenter: FakeChatInputBarPresenter!
    private var delegate: FakeChatInputBarDelegate!
    override func setUp() {
        super.setUp()
        self.bar = ChatInputBar.loadNib()
    }

    private func setupPresenter() {
        self.presenter = FakeChatInputBarPresenter(chatInputBar: self.bar)
    }

    private func setupDelegate() {
        self.delegate = FakeChatInputBarDelegate()
        self.bar.delegate = self.delegate
    }

    private func createItemView(inputItem: ChatInputItemProtocol) -> ChatInputItemView {
        let itemView = ChatInputItemView()
        itemView.inputItem = inputItem
        return itemView
    }

    func testThat_WhenInputTextChanged_BarEnablesSendButton() {
        self.bar.sendButton.enabled = false
        self.bar.inputText = "!"
        XCTAssertTrue(self.bar.sendButton.enabled)
    }

    func testThat_WhenInputTextBecomesEmpty_BarDisablesSendButton() {
        self.bar.sendButton.enabled = true
        self.bar.inputText = ""
        XCTAssertFalse(self.bar.sendButton.enabled)
    }

    // MARK: - Presenter tests
    func testThat_WhenItemViewTapped_ItNotifiesPresenterThatNewItemReceivedFocus() {
        self.setupPresenter()
        let item = MockInputItem()
        self.bar.inputItemViewTapped(createItemView(item))

        XCTAssertTrue(self.presenter.onDidReceiveFocusOnItemCalled)
        XCTAssertTrue(self.presenter.itemThatReceivedFocus === item)
    }

    func testThat_WhenTextViewDidBeginEditing_ItNotifiesPresenter() {
        self.setupPresenter()
        self.bar.textViewDidBeginEditing(self.bar.textView)
        XCTAssertTrue(self.presenter.onDidBeginEditingCalled)
    }

    func testThat_WhenTextViewDidEndEditing_ItNotifiesPresenter() {
        self.setupPresenter()
        self.bar.textViewDidEndEditing(self.bar.textView)
        XCTAssertTrue(self.presenter.onDidEndEditingCalled)
    }

    func testThat_GivenTextViewHasNoText_WhenTextViewDidChange_ItDisablesSendButton() {
        self.bar.sendButton.enabled = true

        self.bar.textView.text = ""
        self.bar.textViewDidChange(self.bar.textView)

        XCTAssertFalse(self.bar.sendButton.enabled)
    }

    func testThat_WhenTextViewDidChange_ItEnablesSendButton() {
        self.bar.sendButton.enabled = false

        self.bar.textView.text = "!"
        self.bar.textViewDidChange(self.bar.textView)

        XCTAssertTrue(self.bar.sendButton.enabled)
    }

    func testThat_WhenSendButtonTapped_ItNotifiesPresenter() {
        self.setupPresenter()
        self.bar.buttonTapped(self.bar)
        XCTAssertTrue(self.presenter.onSendButtonPressedCalled)
    }

    // MARK: Delegation Tests
    func testThat_WhenItemViewTapped_ItNotifiesDelegateThatNewItemReceivedFocus() {
        self.setupDelegate()
        let item = MockInputItem()
        self.bar.inputItemViewTapped(createItemView(item))

        XCTAssertTrue(self.delegate.inputBarDidReceiveFocusOnItemCalled)
        XCTAssertTrue(self.delegate.focusedItem === item)
    }

    func testThat_WhenTextViewDidBeginEditing_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.textViewDidBeginEditing(self.bar.textView)
        XCTAssertTrue(self.delegate.inputBarDidBeginEditingCalled)
    }

    func testThat_WhenTextViewDidEndEditing_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.textViewDidEndEditing(self.bar.textView)
        XCTAssertTrue(self.delegate.inputBarDidEndEditingCalled)
    }

    func testThat_WhenTextViewDidChangeText_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.inputText = "text"
        self.bar.textViewDidChange(self.bar.textView)
        XCTAssertTrue(self.delegate.inputBarDidChangeTextCalled)
    }

    func testThat_WhenSendButtonTapped_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.buttonTapped(self.bar)
        XCTAssertTrue(self.delegate.inputBarSendButtonPressedCalled)
    }
}

class FakeChatInputBarPresenter: ChatInputBarPresenter {
    let chatInputBar: ChatInputBar
    init(chatInputBar: ChatInputBar) {
        self.chatInputBar = chatInputBar
        self.chatInputBar.presenter = self
    }

    var onDidBeginEditingCalled = false
    func onDidBeginEditing() {
        self.onDidBeginEditingCalled = true
    }

    var onDidEndEditingCalled = false
    func onDidEndEditing() {
        self.onDidEndEditingCalled = true
    }

    var onSendButtonPressedCalled = false
    func onSendButtonPressed() {
        self.onSendButtonPressedCalled = true
    }

    var onDidReceiveFocusOnItemCalled = false
    var itemThatReceivedFocus: ChatInputItemProtocol?
    func onDidReceiveFocusOnItem(item: ChatInputItemProtocol) {
        self.onDidReceiveFocusOnItemCalled = true
        self.itemThatReceivedFocus = item
    }
}

class FakeChatInputBarDelegate: ChatInputBarDelegate {
    var inputBarDidBeginEditingCalled = false
    func inputBarDidBeginEditing(inputBar: ChatInputBar) {
        self.inputBarDidBeginEditingCalled = true
    }

    var inputBarDidEndEditingCalled = false
    func inputBarDidEndEditing(inputBar: ChatInputBar) {
        self.inputBarDidEndEditingCalled = true
    }

    var inputBarDidChangeTextCalled = false
    func inputBarDidChangeText(inputBar: ChatInputBar) {
        self.inputBarDidChangeTextCalled = true
    }

    var inputBarSendButtonPressedCalled = false
    func inputBarSendButtonPressed(inputBar: ChatInputBar) {
        self.inputBarSendButtonPressedCalled = true
    }

    var inputBarDidReceiveFocusOnItemCalled = false
    var focusedItem: ChatInputItemProtocol?
    func inputBar(inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol) {
        self.inputBarDidReceiveFocusOnItemCalled = true
        self.focusedItem = item
    }
}
