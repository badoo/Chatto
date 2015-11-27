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

import Foundation

protocol ChatInputItemViewDelegate: class {
    func inputItemViewTapped(view: ChatInputItemView)
}

class ChatInputItemView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    private func commonInit() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap")
        gestureRecognizer.cancelsTouchesInView = false
        self.addGestureRecognizer(gestureRecognizer)
    }

    weak var delegate: ChatInputItemViewDelegate?
    func handleTap() {
        self.delegate?.inputItemViewTapped(self)
    }

    var inputItem: ChatInputItemProtocol! {
        willSet {
            if self.inputItem != nil {
                self.inputItem.tabView.removeFromSuperview()
            }
        }
        didSet {
            if self.inputItem != nil {
                self.addSubview(self.inputItem.tabView)
                self.setNeedsLayout()
            }
        }
    }
}

// MARK: UIView
extension ChatInputItemView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.inputItem.tabView.frame = self.bounds
    }

    override func intrinsicContentSize() -> CGSize {
        return self.inputItem.tabView.intrinsicContentSize()
    }
}
