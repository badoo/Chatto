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
    let notificationCenter: NSNotificationCenter

    public init(chatInputBar: ChatInputBar,
                chatInputItems: [ChatInputItemProtocol],
                chatInputBarAppearance: ChatInputBarAppearance,
                notificationCenter: NSNotificationCenter = NSNotificationCenter.defaultCenter()) {
        self.chatInputBar = chatInputBar
        self.chatInputItems = chatInputItems
        self.chatInputBar.setAppearance(chatInputBarAppearance)
        self.notificationCenter = notificationCenter
        super.init()

        self.chatInputBar.presenter = self
        self.chatInputBar.inputItems = self.chatInputItems
        self.notificationCenter.addObserver(self, selector: #selector(BasicChatInputBarPresenter.keyboardDidChangeFrame), name: UIKeyboardDidChangeFrameNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(BasicChatInputBarPresenter.keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(BasicChatInputBarPresenter.keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
    }

    deinit {
        self.notificationCenter.removeObserver(self)
    }

    private(set) var focusedItem: ChatInputItemProtocol? {
        willSet {
            self.focusedItem?.setSelected(false)
        }
        didSet {
            self.focusedItem?.setSelected(true)
        }
    }

    private func updateFirstResponderWithInputItem(inputItem: ChatInputItemProtocol) {
        let responder = self.chatInputBar.textView
        let inputView = inputItem.inputView
        responder.inputView = inputView
        if responder.isFirstResponder() {
            self.setHeight(forInputView: inputView)
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

    private var lastKnownKeyboardHeight: CGFloat?

    private func setHeight(forInputView inputView: UIView?) {
        guard let inputView = inputView else { return }
        guard let keyboardHeight = self.lastKnownKeyboardHeight else { return }

        var mask = inputView.autoresizingMask
        mask.remove(.FlexibleHeight)
        inputView.autoresizingMask = mask

        let accessoryViewHeight = self.chatInputBar.textView.inputAccessoryView?.bounds.height ?? 0
        let inputViewHeight = keyboardHeight - accessoryViewHeight

        if let heightConstraint = inputView.constraints.filter({ $0.firstAttribute == .Height }).first {
            heightConstraint.constant = inputViewHeight
        } else {
            inputView.frame.size.height = inputViewHeight
        }
    }

    private var allowListenToChangeFrameEvents = true

    @objc
    private func keyboardDidChangeFrame(notification: NSNotification) {
        guard self.allowListenToChangeFrameEvents else { return }
        guard let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        self.lastKnownKeyboardHeight = value.CGRectValue().height
    }

    @objc
    private func keyboardWillHide(notification: NSNotification) {
        self.allowListenToChangeFrameEvents = false
    }

    @objc
    private func keyboardWillShow(notification: NSNotification) {
        self.allowListenToChangeFrameEvents = true
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
