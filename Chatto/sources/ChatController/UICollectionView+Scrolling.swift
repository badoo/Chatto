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

extension UICollectionView {
    public func rect(at indexPath: IndexPath) -> CGRect? {
        self.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame
    }

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
    public func scrollToBottom(animated: Bool, animationDuration: TimeInterval) {
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
