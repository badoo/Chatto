//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//
import UIKit

public protocol KeyboardInputAdjustableViewController: UIViewController {
    var inputBarContainer: UIView { get }
    var inputContainerBottomConstraint: NSLayoutConstraint { get }
}

public protocol KeyboardUpdatesHandlerProtocol {
    var keyboardTrackingView: KeyboardTrackingView { get }

    func adjustLayoutIfNeeded()
    func startTracking()
    func stopTracking()
}

public protocol KeyboardUpdatesHandlerDelegate: AnyObject {
    func onKeyboardStateDidChange(_ height: CGFloat, _ status: KeyboardStatus)
}

public final class KeyboardUpdatesHandler: KeyboardUpdatesHandlerProtocol {
    private let keyboardTracker: KeyboardTrackerProtocol

    private var isTracking: Bool
    private var isPerformingForcedLayout: Bool

    public private(set) lazy var keyboardTrackingView: KeyboardTrackingView = self.makeTrackingView()

    public weak var delegate: KeyboardUpdatesHandlerDelegate?
    public weak var keyboardInputAdjustableViewController: KeyboardInputAdjustableViewController?

    public init(keyboardTracker: KeyboardTrackerProtocol) {
        self.keyboardTracker = keyboardTracker

        self.isTracking = false
        self.isPerformingForcedLayout = false

        keyboardTracker.delegate = self
    }

    public func startTracking() {
        self.isTracking = true
    }

    public func stopTracking() {
        self.isTracking = false
    }

    public func adjustLayoutIfNeeded() {
        self.adjustTrackingViewSizeIfNeeded()
    }

    private func makeTrackingView() -> KeyboardTrackingView {
        let trackingView = KeyboardTrackingView()
        trackingView.positionChangedCallback = { [weak self] in
            guard let sSelf = self else { return }
            guard !sSelf.isPerformingForcedLayout else { return }

            sSelf.adjustLayoutInputAtTrackingViewIfNeeded()
        }

        return trackingView
    }

    private func adjustTrackingViewSizeIfNeeded() {
        guard self.isTracking && self.keyboardTracker.keyboardStatus.state == .shown else { return }

        self.adjustTrackingViewSize()
    }

    private func adjustLayoutInputAtTrackingViewIfNeeded() {
        guard self.isTracking && self.keyboardTracker.keyboardStatus.state == .shown else { return }

        self.layoutInputContainer(withBottomConstraint: self.calculateBottomConstraintFromTrackingView())
    }
}

extension KeyboardUpdatesHandler: KeyboardTrackerDelegate {
    public func keyboardTracker(_: KeyboardTrackerProtocol,
                                didUpdateTo keyboardStatus: KeyboardStatus) {
        guard self.isTracking else { return }

        guard let keyboardInputAdjustableViewController = self.keyboardInputAdjustableViewController else {
            return
        }

        let bottomConstraintValue = self.bottomConstraintValue(
            for: keyboardStatus.frame,
            keyboardInputAdjustableViewController: keyboardInputAdjustableViewController
        )

        switch keyboardStatus.state {
        case .hidden:
            self.layoutInputAtBottom()
        case .hiding:
            self.layoutInputAtBottom()
        case .showing:
            guard bottomConstraintValue > 0,
                  !self.isPerformingForcedLayout else { return }

            self.delegate?.onKeyboardStateDidChange(bottomConstraintValue, self.keyboardTracker.keyboardStatus)
        case .shown:
            guard bottomConstraintValue > 0,
                  !self.isPerformingForcedLayout else { return }

            self.delegate?.onKeyboardStateDidChange(bottomConstraintValue, self.keyboardTracker.keyboardStatus)
            self.adjustTrackingViewSizeIfNeeded()
        }
    }

    private func bottomConstraintValue(for keyboardFrame: CGRect,
                                      keyboardInputAdjustableViewController: KeyboardInputAdjustableViewController) -> CGFloat {
        let rectInView = keyboardInputAdjustableViewController.view.convert(keyboardFrame, from: nil)

        guard keyboardFrame.height > 0 else { return 0 }
        guard rectInView.maxY >=~ keyboardInputAdjustableViewController.view.bounds.height else { return 0 } // Undocked keyboard
        let adjustedBottomConstraint = keyboardInputAdjustableViewController.view.bounds.height
            - rectInView.minY
            - self.keyboardTrackingView.intrinsicContentSize.height

        return max(0, adjustedBottomConstraint)
    }

    private func layoutInputAtBottom() {
        self.keyboardTrackingView.bounds.size.height = 0

        self.layoutInputContainer(withBottomConstraint: 0)
    }

    private func layoutInputContainer(withBottomConstraint bottomConstraint: CGFloat) {
        self.isPerformingForcedLayout = true
        defer { self.isPerformingForcedLayout = false }

        self.delegate?.onKeyboardStateDidChange(bottomConstraint, self.keyboardTracker.keyboardStatus)
    }

    private func adjustTrackingViewSize() {
        guard let keyboardInputAdjustableViewController = self.keyboardInputAdjustableViewController else { return }

        let inputBarContainerView = keyboardInputAdjustableViewController.inputBarContainer
        let inputBarContainerViewHeight = inputBarContainerView.bounds.height
        guard self.keyboardTrackingView.preferredSize.height != inputBarContainerViewHeight else {
            return
        }

        self.keyboardTrackingView.preferredSize.height = inputBarContainerViewHeight
        self.isPerformingForcedLayout = true
        defer { self.isPerformingForcedLayout = false }

        // Sometimes, the autolayout system doesn't finish the layout inside of the input bar container at this point.
        // If it happens, then the input bar may have a height different than an input bar container.
        // We need to ensure that their heights are the same; otherwise, it would lead to incorrect calculations that in turn affects lastKnownKeyboardHeight.
        // Tracking view adjustment changes a keyboard height and triggers an update of lastKnownKeyboardHeight.
        inputBarContainerView.layoutIfNeeded()
        self.keyboardTrackingView.window?.layoutIfNeeded()
    }

    private func calculateBottomConstraintFromTrackingView() -> CGFloat {
        guard self.keyboardTrackingView.superview != nil else { return 0 }
        guard let keyboardInputAdjustableViewController = self.keyboardInputAdjustableViewController else { return 0 }

        let trackingViewRect = keyboardInputAdjustableViewController.view.convert(
            self.keyboardTrackingView.bounds,
            from: self.keyboardTrackingView
        )

        return max(0, keyboardInputAdjustableViewController.view.bounds.height - trackingViewRect.maxY)
    }
}
