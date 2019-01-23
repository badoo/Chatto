//
//  BaseChatViewController+InputPositionControlling.swift
//  Chatto
//
//  Created by Mikhail Gasanov on 23/01/2019.
//

import Foundation

extension BaseChatViewController: InputPositionControlling {

    public var maximumInputSize: CGSize {
        return self.view.bounds.size
    }

    open var inputContentBottomMargin: CGFloat {
        return self.inputContainerBottomConstraint.constant
    }

    open func changeInputContentBottomMarginTo(_ newValue: CGFloat, animated: Bool = false, callback: (() -> Void)? = nil) {
        self.changeInputContentBottomMarginTo(newValue, animated: animated, duration: CATransaction.animationDuration(), callback: callback)
    }

    open func changeInputContentBottomMarginTo(_ newValue: CGFloat, animated: Bool = false, duration: CFTimeInterval, initialSpringVelocity: CGFloat = 0.0, callback: (() -> Void)? = nil) {
        guard self.inputContainerBottomConstraint.constant != newValue else { callback?(); return }
        self.isAdjustingInputContainer = true
        let layoutBlock = {
            self.inputContainerBottomConstraint.constant = max(newValue, self.bottomLayoutGuide.length)
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: initialSpringVelocity,
                           options: .curveLinear,
                           animations: layoutBlock,
                           completion: { (_) in
                            callback?()
            })
        } else {
            layoutBlock()
            callback?()
        }
        self.isAdjustingInputContainer = false
    }
}
