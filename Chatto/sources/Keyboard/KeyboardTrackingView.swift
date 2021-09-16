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

public final class KeyboardTrackingView: UIView {

    var positionChangedCallback: (() -> Void)?
    var observedView: UIView?

    deinit {
        if let observedView = self.observedView {
            observedView.removeObserver(self, forKeyPath: "frame")
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        self.autoresizingMask = .flexibleHeight
        self.isUserInteractionEnabled = false
        self.backgroundColor = UIColor.clear
        self.isHidden = true
    }

    var preferredSize: CGSize = .zero {
        didSet {
            if oldValue != self.preferredSize {
                self.invalidateIntrinsicContentSize()
                self.window?.setNeedsLayout()
            }
        }
    }

    public override var intrinsicContentSize: CGSize {
        return self.preferredSize
    }

    public override func didMoveToSuperview() {
        if let observedView = self.observedView {
            observedView.removeObserver(self, forKeyPath: "center")
            self.observedView = nil
        }

        if let newSuperview = self.superview {
            newSuperview.addObserver(self, forKeyPath: "center", options: [.new, .old], context: nil)
            self.observedView = newSuperview
        }

        super.didMoveToSuperview()
    }

    public override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let object = object as? UIView, let superview = self.superview else { return }
        if object === superview {
            guard let sChange = change else { return }
            let oldCenter = (sChange[NSKeyValueChangeKey.oldKey] as! NSValue).cgPointValue
            let newCenter = (sChange[NSKeyValueChangeKey.newKey] as! NSValue).cgPointValue
            if oldCenter != newCenter {
                self.positionChangedCallback?()
            }
        }
    }
}
