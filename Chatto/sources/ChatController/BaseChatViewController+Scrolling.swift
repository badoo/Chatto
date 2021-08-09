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

@frozen
public enum CellVerticalEdge {
    case top
    case bottom
}

extension CGFloat {
    static let bma_epsilon: CGFloat = 0.001
}

extension BaseChatViewController {

    private static var nextDidEndScrollingAnimationHandlersKey: Int = 0
    private var nextDidEndScrollingAnimationHandlers: [() -> Void] {
        get { objc_getAssociatedObject(self, &Self.nextDidEndScrollingAnimationHandlersKey) as? [() -> Void] ?? [] }
        set { objc_setAssociatedObject(self, &Self.nextDidEndScrollingAnimationHandlersKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    public func isScrolledAtBottom() -> Bool {
        guard let collectionView = self.collectionView else { return true }
        return collectionView.isScrolledAtBottom()
    }

    public func isScrolledAtTop() -> Bool {
        guard let collectionView = self.collectionView else { return true }
        return collectionView.isScrolledAtTop()
    }

    public func isCloseToBottom() -> Bool {
        guard let collectionView = self.collectionView else { return true }

        return collectionView.isCloseToBottom(threshold: self.configuration.updates.autoloadingFractionalThreshold)
    }

    public func isCloseToTop() -> Bool {
        guard let collectionView = self.collectionView else { return true }

        return collectionView.isCloseToTop(threshold: self.configuration.updates.autoloadingFractionalThreshold)
    }

    public func isIndexPathVisible(_ indexPath: IndexPath, atEdge edge: CellVerticalEdge) -> Bool {
        guard let collectionView = self.collectionView else { return true }

        return collectionView.isIndexPathVisible(indexPath, atEdge: edge)
    }

    public func visibleRect() -> CGRect {
        guard let collectionView = self.collectionView else { return CGRect.zero }
        return collectionView.visibleRect()
    }

    @objc
    open func scrollToBottom(animated: Bool) {
        guard let collectionView = self.collectionView else { return }

        return collectionView.scrollToBottom(
            animated: animated,
            animationDuration: self.configuration.animation.updatesAnimationDuration
        )
    }

    public func scrollToPreservePosition(oldRefRect: CGRect?, newRefRect: CGRect?) {
        guard let collectionView = self.collectionView else { return }

        return collectionView.scrollToPreservePosition(oldRefRect: oldRefRect, newRefRect: newRefRect)
    }

    public func scrollToItem(withId itemId: String,
                             position: UICollectionView.ScrollPosition = .centeredVertically,
                             animated: Bool = false,
                             spotlight: Bool = false) {
        guard let collectionView = self.collectionView else { return }
        guard let itemIndex = self.chatItemCompanionCollection.indexOf(itemId) else { return }

        let indexPath = IndexPath(item: itemIndex, section: 0)
        guard let rect = self.rectAtIndexPath(indexPath) else { return }

        if animated {
            let pageHeight = collectionView.bounds.height
            let twoPagesHeight = pageHeight * 2
            let isScrollingUp = rect.minY < collectionView.contentOffset.y

            if isScrollingUp {
                let isNeedToScrollUpMoreThenTwoPages = rect.minY < collectionView.contentOffset.y - twoPagesHeight
                if isNeedToScrollUpMoreThenTwoPages {
                    let lastPageOriginY = collectionView.contentSize.height - pageHeight
                    var preScrollRect = rect
                    preScrollRect.origin.y = min(lastPageOriginY, rect.minY + pageHeight)
                    collectionView.scrollRectToVisible(preScrollRect, animated: false)
                }
            } else {
                let isNeedToScrollDownMoreThenTwoPages = rect.minY > collectionView.contentOffset.y + twoPagesHeight
                if isNeedToScrollDownMoreThenTwoPages {
                    var preScrollRect = rect
                    preScrollRect.origin.y = max(0, rect.minY - pageHeight)
                    collectionView.scrollRectToVisible(preScrollRect, animated: false)
                }
            }
        }

        if spotlight {
            guard let presenter = self.chatItemCompanionCollection[itemId]?.presenter else { return }
            let contentOffsetWillBeChanged = !collectionView.indexPathsForVisibleItems.contains(indexPath)
            if contentOffsetWillBeChanged {
                self.nextDidEndScrollingAnimationHandlers.append { [weak presenter] in
                    presenter?.spotlight()
                }
            } else {
                presenter.spotlight()
            }
        }

        collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        for handler in self.nextDidEndScrollingAnimationHandlers {
            handler()
        }
        self.nextDidEndScrollingAnimationHandlers = []
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = self.collectionView else { return }
        if collectionView.isDragging {
            self.autoLoadMoreContentIfNeeded()
        }
        self.scrollViewEventsHandler?.onScrollViewDidScroll(scrollView)
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.scrollViewEventsHandler?.onScrollViewDidEndDragging(scrollView, decelerate)
    }

    open func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        self.autoLoadMoreContentIfNeeded()
    }

    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}

    public func autoLoadMoreContentIfNeeded() {
        guard self.autoLoadingEnabled, let dataSource = self.chatDataSource else { return }

        if self.isCloseToTop() && dataSource.hasMorePrevious {
            dataSource.loadPrevious()
        } else if self.isCloseToBottom() && dataSource.hasMoreNext {
            dataSource.loadNext()
        }
    }
}

extension UICollectionView {
    public func isScrolledAtBottom() -> Bool {
        guard self.numberOfSections > 0 && self.numberOfItems(inSection: 0) > 0 else { return true }
        let sectionIndex = self.numberOfSections - 1
        let itemIndex = self.numberOfItems(inSection: sectionIndex) - 1
        let lastIndexPath = IndexPath(item: itemIndex, section: sectionIndex)

        return self.isIndexPathVisible(lastIndexPath, atEdge: .bottom)
    }

    public func isScrolledAtTop() -> Bool {
        guard self.numberOfSections > 0 && self.numberOfItems(inSection: 0) > 0 else { return true }
        let firstIndexPath = IndexPath(item: 0, section: 0)

        return self.isIndexPathVisible(firstIndexPath, atEdge: .top)
    }

    public func isCloseToBottom(threshold: CGFloat) -> Bool {
        guard self.contentSize.height > 0 else { return true }

        return (self.visibleRect().maxY / self.contentSize.height) > (1 - threshold)
    }

    public func isCloseToTop(threshold: CGFloat) -> Bool {
        guard self.contentSize.height > 0 else { return true }

        return (self.visibleRect().minY / self.contentSize.height) < threshold
    }

    public func isIndexPathVisible(_ indexPath: IndexPath, atEdge edge: CellVerticalEdge) -> Bool {
        guard let attributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) else { return false }

        let visibleRect = self.visibleRect()
        let intersection = visibleRect.intersection(attributes.frame)
        if edge == .top {
            return abs(intersection.minY - attributes.frame.minY) < CGFloat.bma_epsilon
        } else {
            return abs(intersection.maxY - attributes.frame.maxY) < CGFloat.bma_epsilon
        }
    }

    public func visibleRect() -> CGRect {
        let contentInset = self.contentInset
        let collectionViewBounds = self.bounds
        let contentSize = self.collectionViewLayout.collectionViewContentSize

        return CGRect(
            x: CGFloat(0),
            y: self.contentOffset.y + contentInset.top,
            width: collectionViewBounds.width,
            height: min(contentSize.height, collectionViewBounds.height - contentInset.top - contentInset.bottom)
        )
    }

    @objc
    open func scrollToBottom(animated: Bool, animationDuration: TimeInterval) {
        // Cancel current scrolling
        self.setContentOffset(self.contentOffset, animated: false)

        // Note that we don't rely on collectionView's contentSize. This is because it won't be valid after performBatchUpdates or reloadData
        // After reload data, collectionViewLayout.collectionViewContentSize won't be even valid, so you may want to refresh the layout manually
        let newOffsetY = self.collectionViewLayout.collectionViewContentSize.height
            - self.bounds.height
            + self.contentInset.bottom
        let offsetY = max(-self.contentInset.top, newOffsetY)

        // Don't use setContentOffset(:animated). If animated, contentOffset property will be updated along with the animation for each frame update
        // If a message is inserted while scrolling is happening (as in very fast typing), we want to take the "final" content offset (not the "real time" one) to check if we should scroll to bottom again
        if animated {
            UIView.animate(
                withDuration: animationDuration
            ){
                self.contentOffset = CGPoint(x: 0, y: offsetY)
            }
        } else {
            self.contentOffset = CGPoint(x: 0, y: offsetY)
        }
    }

    public func scrollToPreservePosition(oldRefRect: CGRect?, newRefRect: CGRect?) {
        guard let oldRefRect = oldRefRect,
              let newRefRect = newRefRect else {
            return
        }

        let diffY = newRefRect.minY - oldRefRect.minY
        self.contentOffset = CGPoint(x: 0, y: self.contentOffset.y + diffY)
    }
}
