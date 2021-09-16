//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//
import UIKit

public protocol KeyboardUpdatesAnimatorProtocol {
    func configure(for KeyboardInputAdjustableViewController: KeyboardInputAdjustableViewController)
    func adjustInputContentBottomMarginTo(_ newValue: CGFloat)
}

public final class StaticKeyboardUpdatesAnimator: KeyboardUpdatesAnimatorProtocol {

    private let inputContainerBottomBaseOffset: CGFloat

    private weak var KeyboardInputAdjustableViewController: KeyboardInputAdjustableViewController?

    public init(inputContainerBottomBaseOffset: CGFloat) {
        self.inputContainerBottomBaseOffset = inputContainerBottomBaseOffset
    }

    public func configure(for KeyboardInputAdjustableViewController: KeyboardInputAdjustableViewController) {
        self.KeyboardInputAdjustableViewController = KeyboardInputAdjustableViewController
    }

    public func adjustInputContentBottomMarginTo(_ newValue: CGFloat) {
        guard let KeyboardInputAdjustableViewController = self.KeyboardInputAdjustableViewController else { return }

        let viewControllerBottomConstraint = KeyboardInputAdjustableViewController.inputContainerBottomConstraint
        viewControllerBottomConstraint.constant = max(
            self.inputContainerBottomBaseOffset, newValue
        )

        KeyboardInputAdjustableViewController.view.setNeedsLayout()
        KeyboardInputAdjustableViewController.view.layoutIfNeeded()
    }
}
