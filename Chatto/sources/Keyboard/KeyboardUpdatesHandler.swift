//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import UIKit

public protocol KeyboardUpdatesHandlerProtocol: AnyObject {
    var keyboardInfo: Observable<KeyboardUpdatesInfo> { get }
    var keyboardInputAdjustableViewController: UIViewController? { get set }
    var keyboardTrackingView: UIView { get }

    func startTracking()
    func stopTracking()
}

public protocol KeyboardUpdatesHandlerDelegate: AnyObject {
    func didAdjustBottomMargin(to margin: CGFloat, state: KeyboardState)
}

public struct KeyboardUpdatesInfo {
    public let bottomMargin: CGFloat
    public let state: KeyboardState

    public init(bottomMargin: CGFloat, state: KeyboardState) {
        self.bottomMargin = bottomMargin
        self.state = state
    }
}

public final class KeyboardUpdatesHandler: KeyboardUpdatesHandlerProtocol {
    private let keyboardTracker: KeyboardTrackerProtocol

    private var isTracking: Bool
    private var isPerformingForcedLayout: Bool

    public var keyboardTrackingView: UIView { self._keyboardTrackingView }
    private lazy var _keyboardTrackingView: KeyboardTrackingView = self.makeTrackingView()

    public private(set) var keyboardInfo: Observable<KeyboardUpdatesInfo>// DelegateStore<KeyboardUpdatesHandlerDelegate>
    public weak var keyboardInputAdjustableViewController: UIViewController?

    private var keyboardState: KeyboardState {
        return self.keyboardTracker.keyboardStatus.state
    }

    public init(keyboardTracker: KeyboardTrackerProtocol) {
        self.keyboardTracker = keyboardTracker

        self.keyboardInfo = .init(
            KeyboardUpdatesInfo(bottomMargin: 0, state: keyboardTracker.keyboardStatus.state)
        )
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

    private func makeTrackingView() -> KeyboardTrackingView {
        let trackingView = KeyboardTrackingView()
        trackingView.positionChangedCallback = { [weak self] in
            guard let sSelf = self else { return }
            guard !sSelf.isPerformingForcedLayout else { return }

            sSelf.adjustLayoutInputAtTrackingViewIfNeeded()
        }

        return trackingView
    }

    private func adjustLayoutInputAtTrackingViewIfNeeded() {
        guard self.isTracking && self.keyboardState == .shown else { return }

        self.layoutInputContainer(withBottomConstraint: self.calculateBottomConstraintFromTrackingView())
    }
}

extension KeyboardUpdatesHandler: KeyboardTrackerDelegate {
    public func didUpdate(keyboardStatus: KeyboardStatus) {
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


            self.keyboardInfo.value = KeyboardUpdatesInfo(bottomMargin: bottomConstraintValue, state: self.keyboardState)
        case .shown:
            guard bottomConstraintValue > 0,
                  !self.isPerformingForcedLayout else { return }

            self.keyboardInfo.value = KeyboardUpdatesInfo(bottomMargin: bottomConstraintValue, state: self.keyboardState)
        }
    }

    private func bottomConstraintValue(for keyboardFrame: CGRect,
                                      keyboardInputAdjustableViewController: UIViewController) -> CGFloat {
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

        self.keyboardInfo.value = KeyboardUpdatesInfo(bottomMargin: bottomConstraint, state: self.keyboardState)
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
