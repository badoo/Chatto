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
    private var delegate: MockChatInputBarDelegate!
    override func setUp() {
        super.setUp()
        self.bar = ChatInputBar.loadNib()
    }

    private func setupDelegate() {
        self.delegate = MockChatInputBarDelegate()
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

    // MARK: - Delegation tests
    func testThat_WhenItemViewTapped_ItNotifiesDelegateThatNewItemReceivedFocus() {
        self.setupDelegate()
        let item = MockInputItem()
        self.bar.inputItemViewTapped(createItemView(item))

        XCTAssertTrue(self.delegate.itemDidReceiveFocus)
        XCTAssertTrue(self.delegate.itemThatReceivedFocus === item)
    }

    func testThat_WhenTextViewDidBeginEditing_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.textViewDidBeginEditing(self.bar.textView)
        XCTAssertTrue(self.delegate.inputBarDidBeginEditing)
    }

    func testThat_WhenTextViewDidEndEditing_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.textViewDidEndEditing(self.bar.textView)
        XCTAssertTrue(self.delegate.inputBarDidEndEditing)
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

    func testThat_WhenSendButtonTapped_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.buttonTapped(self.bar)
        XCTAssertTrue(self.delegate.inputBarSendButtonPressed)
    }
}

class MockChatInputBarDelegate: ChatInputBarDelegate {
    var inputBarDidBeginEditing = false
    func inputBarDidBeginEditing(inputBar: ChatInputBar) {
        self.inputBarDidBeginEditing = true
    }

    var inputBarDidEndEditing = false
    func inputBarDidEndEditing(inputBar: ChatInputBar) {
        self.inputBarDidEndEditing = true
    }

    var inputBarSendButtonPressed = false
    func inputBarSendButtonPressed(inputBar: ChatInputBar) {
        self.inputBarSendButtonPressed = true
    }

    var itemDidReceiveFocus = false
    var itemThatReceivedFocus: ChatInputItemProtocol?
    func inputBar(inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol) {
        self.itemDidReceiveFocus = true
        self.itemThatReceivedFocus = item
    }
}
