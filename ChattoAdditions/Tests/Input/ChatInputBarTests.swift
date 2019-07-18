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
    private var delegateStrong: FakeChatInputBarDelegate!
    override func setUp() {
        super.setUp()
        self.bar = ChatInputBar.loadNib()
    }

    private func setupPresenter() {
        self.presenter = FakeChatInputBarPresenter(chatInputBar: self.bar)
    }

    private func setupDelegate() {
        self.delegateStrong = FakeChatInputBarDelegate()
        self.bar.delegate = self.delegateStrong
    }

    private func createItemView(inputItem: ChatInputItemProtocol) -> ChatInputItemView {
        let itemView = ChatInputItemView()
        itemView.inputItem = inputItem
        return itemView
    }

    private func simulateTapOnTextViewForDelegate(_ textViewDelegate: UITextViewDelegate) {
        let dummyTextView = UITextView()
        let shouldBeginEditing = textViewDelegate.textViewShouldBeginEditing?(dummyTextView) ?? true
        guard shouldBeginEditing else { return }
        textViewDelegate.textViewDidBeginEditing?(dummyTextView)
    }

    func testThat_WhenInputTextChanged_BarEnablesSendButton() {
        self.bar.sendButton.isEnabled = false
        self.bar.inputText = "!"
        XCTAssertTrue(self.bar.sendButton.isEnabled)
    }

    func testThat_WhenInputTextBecomesEmpty_BarDisablesSendButton() {
        self.bar.sendButton.isEnabled = true
        self.bar.inputText = ""
        XCTAssertFalse(self.bar.sendButton.isEnabled)
    }

    // MARK: - Presenter tests
    func testThat_WhenItemViewTapped_ItNotifiesPresenterThatNewItemReceivedFocus() {
        self.setupPresenter()
        let item = MockInputItem()
        self.bar.inputItemViewTapped(createItemView(inputItem: item))

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
        self.bar.sendButton.isEnabled = true

        self.bar.textView.text = ""
        self.bar.textViewDidChange(self.bar.textView)

        XCTAssertFalse(self.bar.sendButton.isEnabled)
    }

    func testThat_WhenTextViewDidChange_ItEnablesSendButton() {
        self.bar.sendButton.isEnabled = false

        self.bar.textView.text = "!"
        self.bar.textViewDidChange(self.bar.textView)

        XCTAssertTrue(self.bar.sendButton.isEnabled)
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
        self.bar.inputItemViewTapped(createItemView(inputItem: item))

        XCTAssertTrue(self.delegateStrong.inputBarDidReceiveFocusOnItemCalled)
        XCTAssertTrue(self.delegateStrong.focusedItem === item)
    }

    func testThat_WhenTextViewDidBeginEditing_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.textViewDidBeginEditing(self.bar.textView)
        XCTAssertTrue(self.delegateStrong.inputBarDidBeginEditingCalled)
    }

    func testThat_WhenTextViewDidEndEditing_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.textViewDidEndEditing(self.bar.textView)
        XCTAssertTrue(self.delegateStrong.inputBarDidEndEditingCalled)
    }

    func testThat_WhenTextViewDidChangeText_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.inputText = "text"
        self.bar.textViewDidChange(self.bar.textView)
        XCTAssertTrue(self.delegateStrong.inputBarDidChangeTextCalled)
    }

    func testThat_WhenExpandableTextViewPlaceholderIsShown_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.expandableTextViewDidShowPlaceholder(self.bar.textView)
        XCTAssertTrue(self.delegateStrong.inputBarDidShowPlaceholderCalled)
    }

    func testThat_WhenExpandableTextViewPlaceholderIsHidden_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.expandableTextViewDidHidePlaceholder(self.bar.textView)
        XCTAssertTrue(self.delegateStrong.inputBarDidHidePlaceholderCalled)
    }

    func testThat_WhenSendButtonTapped_ItNotifiesDelegate() {
        self.setupDelegate()
        self.bar.buttonTapped(self.bar)
        XCTAssertTrue(self.delegateStrong.inputBarSendButtonPressedCalled)
    }

    func testThat_WhenInputTextChangedAndCustomStateUpdateClosureProvided_BarUpdatesSendButtonStateAccordingly() {
        var closureCalled = false
        self.bar.shouldEnableSendButton = { (_) in
            closureCalled = true
            return false
        }
        self.bar.inputText = "    "
        self.bar.textViewDidChange(self.bar.textView)
        XCTAssertTrue(closureCalled)
        XCTAssertFalse(self.bar.sendButton.isEnabled)
    }

    func testThat_WhenItemViewTapped_ItReceivesFocuesByDefault() {
        self.setupPresenter()

        let item = MockInputItem()
        self.bar.inputItemViewTapped(createItemView(inputItem: item))

        XCTAssertTrue(self.presenter.onDidReceiveFocusOnItemCalled)
        XCTAssertTrue(self.presenter.itemThatReceivedFocus === item)
    }

    func testThat_WhenItemViewTappedAndDelegateAllowsFocusing_ItWillFocusTheItem() {
        self.setupDelegate()
        self.delegateStrong.inputBarShouldFocusOnItemResult = true

        let item = MockInputItem()
        self.bar.inputItemViewTapped(createItemView(inputItem: item))

        XCTAssertTrue(self.delegateStrong.inputBarShouldFocusOnItemCalled)
        XCTAssertTrue(self.delegateStrong.inputBarDidReceiveFocusOnItemCalled)
        XCTAssertTrue(self.delegateStrong.focusedItem === item)
    }

    func testThat_GivenFocusedItemIsNil_WhenFocusOnItem_InputBarDidLoseFocusIsNotCalled() {
        self.setupDelegate()
        self.setupPresenter()
        self.delegateStrong.inputBarShouldFocusOnItemResult = true
        let item = MockInputItem()

        self.presenter.focusedItem = nil
        self.bar.focusOnInputItem(item)

        XCTAssertFalse(self.delegateStrong.inputBarDidLoseFocusOnItemCalled)
        XCTAssertTrue(self.delegateStrong.inputBarDidReceiveFocusOnItemCalled)
    }

    func testThat_GivenFocusedItemIsItem1_WhenFocusOnItem2_InputBarDidLoseFocusIsCalled() {
        self.setupDelegate()
        self.setupPresenter()
        self.delegateStrong.inputBarShouldFocusOnItemResult = true
        let item1 = MockInputItem()
        let item2 = MockInputItem()

        self.presenter.focusedItem = item1
        self.bar.focusOnInputItem(item2)

        XCTAssertTrue(self.delegateStrong.inputBarDidLoseFocusOnItemCalled)
        XCTAssertTrue(self.delegateStrong.inputBarDidReceiveFocusOnItemCalled)
    }

    func testThat_WhenItemViewTappedAndDelegateDisallowsFocusing_ItWontFocusTheItem() {
        self.setupDelegate()
        self.delegateStrong.inputBarShouldFocusOnItemResult = false

        let item = MockInputItem()
        self.bar.inputItemViewTapped(createItemView(inputItem: item))

        XCTAssertTrue(self.delegateStrong.inputBarShouldFocusOnItemCalled)
        XCTAssertFalse(self.delegateStrong.inputBarDidReceiveFocusOnItemCalled)
    }

    func testThat_WhenTextViewGoingToBecomeEditable_ItBecomesEditableByDefault() {
        self.setupPresenter()
        self.simulateTapOnTextViewForDelegate(self.bar)
        XCTAssertTrue(self.presenter.onDidBeginEditingCalled)
    }

    func testThat_WhenTextViewGoingToBecomeEditableAndDelegateAllowsIt_ItWillBeEditable() {
        self.setupDelegate()
        self.delegateStrong.inputBarShouldBeginTextEditingResult = true
        self.simulateTapOnTextViewForDelegate(self.bar)
        XCTAssertTrue(self.delegateStrong.inputBarShouldBeginTextEditingCalled)
        XCTAssertTrue(self.delegateStrong.inputBarDidBeginEditingCalled)
    }

    func testThat_WhenTextViewGoingToBecomeEditableAndDelegateDisallowsIt_ItWontBeEditable() {
        self.setupDelegate()
        self.delegateStrong.inputBarShouldBeginTextEditingResult = false
        self.simulateTapOnTextViewForDelegate(self.bar)
        XCTAssertTrue(self.delegateStrong.inputBarShouldBeginTextEditingCalled)
        XCTAssertFalse(self.delegateStrong.inputBarDidBeginEditingCalled)
    }
}

class FakeChatInputBarPresenter: ChatInputBarPresenter {
    var focusedItem: ChatInputItemProtocol?

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
    func onDidReceiveFocusOnItem(_ item: ChatInputItemProtocol) {
        self.onDidReceiveFocusOnItemCalled = true
        self.itemThatReceivedFocus = item
    }
}

class FakeChatInputBarDelegate: ChatInputBarDelegate {
    var inputBarShouldBeginTextEditingCalled = false
    var inputBarShouldBeginTextEditingResult = true
    func inputBarShouldBeginTextEditing(_ inputBar: ChatInputBar) -> Bool {
        self.inputBarShouldBeginTextEditingCalled = true
        return self.inputBarShouldBeginTextEditingResult
    }

    var inputBarDidBeginEditingCalled = false
    func inputBarDidBeginEditing(_ inputBar: ChatInputBar) {
        self.inputBarDidBeginEditingCalled = true
    }

    var inputBarDidEndEditingCalled = false
    func inputBarDidEndEditing(_ inputBar: ChatInputBar) {
        self.inputBarDidEndEditingCalled = true
    }

    var inputBarDidChangeTextCalled = false
    func inputBarDidChangeText(_ inputBar: ChatInputBar) {
        self.inputBarDidChangeTextCalled = true
    }

    var inputBarSendButtonPressedCalled = false
    func inputBarSendButtonPressed(_ inputBar: ChatInputBar) {
        self.inputBarSendButtonPressedCalled = true
    }

    var inputBarShouldFocusOnItemCalled = false
    var inputBarShouldFocusOnItemResult = true
    func inputBar(_ inputBar: ChatInputBar, shouldFocusOnItem item: ChatInputItemProtocol) -> Bool {
        self.inputBarShouldFocusOnItemCalled = true
        return self.inputBarShouldFocusOnItemResult
    }

    var inputBarDidLoseFocusOnItemCalled = false
    func inputBar(_ inputBar: ChatInputBar, didLoseFocusOnItem item: ChatInputItemProtocol) {
        self.inputBarDidLoseFocusOnItemCalled = true
    }

    var inputBarDidReceiveFocusOnItemCalled = false
    var focusedItem: ChatInputItemProtocol?
    func inputBar(_ inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol) {
        self.inputBarDidReceiveFocusOnItemCalled = true
        self.focusedItem = item
    }

    var inputBarDidShowPlaceholderCalled = false
    func inputBarDidShowPlaceholder(_ inputBar: ChatInputBar) {
        self.inputBarDidShowPlaceholderCalled = true
    }

    var inputBarDidHidePlaceholderCalled = false
    func inputBarDidHidePlaceholder(_ inputBar: ChatInputBar) {
        self.inputBarDidHidePlaceholderCalled = true
    }
}
