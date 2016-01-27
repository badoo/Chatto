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

class KeyboardTracker {

    private enum KeyboardStatus {
        case Hidden
        case Showing
        case Shown
    }

    private var keyboardStatus: KeyboardStatus = .Hidden
    private let view: UIView
    private let inputContainerBottomConstraint: NSLayoutConstraint
    var trackingView: UIView {
        return self.keyboardTrackerView
    }
    private lazy var keyboardTrackerView: KeyboardTrackingView = {
        let trackingView = KeyboardTrackingView()
        trackingView.positionChangedCallback = { [weak self] in
            self?.layoutInputAtTrackingViewIfNeeded()
        }
        return trackingView
    }()

    var isTracking = false
    var inputContainer: UIView
    private var notificationCenter: NSNotificationCenter

    init(viewController: UIViewController, inputContainer: UIView, inputContainerBottomContraint: NSLayoutConstraint, notificationCenter: NSNotificationCenter) {
        self.view = viewController.view
        self.inputContainer = inputContainer
        self.inputContainerBottomConstraint = inputContainerBottomContraint
        self.notificationCenter = notificationCenter
        self.notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
    }

    deinit {
        self.notificationCenter.removeObserver(self)
    }

    func startTracking() {
        self.isTracking = true
    }

    func stopTracking() {
        self.isTracking = false
    }

    @objc
    private func keyboardWillShow(notification: NSNotification) {
        guard self.isTracking else { return }
        let bottomConstraint = self.bottomConstraintFromNotification(notification)
        guard bottomConstraint > 0 else { return } // Some keyboards may report initial willShow/DidShow notifications with invalid positions
        self.keyboardStatus = .Showing
        self.inputContainerBottomConstraint.constant = bottomConstraint
        self.view.layoutIfNeeded()
        self.adjustTrackingViewSizeIfNeeded()
    }

    @objc
    private func keyboardDidShow(notification: NSNotification) {
        guard self.isTracking else { return }
        let bottomConstraint = self.bottomConstraintFromNotification(notification)
        guard bottomConstraint > 0 else { return } // Some keyboards may report initial willShow/DidShow notifications with invalid positions
        self.keyboardStatus = .Shown
        self.inputContainerBottomConstraint.constant = bottomConstraint
        self.view.layoutIfNeeded()
        self.layoutTrackingViewIfNeeded()
    }

    @objc
    private func keyboardWillChangeFrame(notification: NSNotification) {
        guard self.isTracking else { return }
        let bottomConstraint = self.bottomConstraintFromNotification(notification)
        if bottomConstraint == 0 {
            self.keyboardStatus = .Hidden
            self.layoutInputAtBottom()
        }
    }

    @objc
    private func keyboardWillHide(notification: NSNotification) {
        guard self.isTracking else { return }
        self.keyboardStatus = .Hidden
        self.layoutInputAtBottom()
    }

    private func bottomConstraintFromNotification(notification: NSNotification) -> CGFloat {
        guard let rect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() else { return 0 }
        guard rect.height > 0 else { return 0 }
        let rectInView = self.view.convertRect(rect, fromView: nil)
        guard rectInView.maxY >= self.view.bounds.height else { return 0 } // Undocked keyboard
        return max(0, self.view.bounds.height - rectInView.minY - self.trackingView.bounds.height)
    }

    private func bottomConstraintFromTrackingView() -> CGFloat {
        let trackingViewRect = self.view.convertRect(self.keyboardTrackerView.bounds, fromView: self.keyboardTrackerView)
        return  self.view.bounds.height - trackingViewRect.maxY
    }

    func layoutTrackingViewIfNeeded() {
        guard self.isTracking && self.keyboardStatus == .Shown else { return }
        self.adjustTrackingViewSizeIfNeeded()
    }

    private func adjustTrackingViewSizeIfNeeded() {
        let inputContainerHeight = self.inputContainer.bounds.height
        let trackerViewHeight = self.trackingView.bounds.height
        if trackerViewHeight != inputContainerHeight {
            self.keyboardTrackerView.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: self.keyboardTrackerView.bounds.width, height: inputContainerHeight))
        }
    }

    private func layoutInputAtBottom() {
        self.keyboardTrackerView.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: self.keyboardTrackerView.bounds.width, height: 0))
        self.inputContainerBottomConstraint.constant = 0
        self.view.layoutIfNeeded()
    }

    func layoutInputAtTrackingViewIfNeeded() {
        guard self.isTracking && self.keyboardStatus == .Shown else { return }
        let newBottomConstraint = self.bottomConstraintFromTrackingView()
        self.inputContainerBottomConstraint.constant = newBottomConstraint
        self.view.layoutIfNeeded()
    }
}

private class KeyboardTrackingView: UIView {

    var positionChangedCallback: (() -> Void)?
    var observedView: UIView?

    deinit {
        if let observedView = self.observedView {
            observedView.removeObserver(self, forKeyPath: "center")
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

    private func commonInit() {
        self.autoresizingMask = .FlexibleHeight
        self.userInteractionEnabled = false
        self.backgroundColor = UIColor.clearColor()
        self.hidden = true
    }

    override var bounds: CGRect {
        didSet {
            if oldValue.size != self.bounds.size {
                self.invalidateIntrinsicContentSize()
            }
        }
    }

    private override func intrinsicContentSize() -> CGSize {
        return self.bounds.size
    }

    override func willMoveToSuperview(newSuperview: UIView?) {
        if let observedView = self.observedView {
            observedView.removeObserver(self, forKeyPath: "center")
            self.observedView = nil
        }

        if let newSuperview = newSuperview {
            newSuperview.addObserver(self, forKeyPath: "center", options: [.New, .Old], context: nil)
            self.observedView = newSuperview
        }

        super.willMoveToSuperview(newSuperview)
    }

    private override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let object = object, superview = self.superview else { return }
        if object === superview {
            guard let sChange = change else { return }
            let oldCenter = (sChange[NSKeyValueChangeOldKey] as! NSValue).CGPointValue()
            let newCenter = (sChange[NSKeyValueChangeNewKey] as! NSValue).CGPointValue()
            if oldCenter != newCenter {
                self.positionChangedCallback?()
            }
        }
    }
}
