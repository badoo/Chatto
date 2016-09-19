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

public class ExpandableTextView: UITextView {

    private let placeholder: UITextView = UITextView()

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.commonInit()
    }

    override public var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.layoutIfNeeded() // needed?
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private func commonInit() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ExpandableTextView.textDidChange), name: UITextViewTextDidChangeNotification, object: self)
        self.configurePlaceholder()
        self.updatePlaceholderVisibility()
    }


    override public func layoutSubviews() {
        super.layoutSubviews()
        self.placeholder.frame = self.bounds
    }

    override public func intrinsicContentSize() -> CGSize {
        return self.contentSize
    }

    override public var text: String! {
        didSet {
            self.textDidChange()
        }
    }

    override public var textContainerInset: UIEdgeInsets {
        didSet {
            self.configurePlaceholder()
        }
    }

    override public var textAlignment: NSTextAlignment {
        didSet {
            self.configurePlaceholder()
        }
    }

    public func setTextPlaceholder(textPlaceholder: String) {
        self.placeholder.text = textPlaceholder
    }

    public func setTextPlaceholderColor(color: UIColor) {
        self.placeholder.textColor = color
    }

    public func setTextPlaceholderFont(font: UIFont) {
        self.placeholder.font = font
    }

    public func setTextPlaceholderAccessibilityIdentifier(accessibilityIdentifier: String) {
        self.placeholder.accessibilityIdentifier = accessibilityIdentifier
    }

    func textDidChange() {
        self.updatePlaceholderVisibility()
        self.scrollToCaret()

        if #available(iOS 9, *) {
            // Bugfix:
            // 1. Open keyboard
            // 2. Paste very long text (so it snaps to nav bar and shows scroll indicators)
            // 3. Select all and cut
            // 4. Paste again: Texview it's smaller than it should be
            self.scrollEnabled = false
            self.scrollEnabled = true
        }
    }

    private func scrollToCaret() {
        if let textRange = self.selectedTextRange {
            var rect = caretRectForPosition(textRange.end)
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
        self.addSubview(self.placeholder)
    }

    private func hidePlaceholder() {
        self.placeholder.removeFromSuperview()
    }

    private func configurePlaceholder() {
        self.placeholder.translatesAutoresizingMaskIntoConstraints = false
        self.placeholder.editable = false
        self.placeholder.selectable = false
        self.placeholder.userInteractionEnabled = false
        self.placeholder.textAlignment = self.textAlignment
        self.placeholder.textContainerInset = self.textContainerInset
        self.placeholder.backgroundColor = UIColor.clearColor()
    }
}
