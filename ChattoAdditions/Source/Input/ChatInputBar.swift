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

@objc public protocol ChatInputBarDelegate: class {
    optional func inputBarShouldBeginTextEditing(inputBar: ChatInputBar) -> Bool
    optional func inputBarShouldEndTextEditing(inputBar: ChatInputBar) -> Bool
    optional func inputBarDidBeginEditing(inputBar: ChatInputBar)
    optional func inputBarDidEndEditing(inputBar: ChatInputBar)
    optional func inputBarDidChangeText(inputBar: ChatInputBar)
    optional func inputBarSendButtonPressed(inputBar: ChatInputBar)
}


/// all methods defined in RequiredChatInputBarDelegate must be implemented.
public protocol RequiredChatInputBarDelegate: class {
    func inputBar(inputBar: ChatInputBar, shouldFocusOnItem item: ChatInputItemProtocol) -> Bool
    func inputBar(inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol)
}

@objc
public class ChatInputBar: ReusableXibView {

    public weak var delegate: ChatInputBarDelegate?
    public weak var requiredDelegate: RequiredChatInputBarDelegate?
    weak var presenter: ChatInputBarPresenter?

    public var shouldEnableSendButton = { (inputBar: ChatInputBar) -> Bool in
        return !inputBar.textView.text.isEmpty
    }

    // enable press the return key to send message		
    public var enableReturnKeyToSend: Bool = false

    @IBOutlet weak var scrollView: HorizontalStackScrollView!
    @IBOutlet weak var textView: ExpandableTextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var topBorderHeightConstraint: NSLayoutConstraint!

    @IBOutlet var constraintsForHiddenTextView: [NSLayoutConstraint]!
    @IBOutlet var constraintsForVisibleTextView: [NSLayoutConstraint]!

    @IBOutlet var constraintsForVisibleSendButton: [NSLayoutConstraint]!
    @IBOutlet var constraintsForHiddenSendButton: [NSLayoutConstraint]!
    @IBOutlet var tabBarContainerHeightConstraint: NSLayoutConstraint!

    class public func loadNib() -> ChatInputBar {
        let view = NSBundle(forClass: self).loadNibNamed(self.nibName(), owner: nil, options: nil)!.first as! ChatInputBar
        view.translatesAutoresizingMaskIntoConstraints = false
        view.frame = CGRect.zero
        return view
    }

    override class func nibName() -> String {
        return "ChatInputBar"
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        self.topBorderHeightConstraint.constant = 1 / UIScreen.mainScreen().scale
        self.textView.scrollsToTop = false
        self.textView.delegate = self
        self.scrollView.scrollsToTop = false
        self.sendButton.enabled = false
    }

    public override func updateConstraints() {
        if self.showsTextView {
            NSLayoutConstraint.activateConstraints(self.constraintsForVisibleTextView)
            NSLayoutConstraint.deactivateConstraints(self.constraintsForHiddenTextView)
        } else {
            NSLayoutConstraint.deactivateConstraints(self.constraintsForVisibleTextView)
            NSLayoutConstraint.activateConstraints(self.constraintsForHiddenTextView)
        }
        if self.showsSendButton {
            NSLayoutConstraint.deactivateConstraints(self.constraintsForHiddenSendButton)
            NSLayoutConstraint.activateConstraints(self.constraintsForVisibleSendButton)
        } else {
            NSLayoutConstraint.deactivateConstraints(self.constraintsForVisibleSendButton)
            NSLayoutConstraint.activateConstraints(self.constraintsForHiddenSendButton)
        }
        super.updateConstraints()
    }

    public var showsTextView: Bool = true {
        didSet {
            self.setNeedsUpdateConstraints()
            self.setNeedsLayout()
            self.updateIntrinsicContentSizeAnimated()
        }
    }

    public var showsSendButton: Bool = true {
        didSet {
            self.setNeedsUpdateConstraints()
            self.setNeedsLayout()
            self.updateIntrinsicContentSizeAnimated()
        }
    }

    public var maxCharactersCount: UInt? // nil -> unlimited

    private func updateIntrinsicContentSizeAnimated() {
        let options: UIViewAnimationOptions = [.BeginFromCurrentState, .AllowUserInteraction, .CurveEaseInOut]
        UIView.animateWithDuration(0.25, delay: 0, options: options, animations: { () -> Void in
            self.invalidateIntrinsicContentSize()
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
        }, completion: nil)
    }

    public override func layoutSubviews() {
        self.updateConstraints() // Interface rotation or size class changes will reset constraints as defined in interface builder -> constraintsForVisibleTextView will be activated
        super.layoutSubviews()
    }

    var inputItems = [ChatInputItemProtocol]() {
        didSet {
            let inputItemViews = self.inputItems.map { (item: ChatInputItemProtocol) -> ChatInputItemView in
                let inputItemView = ChatInputItemView()
                inputItemView.inputItem = item
                inputItemView.delegate = self
                return inputItemView
            }
            self.scrollView.addArrangedViews(inputItemViews)
        }
    }

    public func becomeFirstResponderWithInputView(inputView: UIView?) {
        self.textView.inputView = inputView

        if self.textView.isFirstResponder() {
            self.textView.reloadInputViews()
        } else {
            self.textView.becomeFirstResponder()
        }
    }

    public var inputText: String {
        get {
            return self.textView.text
        }
        set {
            self.textView.text = newValue
            self.updateSendButton()
        }
    }

    private func updateSendButton() {
        self.sendButton.enabled = self.shouldEnableSendButton(self)
    }

    @IBAction func buttonTapped(sender: AnyObject) {
        self.presenter?.onSendButtonPressed()
        self.delegate?.inputBarSendButtonPressed?(self)
    }

    public func setTextViewPlaceholderAccessibilityIdentifer(accessibilityIdentifer: String) {
        self.textView.setTextPlaceholderAccessibilityIdentifier(accessibilityIdentifer)
    }
}

// MARK: - ChatInputItemViewDelegate
extension ChatInputBar: ChatInputItemViewDelegate {
    func inputItemViewTapped(view: ChatInputItemView) {
        self.focusOnInputItem(view.inputItem)
    }

    public func focusOnInputItem(inputItem: ChatInputItemProtocol) {
        let shouldFocus = self.requiredDelegate?.inputBar(self, shouldFocusOnItem: inputItem) ?? true
        guard shouldFocus else { return }

        self.presenter?.onDidReceiveFocusOnItem(inputItem)
        self.requiredDelegate?.inputBar(self, didReceiveFocusOnItem: inputItem)
    }
}

// MARK: - ChatInputBarAppearance
extension ChatInputBar {
    public func setAppearance(appearance: ChatInputBarAppearance) {
        self.textView.font = appearance.textInputAppearance.font
        self.textView.textColor = appearance.textInputAppearance.textColor
        self.textView.textContainerInset = appearance.textInputAppearance.textInsets
        self.textView.setTextPlaceholderFont(appearance.textInputAppearance.placeholderFont)
        self.textView.setTextPlaceholderColor(appearance.textInputAppearance.placeholderColor)
        self.textView.setTextPlaceholder(appearance.textInputAppearance.placeholderText)

        if enableReturnKeyToSend {        
            self.textView.returnKeyType = .Send        
            self.textView.enablesReturnKeyAutomatically = true        
        }

        self.tabBarInterItemSpacing = appearance.tabBarAppearance.interItemSpacing
        self.tabBarContentInsets = appearance.tabBarAppearance.contentInsets

        self.sendButton.contentEdgeInsets = appearance.sendButtonAppearance.insets
        self.sendButton.setTitle(appearance.sendButtonAppearance.title, forState: .Normal)
        appearance.sendButtonAppearance.titleColors.forEach { (state, color) in
            self.sendButton.setTitleColor(color, forState: state.controlState)
        }
        self.sendButton.titleLabel?.font = appearance.sendButtonAppearance.font

        self.tabBarContainerHeightConstraint.constant = appearance.tabBarAppearance.height
    }
}

extension ChatInputBar { // Tabar
    public var tabBarInterItemSpacing: CGFloat {
        get {
            return self.scrollView.interItemSpacing
        }
        set {
            self.scrollView.interItemSpacing = newValue
        }
    }

    public var tabBarContentInsets: UIEdgeInsets {
        get {
            return self.scrollView.contentInset
        }
        set {
            self.scrollView.contentInset = newValue
        }
    }
}

// MARK: UITextViewDelegate
extension ChatInputBar: UITextViewDelegate {
    public func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return self.delegate?.inputBarShouldBeginTextEditing?(self) ?? true
    }
    
    public func textViewShouldEndEditing(textView: UITextView) -> Bool {
        return self.delegate?.inputBarShouldEndTextEditing?(self) ?? true
    }

    public func textViewDidEndEditing(textView: UITextView) {
        self.presenter?.onDidEndEditing()
        self.delegate?.inputBarDidEndEditing?(self)
    }

    public func textViewDidBeginEditing(textView: UITextView) {
        self.presenter?.onDidBeginEditing()
        self.delegate?.inputBarDidBeginEditing?(self)
    }

    public func textViewDidChange(textView: UITextView) {
        self.updateSendButton()
        self.delegate?.inputBarDidChangeText?(self)
    }

    public func textView(textView: UITextView, shouldChangeTextInRange nsRange: NSRange, replacementText text: String) -> Bool {
        if self.enableReturnKeyToSend && text.containsString("\n") {        
            self.presenter?.onSendButtonPressed()        
            return false        
        }

        let range = self.textView.text.bma_rangeFromNSRange(nsRange)
        if let maxCharactersCount = self.maxCharactersCount {
            let currentCount = textView.text.characters.count
            let rangeLength = textView.text.substringWithRange(range).characters.count
            let nextCount = currentCount - rangeLength + text.characters.count
            return UInt(nextCount) <= maxCharactersCount
        }
        return true
    }
}

private extension String {
    func bma_rangeFromNSRange(nsRange: NSRange) -> Range<String.Index> {
        let from16 = self.utf16.startIndex.advancedBy(nsRange.location, limit: self.utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: self.utf16.endIndex)
        if let from = String.Index(from16, within: self), to = String.Index(to16, within: self) {
            return from ..< to
        }
        return self.startIndex...self.startIndex
    }
}
