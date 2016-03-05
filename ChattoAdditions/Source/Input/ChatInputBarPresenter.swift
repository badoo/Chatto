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

protocol ChatInputBarPresenter: class {
    var chatInputBar: ChatInputBar { get }
    func onDidBeginEditing()
    func onDidEndEditing()
    func onSendButtonPressed()
    func onDidReceiveFocusOnItem(item: ChatInputItemProtocol)
}

@objc public class BasicChatInputBarPresenter: NSObject, ChatInputBarPresenter {
    let chatInputBar: ChatInputBar
    let chatInputItems: [ChatInputItemProtocol]

    public init(chatInputBar: ChatInputBar, chatInputItems: [ChatInputItemProtocol]) {
        self.chatInputBar = chatInputBar
        self.chatInputItems = chatInputItems
        self.chatInputBar.tabBarInterItemSpacing = 10
        self.chatInputBar.tabBarContentInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        super.init()

        self.chatInputBar.presenter = self
        self.chatInputBar.inputItems = self.chatInputItems
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
        let responder = self.chatInputBar.textView
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

// MARK: ChatInputBarPresenter
extension BasicChatInputBarPresenter {
    public func onDidEndEditing() {
        self.focusedItem = nil
        self.chatInputBar.textView.inputView = nil
        self.chatInputBar.showsTextView = true
        self.chatInputBar.showsSendButton = true
    }

    public func onDidBeginEditing() {
        if self.focusedItem == nil {
            self.focusedItem = self.firstKeyboardInputItem()
        }
    }

    func onSendButtonPressed() {
        if let focusedItem = self.focusedItem {
            focusedItem.handleInput(self.chatInputBar.inputText)
        } else if let keyboardItem = self.firstKeyboardInputItem() {
            keyboardItem.handleInput(self.chatInputBar.inputText)
        }
        self.chatInputBar.inputText = ""
    }

    func onDidReceiveFocusOnItem(item: ChatInputItemProtocol) {
        guard item.presentationMode != .None else { return }
        guard item !== self.focusedItem else { return }

        self.focusedItem = item
        self.chatInputBar.showsSendButton = item.showsSendButton
        self.chatInputBar.showsTextView = item.presentationMode == .Keyboard
        self.updateFirstResponderWithInputItem(item)
    }
}
