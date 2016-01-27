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

@objc public class ChatInputBarPresenter: NSObject {
    let chatInputView: ChatInputBar
    let chatInputItems: [ChatInputItemProtocol]

    public init(chatInputView: ChatInputBar, chatInputItems: [ChatInputItemProtocol]) {
        self.chatInputView = chatInputView
        self.chatInputItems = chatInputItems
        self.chatInputView.tabBarInterItemSpacing = 10
        self.chatInputView.tabBarContentInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        super.init()

        self.chatInputView.delegate = self
        self.chatInputView.inputItems = self.chatInputItems
    }

    private(set) var focusedItem: ChatInputItemProtocol? {
        willSet {
            self.focusedItem?.selected = false
        }
        didSet {
            self.focusedItem?.selected = true
        }
    }

    private func updateFirstResponderWithInputItem(inputItem: ChatInputItemProtocol) {
        let responder = self.chatInputView.textView
        responder.inputView = inputItem.inputView
        if responder.isFirstResponder() {
            responder.reloadInputViews()
        } else {
            responder.becomeFirstResponder()
        }
    }

    private func firstKeyboardInputItem() -> ChatInputItemProtocol? {
        var firstKeyboardInputItem: ChatInputItemProtocol? = nil
        for inputItem in self.chatInputItems {
            if inputItem.presentationMode == .Keyboard {
                firstKeyboardInputItem = inputItem
                break
            }
        }
        return firstKeyboardInputItem
    }
}

extension ChatInputBarPresenter: ChatInputBarDelegate {
    public func inputBarDidEndEditing(inputBar: ChatInputBar) {
        self.focusedItem = nil
        self.chatInputView.textView.inputView = nil
        self.chatInputView.showsTextView = true
        self.chatInputView.showsSendButton = true
    }

    public func inputBarDidBeginEditing(inputBar: ChatInputBar) {
        if self.focusedItem == nil {
            self.focusedItem = self.firstKeyboardInputItem()
        }
    }

    func inputBarSendButtonPressed(inputBar: ChatInputBar) {
        if let focusedItem = self.focusedItem {
            focusedItem.handleInput(inputBar.inputText)
        } else if let keyboardItem = self.firstKeyboardInputItem() {
            keyboardItem.handleInput(inputBar.inputText)
        }
    }

    func inputBar(inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol) {
        guard item.presentationMode != .None else { return }
        guard item !== self.focusedItem else { return }

        self.focusedItem = item
        self.chatInputView.showsSendButton = item.showsSendButton
        self.chatInputView.showsTextView = item.presentationMode == .Keyboard
        self.updateFirstResponderWithInputItem(item)
    }
}
