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

class ChatInputPresenterTests: XCTestCase {
    private var bar: ChatInputBar!
    private var presenter: BasicChatInputBarPresenter!
    override func setUp() {
        super.setUp()
        self.bar = ChatInputBar.loadNib()
        self.presenter = BasicChatInputBarPresenter(chatInputBar: self.bar, chatInputItems: [], chatInputBarAppearance: ChatInputBarAppearance())
    }

    func testThat_WhenSendButtonPressed_InputTextBecomesEmpty() {
        self.bar.inputText = "text"
        self.presenter.onSendButtonPressed()
        XCTAssertEqual(self.bar.inputText.characters.count, 0)
    }

    // MARK: - Focused item tests
    func testThat_WhenItemDidReceiveFocus_ItemBecomesFocused() {
        let item = MockInputItem() as ChatInputItemProtocol
        self.presenter.onDidReceiveFocusOnItem(item)
        XCTAssertTrue(self.presenter.focusedItem! === item)
    }

    func testThat_WhenAnotherItemDidReceiveFocus_AnotherItemBecomesFocused() {
        let item = MockInputItem()
        self.presenter.onDidReceiveFocusOnItem(item)

        let anotherItem = MockInputItem() as ChatInputItemProtocol
        self.presenter.onDidReceiveFocusOnItem(anotherItem)
        XCTAssertTrue(self.presenter.focusedItem! === anotherItem)
    }

    func testThat_GivenItemHasNonePresentationMode_WhenItemReceivesFocus_ItDoesntBecomeFocused() {
        let item = MockInputItem()
        item.presentationMode = .none
        self.presenter.onDidReceiveFocusOnItem(item)
        XCTAssertNil(self.presenter.focusedItem)
    }

    func testThat_WhenItemReceivesFocus_ItBecomesSelected() {
        let item = MockInputItem()
        self.presenter.onDidReceiveFocusOnItem(item)
        XCTAssertTrue(item.selected)
    }

    func testThat_WhenAnotherItemReceivesFocus_PreviousItemBecomesDeselected() {
        let item = MockInputItem()
        self.presenter.onDidReceiveFocusOnItem(item)

        let anotherItem = MockInputItem()
        self.presenter.onDidReceiveFocusOnItem(anotherItem)
        XCTAssertFalse(item.selected)
    }

    func testThat_GivenItemShowsSendButton_WhenItemReceivesFocus_PresenterShowsSendButton() {
        let item = MockInputItem()
        item.showsSendButton = true
        self.presenter.onDidReceiveFocusOnItem(item)
        XCTAssertTrue(self.bar.showsSendButton)
    }

    func testThat_GivenItemDoesntShowSendButton_WhenItemReceivesFocus_PresenterHidesSendButton() {
        self.bar.showsSendButton = true
        let item = MockInputItem()
        self.presenter.onDidReceiveFocusOnItem(item)
        XCTAssertFalse(self.bar.showsSendButton)
    }

    func testThat_GivenItemHasKeyboardPresentationMode_WhenItemReceivesFocus_PresenterShowsTextView() {
        self.bar.showsTextView = false
        let item = MockInputItem()
        item.presentationMode = .keyboard
        self.presenter.onDidReceiveFocusOnItem(item)
        XCTAssertTrue(self.bar.showsTextView)
    }

    func testThat_GivenItemHasCustomViewPresentationMode_WhenItemReceivesFocus_PresenterHidesTextView() {
        self.bar.showsTextView = true
        let item = MockInputItem()
        item.presentationMode = .customView
        self.presenter.onDidReceiveFocusOnItem(item)
        XCTAssertFalse(self.bar.showsTextView)
    }

    func testThat_GivenItemHasNonePresentationMode_WhenItemReceivesFocus_PresenterDoesntHideTextView() {
        self.bar.showsTextView = true
        let item = MockInputItem()
        item.presentationMode = .none
        self.presenter.onDidReceiveFocusOnItem(item)
        XCTAssertTrue(self.bar.showsTextView)

    }

    func testThat_GivenPresenterHasFocusedItem_WhenSendButtonPressed_FocusedItemHandlesInputFromInputBar() {
        let item = MockInputItem()
        self.presenter.onDidReceiveFocusOnItem(item)

        let inputText = "inputText"
        self.bar.inputText = inputText
        self.presenter.onSendButtonPressed()

        XCTAssertTrue(item.handledInput as! String == inputText)
    }

    func testThat_GivenPresenterHasNoFocusedItem_WhenSendButtonPressed_FirstKeyboardItemHandlesInputFromInputBar() {
        var itemThatHandledInput = 0
        let firstInputItem = TextChatInputItem()
        firstInputItem.textInputHandler = { text in
            itemThatHandledInput = 1
        }

        let secondInputItem = TextChatInputItem()
        secondInputItem.textInputHandler = { text in
            itemThatHandledInput = 2
        }

        let inputItems: [ChatInputItemProtocol] = [firstInputItem, secondInputItem]
        self.presenter = BasicChatInputBarPresenter(chatInputBar: self.bar, chatInputItems: inputItems, chatInputBarAppearance: ChatInputBarAppearance())
        self.presenter.onSendButtonPressed()
        XCTAssertEqual(itemThatHandledInput, 1)
    }

    // MARK: - Bar editing tests
    func testThat_GivenPresenterHasFocusedItem_WhenBarDidEndEditing_FocusedItemLostFocus() {
        let item = MockInputItem()
        self.presenter.onDidReceiveFocusOnItem(item)
        self.presenter.onDidEndEditing()
        XCTAssertNil(self.presenter.focusedItem)
    }

    func testThat_WhenBarDidEndEditing_PresenterShowsSendButton() {
        self.bar.showsSendButton = false
        self.presenter.onDidEndEditing()
        XCTAssertTrue(self.bar.showsSendButton)
    }

    func testThat_WhenBarDidEndEditing_PresenterShowsTextView() {
        self.bar.showsTextView = false
        self.presenter.onDidEndEditing()
        XCTAssertTrue(self.bar.showsTextView)
    }

    func testThat_GivenPresenterHasNoFocusedItem_WhenBarDidBeginEditing_FirstKeyboardItemBecomesFocused() {
        let inputItems: [ChatInputItemProtocol] = [TextChatInputItem(), TextChatInputItem()]
        self.presenter = BasicChatInputBarPresenter(chatInputBar: self.bar, chatInputItems: inputItems, chatInputBarAppearance: ChatInputBarAppearance())
        self.presenter.onDidBeginEditing()
        XCTAssertTrue(self.presenter.focusedItem! === inputItems[0])
    }
}
