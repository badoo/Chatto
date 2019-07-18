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
    var focusedItem: ChatInputItemProtocol? { get }
    var chatInputBar: ChatInputBar { get }
    func onDidBeginEditing()
    func onDidEndEditing()
    func onSendButtonPressed()
    func onDidReceiveFocusOnItem(_ item: ChatInputItemProtocol)
}

@objc
public class BasicChatInputBarPresenter: NSObject, ChatInputBarPresenter {
    public let chatInputBar: ChatInputBar
    let chatInputItems: [ChatInputItemProtocol]
    let notificationCenter: NotificationCenter

    public init(chatInputBar: ChatInputBar,
                chatInputItems: [ChatInputItemProtocol],
                chatInputBarAppearance: ChatInputBarAppearance,
                notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.chatInputBar = chatInputBar
        self.chatInputItems = chatInputItems
        self.chatInputBar.setAppearance(chatInputBarAppearance)
        self.notificationCenter = notificationCenter
        super.init()

        self.chatInputBar.presenter = self
        self.chatInputBar.inputItems = self.chatInputItems
        self.notificationCenter.addObserver(self, selector: #selector(keyboardDidChangeFrame), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(handleOrienationDidChangeNotification), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    deinit {
        self.notificationCenter.removeObserver(self)
    }

    fileprivate(set) var focusedItem: ChatInputItemProtocol? {
        willSet {
            self.focusedItem?.selected = false
        }
        didSet {
            self.focusedItem?.selected = true
        }
    }

    fileprivate func updateFirstResponderWithInputItem(_ inputItem: ChatInputItemProtocol) {
        let responder = self.chatInputBar.textView!
        if let inputView = inputItem.inputView {
            let containerView: InputContainerView = {
                let containerView = InputContainerView()
                containerView.allowsSelfSizing = true
                containerView.translatesAutoresizingMaskIntoConstraints = false
                containerView.contentView = inputView
                self.updateHeight(for: containerView)
                return containerView
            }()
            responder.inputView = containerView
            self.currentInputView = containerView
        } else {
            responder.inputView = nil
            self.currentInputView = nil
        }

        if responder.isFirstResponder {
            responder.reloadInputViews()
        } else {
            responder.becomeFirstResponder()
        }
    }

    fileprivate func firstKeyboardInputItem() -> ChatInputItemProtocol? {
        var firstKeyboardInputItem: ChatInputItemProtocol?
        for inputItem in self.chatInputItems where inputItem.presentationMode == .keyboard {
            firstKeyboardInputItem = inputItem
            break
        }
        return firstKeyboardInputItem
    }

    private var lastKnownKeyboardHeight: CGFloat?
    private var allowListenToChangeFrameEvents = true

    // MARK: Input View

    private weak var currentInputView: InputContainerView?

    private func updateHeight(for inputView: InputContainerView) {
        inputView.contentHeight = {
            if let keyboardHeight = self.lastKnownKeyboardHeight, keyboardHeight > 0 {
                return keyboardHeight
            } else {
                if UIApplication.shared.statusBarOrientation.isPortrait {
                    return UIScreen.main.defaultPortraitKeyboardHeight
                } else {
                    return UIScreen.main.defaultLandscapeKeyboardHeight
                }
            }
        }()
    }

    // MARK: Notifications handling

    @objc
    private func keyboardDidChangeFrame(_ notification: Notification) {
        guard self.allowListenToChangeFrameEvents else { return }
        // When a modal controller is dismissed UIKit posts keyboard notifications before focus is returned to the previously selected item
        // Input bar height depends on a selected item so we shouldn't remember keyboard height without having a selected item
        guard self.focusedItem != nil else { return }
        guard let value = (notification as NSNotification).userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        guard value.cgRectValue.height > 0 else { return }
        self.lastKnownKeyboardHeight = value.cgRectValue.height - self.chatInputBar.bounds.height
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        self.allowListenToChangeFrameEvents = false
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        self.allowListenToChangeFrameEvents = true
    }

    @objc
    private func handleOrienationDidChangeNotification(_ notification: Notification) {
        self.lastKnownKeyboardHeight = nil
        if let currentInputView = self.currentInputView {
            self.updateHeight(for: currentInputView)
        }
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
            focusedItem.handleInput(self.chatInputBar.inputText as AnyObject)
        } else if let keyboardItem = self.firstKeyboardInputItem() {
            keyboardItem.handleInput(self.chatInputBar.inputText as AnyObject)
        }
        self.chatInputBar.inputText = ""
    }

    func onDidReceiveFocusOnItem(_ item: ChatInputItemProtocol) {
        guard item.presentationMode != .none else { return }
        guard item !== self.focusedItem else { return }

        self.focusedItem = item
        self.chatInputBar.showsSendButton = item.showsSendButton
        self.chatInputBar.showsTextView = item.presentationMode == .keyboard
        self.updateFirstResponderWithInputItem(item)
    }
}
