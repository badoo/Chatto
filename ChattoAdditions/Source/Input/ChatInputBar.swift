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

protocol ChatInputBarDelegate: class {
    func inputBarDidBeginEditing(inputBar: ChatInputBar)
    func inputBarDidEndEditing(inputBar: ChatInputBar)
    func inputBarSendButtonPressed(inputBar: ChatInputBar)
    func inputBar(inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol)
}

@objc
public class ChatInputBar: ReusableXibView {

    weak var delegate: ChatInputBarDelegate?

    @IBOutlet weak var scrollView: HorizontalStackScrollView!
    @IBOutlet weak var textView: ExpandableTextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var topBorderHeightConstraint: NSLayoutConstraint!

    @IBOutlet var constraintsForHiddenTextView: [NSLayoutConstraint]!
    @IBOutlet var constraintsForVisibleTextView: [NSLayoutConstraint]!

    @IBOutlet var constraintsForVisibleSendButton: [NSLayoutConstraint]!
    @IBOutlet var constraintsForHiddenSendButton: [NSLayoutConstraint]!

    class public func loadNib() -> ChatInputBar {
        let view = NSBundle(forClass: self).loadNibNamed(self.nibName(), owner: nil, options: nil).first as! ChatInputBar
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
            self.sendButton.enabled = !self.textView.text.isEmpty
        }
    }

    @IBAction func buttonTapped(sender: AnyObject) {
        self.delegate?.inputBarSendButtonPressed(self)
        self.inputText = ""
    }
}

// MARK: - ChatInputItemViewDelegate
extension ChatInputBar: ChatInputItemViewDelegate {
    func inputItemViewTapped(view: ChatInputItemView) {
        self.delegate?.inputBar(self, didReceiveFocusOnItem: view.inputItem)
    }
}

// MARK: - ChatInputBarAppearance
extension ChatInputBar {
    public func setAppearance(appearance: ChatInputBarAppearance) {
        self.textView.font = appearance.textFont
        self.textView.textColor = appearance.textColor
        self.textView.setTextPlaceholderFont(appearance.textPlaceholderFont)
        self.textView.setTextPlaceholderColor(appearance.textPlaceholderColor)
        self.textView.setTextPlaceholder(appearance.textPlaceholder)
        self.sendButton.setTitle(appearance.sendButtonTitle, forState: .Normal)
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
    public func textViewDidEndEditing(textView: UITextView) {
        self.delegate?.inputBarDidEndEditing(self)
    }

    public func textViewDidBeginEditing(textView: UITextView) {
        self.delegate?.inputBarDidBeginEditing(self)
    }

    public func textViewDidChange(textView: UITextView) {
        self.sendButton.enabled = !textView.text.isEmpty
    }
}

class SingleViewContainerView: UIView {
    override func intrinsicContentSize() -> CGSize {
        if let subview = self.subviews.first {
            return subview.intrinsicContentSize()
        } else {
            return CGSize.zero
        }
    }

}
