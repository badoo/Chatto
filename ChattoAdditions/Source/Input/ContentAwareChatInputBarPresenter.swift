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

import Chatto

@objc
public class ContentAwareChatInputBarPresenter: NSObject, ChatInputBarPresenter {
    public let chatInputBar: ChatInputBar
    let chatInputItems: [ChatInputItemProtocol]
    let notificationCenter: NotificationCenter

    weak var containerController: ContainerControllerProtocol?
    weak var keyboardAwareController: KeyboardAwareControllerProtocol?
    weak var scrollAwareController: ScrollAwareControllerProtocol?

    public init(containerController: ContainerControllerProtocol,
                keyboardAwareController: KeyboardAwareControllerProtocol,
                scrollAwareController: ScrollAwareControllerProtocol,
                chatInputBar: ChatInputBar,
                chatInputItems: [ChatInputItemProtocol],
                chatInputBarAppearance: ChatInputBarAppearance,
                notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.containerController = containerController
        self.keyboardAwareController = keyboardAwareController
        self.scrollAwareController = scrollAwareController

        self.chatInputBar = chatInputBar
        self.chatInputItems = chatInputItems
        self.chatInputBar.setAppearance(chatInputBarAppearance)
        self.notificationCenter = notificationCenter
        super.init()

        self.chatInputBar.presenter = self
        self.chatInputBar.inputItems = self.chatInputItems
        self.notificationCenter.addObserver(self, selector: #selector(keyboardDidChangeFrame), name: .UIKeyboardDidChangeFrame, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(handleOrienationDidChangeNotification), name: .UIApplicationDidChangeStatusBarOrientation, object: nil)

        self.subscribeToControllers()
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

    fileprivate var shouldIgnoreContainerBottomMarginUpdates: Bool = false
    fileprivate func updateContentContainer(withInputItem inputItem: ChatInputItemProtocol) {
        self.cleanCurrentInputView()
        let responder = self.chatInputBar.textView!
        if inputItem.presentationMode == .keyboard {
            responder.becomeFirstResponder()
        } else if let inputView = inputItem.inputView, let containerController = self.containerController {
            responder.resignFirstResponder()
            self.setupInputView(toContainerController: containerController, inputView)
        }
    }

    fileprivate func firstKeyboardInputItem() -> ChatInputItemProtocol? {
        var firstKeyboardInputItem: ChatInputItemProtocol? = nil
        for inputItem in self.chatInputItems where inputItem.presentationMode == .keyboard {
            firstKeyboardInputItem = inputItem
            break
        }
        return firstKeyboardInputItem
    }

    private func cleanCurrentInputView(animated: Bool = false, completion: (() -> Void)? = nil) {
        self.currentInputView?.endEditing(false)
        if animated {
            UIView.animate(withDuration: CATransaction.animationDuration(),
                           animations: {
                            self.currentInputView?.alpha = 0.0
            },
                           completion: { (_) in
                            self.currentInputView?.removeFromSuperview()
                            completion?()
            })
        } else {
            self.currentInputView?.removeFromSuperview()
            completion?()
        }
    }

    private func setupInputView(toContainerController containerController: ContainerControllerProtocol, _ inputView: UIView) {
        self.shouldIgnoreContainerBottomMarginUpdates = true
        containerController.changeContainerBottomMargin(withNewValue: self.defaultKeyboardHeight, animated: true, callback: {
            self.shouldIgnoreContainerBottomMarginUpdates = false
        })
        let containerView: InputContainerView = {
            let containerView = InputContainerView()
            containerView.allowsSelfSizing = true
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.contentView = inputView
            return containerView
        }()
        containerController.contentContainer.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: containerController.contentContainer.topAnchor),
            containerView.leftAnchor.constraint(equalTo: containerController.contentContainer.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: containerController.contentContainer.rightAnchor),
            containerView.bottomAnchor.constraint(equalTo: containerController.contentContainer.bottomAnchor)
            ])
        self.currentInputView = containerView
    }

    private var lastKnownKeyboardHeight: CGFloat?
    private var allowListenToChangeFrameEvents = true

    // MARK: Input View

    private weak var currentInputView: InputContainerView?

    private var defaultKeyboardHeight: CGFloat {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            return UIScreen.main.defaultPortraitKeyboardHeight
        } else {
            return UIScreen.main.defaultLandscapeKeyboardHeight
        }
    }

    private func expandedInputViewHeight(forItem item: ChatInputItemProtocol) -> CGFloat {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            return UIScreen.main.fixedCoordinateSpace.bounds.height - item.expandedStateTopMargin
        } else {
            return UIScreen.main.fixedCoordinateSpace.bounds.width - item.expandedStateTopMargin
        }
    }

    // MARK: Notifications handling

    @objc
    private func keyboardDidChangeFrame(_ notification: Notification) {
        guard self.allowListenToChangeFrameEvents else { return }
        guard let value = (notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        guard value.cgRectValue.height > 0 else { return }
        self.lastKnownKeyboardHeight = value.cgRectValue.height
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
        self.currentInputView?.contentHeight = self.defaultKeyboardHeight
        self.containerController?.changeContainerBottomMargin(withNewValue: self.defaultKeyboardHeight, animated: true, callback: nil)
    }

    // MARK: Controllers updates handling

    private func subscribeToKeyboardController() {
        self.keyboardAwareController?.onKeyboardLayoutChangeBlock = { [weak self] (_ bottomMargin: CGFloat, _ keyboardStatus: KeyboardStatus) in
            self?.onKeyboardLayoutChange(bottomMargin: bottomMargin, keyboardStatus: keyboardStatus)
        }
    }

    private func onKeyboardLayoutChange(bottomMargin: CGFloat, keyboardStatus: KeyboardStatus) {
        guard let containerController = self.containerController else { return }
        if self.focusedItem == nil || self.focusedItem?.presentationMode == .keyboard {
            containerController.changeContainerBottomMargin(withNewValue: bottomMargin, animated: false, callback: nil)
        } else if let item = self.focusedItem {
            switch keyboardStatus {
            case .shown, .showing:
                containerController.changeContainerBottomMargin(withNewValue: self.expandedInputViewHeight(forItem: item), animated: true, callback: nil)
            case .hidden, .hiding:
                containerController.changeContainerBottomMargin(withNewValue: self.defaultKeyboardHeight, animated: true, callback: nil)
            }
        }
    }

    private func subscribeToScrollController() {
        self.scrollAwareController?.onScrollViewDidEndDraggingBlock = { [weak self] in
            self?.onScrollViewDidEndDragging()
        }
        self.scrollAwareController?.onScrollViewDidScrollBlock = { [weak self] (_ velocity: CGPoint, _ location: CGPoint, _ state: UIGestureRecognizer.State) in
            guard state == .changed else { return }
            self?.onScrollViewDidScroll(velocity: velocity, location: location)
        }
    }

    private func onScrollViewDidEndDragging() {
        guard !self.shouldIgnoreContainerBottomMarginUpdates else { return }
        guard let containerController = self.containerController else { return }
        guard let focusItem = self.focusedItem else { return }
        guard focusItem.presentationMode != .keyboard else { return }
        self.shouldIgnoreContainerBottomMarginUpdates = true
        if 3 * containerController.contentContainerBottomMargin < self.defaultKeyboardHeight {
            let callback: () -> Void = { [weak self] in
                self?.shouldIgnoreContainerBottomMarginUpdates = false
                self?.cleanupFocusedItem(animated: true)
            }
            containerController.changeContainerBottomMargin(withNewValue: 0, animated: true, callback: callback)
        } else {
            let callback: () -> Void = { [weak self] in self?.shouldIgnoreContainerBottomMarginUpdates = false }
            containerController.changeContainerBottomMargin(withNewValue: self.defaultKeyboardHeight, animated: true, callback: callback)
        }
    }

    private func onScrollViewDidScroll(velocity: CGPoint, location: CGPoint) {
        guard !self.shouldIgnoreContainerBottomMarginUpdates else { return }
        guard let containerController = self.containerController else { return }
        guard let focusItem = self.focusedItem else { return }
        guard focusItem.presentationMode != .keyboard else { return }
        self.currentInputView?.endEditing(false)
        if velocity.y > 2500 {
            self.shouldIgnoreContainerBottomMarginUpdates = true
            let callback: () -> Void = { [weak self] in
                self?.shouldIgnoreContainerBottomMarginUpdates = false
                self?.cleanupFocusedItem(animated: true)
            }
            containerController.changeContainerBottomMargin(withNewValue: 0, animated: true, callback: callback)
        } else {
            if location.y > 0 {
                containerController.changeContainerBottomMargin(withNewValue: containerController.contentContainerBottomMargin - location.y, animated: false, callback: nil)
            } else if containerController.contentContainerBottomMargin < self.defaultKeyboardHeight && velocity.y < 0 {
                containerController.changeContainerBottomMargin(withNewValue: min(self.defaultKeyboardHeight, containerController.contentContainerBottomMargin - location.y), animated: false, callback: nil)
            }
            if containerController.contentContainerBottomMargin == 0 {
                self.cleanupFocusedItem(animated: true)
            }
        }
    }

    private func cleanupFocusedItem(animated: Bool = false) {
        self.focusedItem = nil
        self.cleanCurrentInputView(animated: animated) {
            self.onDidEndEditing()
        }
    }

    private func subscribeToControllers() {
        self.subscribeToKeyboardController()
        self.subscribeToScrollController()
    }
}

// MARK: ChatInputBarPresenter
extension ContentAwareChatInputBarPresenter {
    public func onDidEndEditing() {
        if self.focusedItem != nil {
            guard self.focusedItem?.presentationMode == .keyboard else { return }
        }
        self.focusedItem = nil
        self.chatInputBar.textView.inputView = nil
        self.chatInputBar.showsTextView = true
        self.chatInputBar.showsSendButton = true
    }

    public func onDidBeginEditing() {
        if self.focusedItem == nil, let item = self.firstKeyboardInputItem() {
            self.focusedItem = item
            self.updateContentContainer(withInputItem: item)
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
        self.allowListenToChangeFrameEvents = item.presentationMode == .keyboard
        self.updateContentContainer(withInputItem: item)
    }
}
