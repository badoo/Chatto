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

extension ChatViewController: ChatDataSourceDelegateProtocol {

    public enum UpdateContext {
        case Normal
        case FirstLoad
        case Pagination
        case Reload
        case MessageCountReduction
    }

    public func chatDataSourceDidUpdate(chatDataSource: ChatDataSourceProtocol) {
        self.enqueueModelUpdate(context: .Normal)
    }

    public func enqueueModelUpdate(context context: UpdateContext) {
        let newItems = self.chatDataSource?.chatItems ?? []
        self.updateQueue.addTask({ [weak self] (completion) -> () in
            guard let sSelf = self else { return }

            let oldItems = sSelf.decoratedChatItems.map { $0.chatItem }
            sSelf.updateModels(newItems: newItems, oldItems: oldItems, context: context, completion: {
                if sSelf.updateQueue.isEmpty {
                    sSelf.enqueueMessageCountReductionIfNeeded()
                }
                completion()
            })
        })
    }

    public func enqueueMessageCountReductionIfNeeded() {
        guard let preferredMaxMessageCount = self.constants.preferredMaxMessageCount where (self.chatDataSource?.chatItems.count ?? 0) > preferredMaxMessageCount else { return }
        self.updateQueue.addTask { [weak self] (completion) -> () in
            guard let sSelf = self else { return }
            sSelf.chatDataSource?.adjustNumberOfMessages(preferredMaxCount: sSelf.constants.preferredMaxMessageCountAdjustment, focusPosition: sSelf.focusPosition, completion: { (didAdjust) -> Void in
                guard didAdjust, let sSelf = self else {
                    completion()
                    return
                }
                let newItems = sSelf.chatDataSource?.chatItems ?? []
                let oldItems = sSelf.decoratedChatItems.map { $0.chatItem }
                sSelf.updateModels(newItems: newItems, oldItems: oldItems, context: .MessageCountReduction, completion: completion )
            })
        }
    }

    // Returns scrolling position in interval [0, 1], 0 top, 1 bottom
    public var focusPosition: Double {
        if self.isCloseToBottom() {
            return 1
        } else if self.isCloseToTop() {
            return 0
        }

        let contentHeight = self.collectionView.contentSize.height
        guard contentHeight > 0 else {
            return 0.5
        }

        // Rough estimation
        let midContentOffset = self.collectionView.contentOffset.y + self.visibleRect().height / 2
        return min(max(0, Double(midContentOffset / contentHeight)), 1.0)
    }

    func updateVisibleCells(changes: CollectionChanges) {
        // Datasource should be already updated!

        let visibleIndexPaths = Set(self.collectionView.indexPathsForVisibleItems().filter { (indexPath) -> Bool in
            return !changes.insertedIndexPaths.contains(indexPath) && !changes.deletedIndexPaths.contains(indexPath)
            })

        var updatedIndexPaths = Set<NSIndexPath>()
        for move in changes.movedIndexPaths {
            updatedIndexPaths.insert(move.indexPathOld)
            if let cell = self.collectionView.cellForItemAtIndexPath(move.indexPathOld) {
                self.presenterForIndexPath(move.indexPathNew).configureCell(cell, decorationAttributes: self.decorationAttributesForIndexPath(move.indexPathNew))
            }
        }

        // Update remaining visible cells
        let remaining = visibleIndexPaths.subtract(updatedIndexPaths)
        for indexPath in remaining {
            if let cell = self.collectionView.cellForItemAtIndexPath(indexPath) {
                self.presenterForIndexPath(indexPath).configureCell(cell, decorationAttributes: self.decorationAttributesForIndexPath(indexPath))
            }
        }
    }

    func performBatchUpdates(
        updateModelClosure updateModelClosure: () -> Void,
        changes: CollectionChanges,
        context: UpdateContext,
        completion: () -> Void) {
            let shouldScrollToBottom = context != .Pagination && self.isScrolledAtBottom()
            let oldRect = self.rectAtIndexPath(changes.movedIndexPaths.first?.indexPathOld)
            let myCompletion = {
                // Found that cells may not match correct index paths here yet! (see comment below)
                // Waiting for next loop seems to fix the issue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion()
                })
            }

            if context == .Normal {

                UIView.animateWithDuration(self.constants.updatesAnimationDuration, animations: { () -> Void in
                    // We want to update visible cells to support easy removal of bubble tail or any other updates that may be needed after a data update
                    // Collection view state is not constistent after performBatchUpdates. It can happen that we ask a cell for an index path and we still get the old one.
                    // Visible cells can be either updated in completion block (easier but with delay) or before, taking into account if some cell is gonna be moved

                    updateModelClosure()
                    self.updateVisibleCells(changes)

                    self.collectionView.performBatchUpdates({ () -> Void in
                        self.collectionView.deleteItemsAtIndexPaths(Array(changes.deletedIndexPaths))
                        self.collectionView.insertItemsAtIndexPaths(Array(changes.insertedIndexPaths))
                        for move in changes.movedIndexPaths {
                            self.collectionView.moveItemAtIndexPath(move.indexPathOld, toIndexPath: move.indexPathNew)
                        }
                    }) { (finished) -> Void in
                        myCompletion()
                    }
                })
            } else {
                updateModelClosure()
                self.collectionView.reloadData()
                self.collectionView.collectionViewLayout.prepareLayout()
                myCompletion()
            }

            if shouldScrollToBottom {
                self.scrollToBottom(animated: context == .Normal)
            } else {
                let newRect = self.rectAtIndexPath(changes.movedIndexPaths.first?.indexPathNew)
                self.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
            }
    }

    private func updateModels(newItems newItems: [ChatItemProtocol], oldItems: [ChatItemProtocol], var context: UpdateContext, completion: () -> Void) {
        let collectionViewWidth = self.collectionView.bounds.width
        context = self.isFirstLayout ? .FirstLoad : context
        let performInBackground = context != .FirstLoad

        self.autoLoadingEnabled = false
        let perfomBatchUpdates: (changes: CollectionChanges, updateModelClosure: () -> Void) -> ()  = { [weak self] modelUpdate in
            self?.performBatchUpdates(
                updateModelClosure: modelUpdate.updateModelClosure,
                changes: modelUpdate.changes,
                context: context,
                completion: { () -> Void in
                    self?.autoLoadingEnabled = true
                    completion()
            })
        }

        let createModelUpdate = {
            return self.createModelUpdates(
                newItems: newItems,
                oldItems: oldItems,
                collectionViewWidth:collectionViewWidth)
        }

        if performInBackground {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                let modelUpdate = createModelUpdate()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    perfomBatchUpdates(changes: modelUpdate.changes, updateModelClosure: modelUpdate.updateModelClosure)
                })
            }
        } else {
            let modelUpdate = createModelUpdate()
            perfomBatchUpdates(changes: modelUpdate.changes, updateModelClosure: modelUpdate.updateModelClosure)
        }
    }

    private func createModelUpdates(newItems newItems: [ChatItemProtocol], oldItems: [ChatItemProtocol], collectionViewWidth: CGFloat) -> (changes: CollectionChanges, updateModelClosure: () -> Void) {
        let newDecoratedItems = self.chatItemsDecorator?.decorateItems(newItems) ?? newItems.map { DecoratedChatItem(chatItem: $0, decorationAttributes: nil) }
        let changes = Chatto.generateChanges(
            oldCollection: oldItems.map { $0 },
            newCollection: newDecoratedItems.map { $0.chatItem }
        )
        let layoutModel = self.createLayoutModel(newDecoratedItems, collectionViewWidth: collectionViewWidth)
        let updateModelClosure : () -> Void = { [weak self] in
            self?.layoutModel = layoutModel
            self?.decoratedChatItems = newDecoratedItems
        }
        return (changes, updateModelClosure)
    }

    private func createLayoutModel(decoratedItems: [DecoratedChatItem], collectionViewWidth: CGFloat) -> ChatCollectionViewLayoutModel {
        typealias IntermediateItemLayoutData = (height: CGFloat?, bottomMargin: CGFloat)
        typealias ItemLayoutData = (height: CGFloat, bottomMargin: CGFloat)

        func createLayoutModel(intermediateLayoutData intermediateLayoutData: [IntermediateItemLayoutData]) -> ChatCollectionViewLayoutModel {
            let layoutData = intermediateLayoutData.map { (intermediateLayoutData: IntermediateItemLayoutData) -> ItemLayoutData in
                return (height: intermediateLayoutData.height!, bottomMargin: intermediateLayoutData.bottomMargin)
            }
            return ChatCollectionViewLayoutModel.createModel(self.collectionView.bounds.width, itemsLayoutData: layoutData)
        }

        let isInbackground = !NSThread.isMainThread()
        var intermediateLayoutData = [IntermediateItemLayoutData]()
        var itemsForMainThread = [(index: Int, item: DecoratedChatItem, presenter: ChatItemPresenterProtocol?)]()

        for (index, decoratedItem) in decoratedItems.enumerate() {
            let presenter = self.presenterForIndex(index, decoratedChatItems: decoratedItems)
            var height: CGFloat?
            let bottomMargin: CGFloat = decoratedItem.decorationAttributes?.bottomMargin ?? 0
            if !isInbackground || presenter.canCalculateHeightInBackground ?? false {
                height = presenter.heightForCell(maximumWidth: collectionViewWidth, decorationAttributes: decoratedItem.decorationAttributes)
            } else {
                itemsForMainThread.append((index: index, item: decoratedItem, presenter: presenter))
            }
            intermediateLayoutData.append((height: height, bottomMargin: bottomMargin))
        }

        if itemsForMainThread.count > 0 {
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                for (index, decoratedItem, presenter) in itemsForMainThread {
                    let height = presenter?.heightForCell(maximumWidth: collectionViewWidth, decorationAttributes: decoratedItem.decorationAttributes)
                    intermediateLayoutData[index].height = height
                }
            })
        }
        return createLayoutModel(intermediateLayoutData: intermediateLayoutData)
    }

    public func chatCollectionViewLayoutModel() -> ChatCollectionViewLayoutModel {
        if self.layoutModel.calculatedForWidth != self.collectionView.bounds.width {
            self.layoutModel = self.createLayoutModel(self.decoratedChatItems, collectionViewWidth: self.collectionView.bounds.width);

        }
        return self.layoutModel
    }

}
