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

public protocol CellRevealing {
    var allowRevealing: Bool { get }
}

public protocol AccessoryViewRevealable: CellRevealing {
    func revealAccessoryView(withOffset offset: CGFloat, animated: Bool)
    func preferredOffsetToRevealAccessoryView() -> CGFloat? // This allows to sync size in case cells have different sizes for the accessory view. Nil -> no restriction
}

public protocol ReplyIndicatorRevealable: CellRevealing {
    func canShowReply() -> Bool
    func revealReplyIndicator(withOffset offset: CGFloat, animated: Bool) -> Bool
}

public protocol ReplyIndicatorRevealerDelegate: AnyObject {
    func didPassThreshold(at: IndexPath)
    func didFinishReplyGesture(at: IndexPath)
    func didCancelReplyGesture(at: IndexPath)
}

public struct CellPanGestureHandlerConfig {
    public let angleThresholdInRads: CGFloat
    public let threshold: CGFloat
    public let accessoryViewTranslationMultiplier: CGFloat
    public let replyIndicatorTranslationMultiplier: CGFloat
    public var allowReplyRevealing: Bool = false
    public var allowTimestampRevealing: Bool = true

    public static func defaultConfig() -> CellPanGestureHandlerConfig {
        .init(
            angleThresholdInRads: 0.0872665, // ~5 degrees
            threshold: 30,
            accessoryViewTranslationMultiplier: 1/2,
            replyIndicatorTranslationMultiplier: 2/3
        )
    }

    func transformAccessoryViewTranslation(_ translation: CGFloat) -> CGFloat {
        (translation - self.threshold) * self.accessoryViewTranslationMultiplier
    }

    func transformReplyIndicatorTranslation(_ translation: CGFloat) -> CGFloat {
        (translation - self.threshold) * self.replyIndicatorTranslationMultiplier
    }
}

final class CellPanGestureHandler: NSObject, UIGestureRecognizerDelegate {

    private let panRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer()
    private let collectionView: UICollectionView

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        self.collectionView.addGestureRecognizer(self.panRecognizer)
        self.panRecognizer.addTarget(self, action: #selector(CellPanGestureHandler.handlePan(_:)))
        self.panRecognizer.delegate = self
    }

    deinit {
        self.panRecognizer.delegate = nil
        self.collectionView.removeGestureRecognizer(self.panRecognizer)
    }

    var isEnabled: Bool = true {
        didSet {
            self.panRecognizer.isEnabled = self.isEnabled
        }
    }

    var config = CellPanGestureHandlerConfig.defaultConfig()

    public weak var replyDelegate: ReplyIndicatorRevealerDelegate?

    @objc
    private func handlePan(_ panRecognizer: UIPanGestureRecognizer) {
        switch panRecognizer.state {
        case .began:
            break
        case .changed:
            let translation = panRecognizer.translation(in: self.collectionView)
            if translation.x < 0 {
                guard self.config.allowTimestampRevealing else { return }
                self.revealAccessoryView(atOffset: self.config.transformAccessoryViewTranslation(-translation.x))
            } else {
                guard let indexPath = self.collectionView.indexPathForItem(at: panRecognizer.location(in: self.collectionView)),
                    let cell = self.collectionView.cellForItem(at: indexPath) as? ReplyIndicatorRevealable,
                    cell.allowRevealing,
                    self.config.allowReplyRevealing,
                    cell.canShowReply() else { return }

                if self.replyIndexPath == nil, translation.x > self.config.threshold {
                    self.replyIndexPath = indexPath
                    self.collectionView.isScrollEnabled = false
                }
                self.revealReplyIndicator(atOffset: self.config.transformReplyIndicatorTranslation(translation.x))
            }
        case .ended:
            self.revealAccessoryView(atOffset: 0)
            self.finishRevealingReply()

        case .failed, .cancelled:
            self.revealAccessoryView(atOffset: 0)
            self.cancelRevealingReply()
        default:
            break
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer != self.panRecognizer {
            return true
        }

        let translation = self.panRecognizer.translation(in: self.collectionView)
        let x = abs(translation.x), y = abs(translation.y)
        let angleRads = atan2(y, x)
        return angleRads <= self.config.angleThresholdInRads
    }

    private func revealAccessoryView(atOffset offset: CGFloat) {
        // Find max offset (cells can have slighlty different timestamp size ( 3.00 am vs 11.37 pm )
        let cells: [AccessoryViewRevealable] = self.collectionView.visibleCells.compactMap({ $0 as? AccessoryViewRevealable })
        let offset = min(offset, cells.reduce(0) { (current, cell) -> CGFloat in
            return max(current, cell.preferredOffsetToRevealAccessoryView() ?? 0)
        })

        for cell in self.collectionView.visibleCells {
            if let cell = cell as? AccessoryViewRevealable, cell.allowRevealing {
                cell.revealAccessoryView(withOffset: offset, animated: offset == 0)
            }
        }
    }

    private var replyIndexPath: IndexPath?
    private var overReplyThreshold = false

    private func revealReplyIndicator(atOffset offset: CGFloat) {
        guard let indexPath = self.replyIndexPath,
              let cell = self.collectionView.cellForItem(at: indexPath) as? ReplyIndicatorRevealable else { return }
        let maxOffsetReached = cell.revealReplyIndicator(withOffset: offset, animated: offset == 0)
        if maxOffsetReached != overReplyThreshold {
            self.replyDelegate?.didPassThreshold(at: indexPath)
            self.overReplyThreshold = maxOffsetReached
        }
    }

    private func finishRevealingReply() {
        defer { self.cleanUpRevealingReply() }
        guard let indexPath = self.replyIndexPath else { return }
        if self.overReplyThreshold {
            self.replyDelegate?.didFinishReplyGesture(at: indexPath)
        } else {
            self.replyDelegate?.didCancelReplyGesture(at: indexPath)
        }
    }

    private func cancelRevealingReply() {
        defer { self.cleanUpRevealingReply() }
        guard let indexPath = self.replyIndexPath else { return }
        self.replyDelegate?.didCancelReplyGesture(at: indexPath)
    }

    private func cleanUpRevealingReply() {
        self.overReplyThreshold = false
        self.revealReplyIndicator(atOffset: 0)
        self.collectionView.isScrollEnabled = true
        self.replyIndexPath = nil
    }
}
