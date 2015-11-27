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

public enum CellVerticalEdge {
    case Top
    case Bottom
}

extension ChatViewController {

    public func isScrolledAtBottom() -> Bool {
        guard self.collectionView.numberOfSections() > 0 && self.collectionView.numberOfItemsInSection(0) > 0 else { return true }
        let sectionIndex = self.collectionView.numberOfSections() - 1
        let itemIndex = self.collectionView.numberOfItemsInSection(sectionIndex) - 1
        let lastIndexPath = NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
        return self.isIndexPathVisible(lastIndexPath, atEdge: .Bottom)
    }

    public func isScrolledAtTop() -> Bool {
        guard self.collectionView.numberOfSections() > 0 && self.collectionView.numberOfItemsInSection(0) > 0 else { return true }
        let firstIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        return self.isIndexPathVisible(firstIndexPath, atEdge: .Top)
    }

    public func isCloseToBottom() -> Bool {
        guard self.collectionView.contentSize.height > 0 else { return true }
        return (self.visibleRect().maxY / self.collectionView.contentSize.height) > (1 - self.constants.autoloadingFractionalThreshold)
    }

    public func isCloseToTop() -> Bool {
        guard self.collectionView.contentSize.height > 0 else { return true }
        return (self.visibleRect().minY / self.collectionView.contentSize.height) < self.constants.autoloadingFractionalThreshold
    }

    public func isIndexPathVisible(indexPath: NSIndexPath, atEdge edge: CellVerticalEdge) -> Bool {
        if let attributes = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath) {
            let visibleRect = self.visibleRect()
            let intersection = visibleRect.intersect(attributes.frame)
            if edge == .Top {
                return intersection.minY == attributes.frame.minY
            } else {
                return intersection.maxY == attributes.frame.maxY
            }
        }
        return false
    }

    public func visibleRect() -> CGRect {
        let contentInset = self.collectionView.contentInset
        let collectionViewBounds = self.collectionView.bounds
        return CGRect(x: CGFloat(0), y: self.collectionView.contentOffset.y + contentInset.top, width: collectionViewBounds.width, height: min(self.collectionView.contentSize.height, collectionViewBounds.height - contentInset.top - contentInset.bottom))
    }

    public func scrollToBottom(animated animated: Bool) {
        // Note that we don't rely on collectionView's contentSize. This is because it won't be valid after performBatchUpdates or reloadData
        // After reload data, collectionViewLayout.collectionViewContentSize won't be even valid, so you may want to refresh the layout manually
        let offsetY = max(-self.collectionView.contentInset.top, self.collectionView.collectionViewLayout.collectionViewContentSize().height - self.collectionView.bounds.height + self.collectionView.contentInset.bottom)
        self.collectionView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: animated)
    }

    public func scrollToPreservePosition(oldRefRect oldRefRect: CGRect?, newRefRect: CGRect?) {
        guard let oldRefRect = oldRefRect, newRefRect = newRefRect else {
            return
        }
        let diffY = newRefRect.minY - oldRefRect.minY
        self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentOffset.y + diffY)
    }

    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if self.collectionView.dragging {
            self.autoLoadMoreContentIfNeeded()
        }
    }

    public func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        self.autoLoadMoreContentIfNeeded()
    }

    public func autoLoadMoreContentIfNeeded() {
        guard self.autoLoadingEnabled, let dataSource = self.chatDataSource else { return }

        if self.isCloseToTop() && dataSource.hasMorePrevious {
            dataSource.loadPrevious({ [weak self] () -> Void in
                self?.enqueueModelUpdate(context: .Pagination)
            })
        } else if self.isCloseToBottom() && dataSource.hasMoreNext {
            dataSource.loadNext({ [weak self] () -> Void in
                self?.enqueueModelUpdate(context: .Pagination)
            })
        }
    }
}
