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

public protocol ExpandableTextViewPlaceholderDelegate: class {
    func expandableTextViewDidShowPlaceholder(_ textView: ExpandableTextView)
    func expandableTextViewDidHidePlaceholder(_ textView: ExpandableTextView)
}

open class ExpandableTextView: UITextView {

    private let placeholder: UITextView = UITextView()
    public weak var placeholderDelegate: ExpandableTextViewPlaceholderDelegate?

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.commonInit()
    }

    override open var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.layoutIfNeeded() // needed?
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(ExpandableTextView.textDidChange), name: NSNotification.Name.UITextViewTextDidChange, object: self)
        self.configurePlaceholder()
        self.updatePlaceholderVisibility()
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()

        if self.isPlaceholderViewAttached {
            self.placeholderDelegate?.expandableTextViewDidShowPlaceholder(self)
        } else {
            self.placeholderDelegate?.expandableTextViewDidHidePlaceholder(self)
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        self.placeholder.frame = self.bounds
    }

    override open var intrinsicContentSize: CGSize {
        return self.contentSize
    }

    override open var text: String! {
        didSet {
            self.textDidChange()
        }
    }

    open var placeholderText: String {
        get {
            return self.placeholder.text
        }
        set {
            self.placeholder.text = newValue
        }
    }

    override open var textContainerInset: UIEdgeInsets {
        didSet {
            self.configurePlaceholder()
        }
    }

    override open var textAlignment: NSTextAlignment {
        didSet {
            self.configurePlaceholder()
        }
    }

    @available(*, deprecated, message: "use placeholderText property instead")
    open func setTextPlaceholder(_ textPlaceholder: String) {
        self.placeholder.text = textPlaceholder
    }

    open func setTextPlaceholderColor(_ color: UIColor) {
        self.placeholder.textColor = color
    }

    open func setTextPlaceholderFont(_ font: UIFont) {
        self.placeholder.font = font
    }

    open func setTextPlaceholderAccessibilityIdentifier(_ accessibilityIdentifier: String) {
        self.placeholder.accessibilityIdentifier = accessibilityIdentifier
    }

    @objc func textDidChange() {
        self.updatePlaceholderVisibility()
        self.scrollToCaret()

        if #available(iOS 9, *) {
            // Bugfix:
            // 1. Open keyboard
            // 2. Paste very long text (so it snaps to nav bar and shows scroll indicators)
            // 3. Select all and cut
            // 4. Paste again: Texview it's smaller than it should be
            self.isScrollEnabled = false
            self.isScrollEnabled = true
        }
    }

    private func scrollToCaret() {
        if let textRange = self.selectedTextRange {
            var rect = caretRect(for: textRange.end)
            rect = CGRect(origin: rect.origin, size: CGSize(width: rect.width, height: rect.height + textContainerInset.bottom))

            self.scrollRectToVisible(rect, animated: false)
        }
    }

    private func updatePlaceholderVisibility() {
        if self.text == "" {
            self.showPlaceholder()
        } else {
            self.hidePlaceholder()
        }
    }

    private func showPlaceholder() {
        let wasAttachedBeforeShowing = self.isPlaceholderViewAttached
        self.addSubview(self.placeholder)

        if !wasAttachedBeforeShowing {
            self.placeholderDelegate?.expandableTextViewDidShowPlaceholder(self)
        }
    }

    private func hidePlaceholder() {
        let wasAttachedBeforeHiding = self.isPlaceholderViewAttached
        self.placeholder.removeFromSuperview()

        if wasAttachedBeforeHiding {
            self.placeholderDelegate?.expandableTextViewDidHidePlaceholder(self)
        }
    }

    private var isPlaceholderViewAttached: Bool {
        return self.placeholder.superview != nil
    }

    private func configurePlaceholder() {
        self.placeholder.translatesAutoresizingMaskIntoConstraints = false
        self.placeholder.isEditable = false
        self.placeholder.isSelectable = false
        self.placeholder.isUserInteractionEnabled = false
        self.placeholder.textAlignment = self.textAlignment
        self.placeholder.textContainerInset = self.textContainerInset
        self.placeholder.backgroundColor = UIColor.clear
    }
}
