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

extension BaseChatViewController: ChatDataSourceDelegateProtocol {

    public func chatDataSourceDidUpdate(chatDataSource: ChatDataSourceProtocol, updateType: UpdateType) {
        self.enqueueModelUpdate(updateType: updateType)
    }

    public func chatDataSourceDidUpdate(chatDataSource: ChatDataSourceProtocol) {
        self.enqueueModelUpdate(updateType: .Normal)
    }

    public func enqueueModelUpdate(updateType updateType: UpdateType) {
        let newItems = self.chatDataSource?.chatItems ?? []
        self.updateQueue.addTask({ [weak self] (completion) -> () in
            guard let sSelf = self else { return }

            let oldItems = sSelf.chatItemCompanionCollection
            sSelf.updateModels(newItems: newItems, oldItems: oldItems, updateType: updateType, completion: {
                guard let sSelf = self else { return }
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
                let oldItems = sSelf.chatItemCompanionCollection
                sSelf.updateModels(newItems: newItems, oldItems: oldItems, updateType: .MessageCountReduction, completion: completion )
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

        func updateCellIfVisible(atIndexPath cellIndexPath: NSIndexPath, newDataIndexPath: NSIndexPath) {
            if let cell = self.collectionView.cellForItemAtIndexPath(cellIndexPath) {
                let presenter = self.presenterForIndexPath(newDataIndexPath)
                presenter.configureCell(cell, decorationAttributes: self.decorationAttributesForIndexPath(newDataIndexPath))
                presenter.cellWillBeShown(cell) // `createModelUpdates` may have created a new presenter instance for existing visible cell so we need to tell it that its cell is visible
            }
        }

        let visibleIndexPaths = Set(self.collectionView.indexPathsForVisibleItems().filter { (indexPath) -> Bool in
            return !changes.insertedIndexPaths.contains(indexPath) && !changes.deletedIndexPaths.contains(indexPath)
        })

        var updatedIndexPaths = Set<NSIndexPath>()
        for move in changes.movedIndexPaths {
            updatedIndexPaths.insert(move.indexPathOld)
            updateCellIfVisible(atIndexPath: move.indexPathOld, newDataIndexPath: move.indexPathNew)
        }

        // Update remaining visible cells
        let remaining = visibleIndexPaths.subtract(updatedIndexPaths)
        for indexPath in remaining {
            updateCellIfVisible(atIndexPath: indexPath, newDataIndexPath: indexPath)
        }
    }

    func performBatchUpdates(
        updateModelClosure updateModelClosure: () -> Void,
        changes: CollectionChanges,
        updateType: UpdateType,
        completion: () -> Void) {
            let shouldScrollToBottom = updateType != .Pagination && self.isScrolledAtBottom()
            let (oldReferenceIndexPath, newReferenceIndexPath) = self.referenceIndexPathsToRestoreScrollPositionOnUpdate(itemsBeforeUpdate: self.chatItemCompanionCollection, changes: changes)
            let oldRect = self.rectAtIndexPath(oldReferenceIndexPath)
            let myCompletion = {
                // Found that cells may not match correct index paths here yet! (see comment below)
                // Waiting for next loop seems to fix the issue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion()
                })
            }

            if updateType == .Normal {

                UIView.animateWithDuration(self.constants.updatesAnimationDuration, animations: { () -> Void in
                    self.collectionView.performBatchUpdates({ () -> Void in
                        // We want to update visible cells to support easy removal of bubble tail or any other updates that may be needed after a data update
                        // Collection view state is not constistent after performBatchUpdates. It can happen that we ask a cell for an index path and we still get the old one.
                        // Visible cells can be either updated in completion block (easier but with delay) or before, taking into account if some cell is gonna be moved
                        updateModelClosure()
                        self.updateVisibleCells(changes)

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
                self.scrollToBottom(animated: updateType == .Normal)
            } else {
                let newRect = self.rectAtIndexPath(newReferenceIndexPath)
                self.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
            }
    }

    private func updateModels(newItems newItems: [ChatItemProtocol], oldItems: ChatItemCompanionCollection, updateType: UpdateType, completion: () -> Void) {
        let collectionViewWidth = self.collectionView.bounds.width
        let updateType = self.isFirstLayout ? .FirstLoad : updateType
        let performInBackground = updateType != .FirstLoad

        self.autoLoadingEnabled = false
        let perfomBatchUpdates: (changes: CollectionChanges, updateModelClosure: () -> Void) -> ()  = { [weak self] modelUpdate in
            self?.performBatchUpdates(
                updateModelClosure: modelUpdate.updateModelClosure,
                changes: modelUpdate.changes,
                updateType: updateType,
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

    private func createModelUpdates(newItems newItems: [ChatItemProtocol], oldItems: ChatItemCompanionCollection, collectionViewWidth: CGFloat) -> (changes: CollectionChanges, updateModelClosure: () -> Void) {
        let newDecoratedItems = self.chatItemsDecorator?.decorateItems(newItems) ?? newItems.map { DecoratedChatItem(chatItem: $0, decorationAttributes: nil) }
        let changes = Chatto.generateChanges(oldCollection: oldItems.map { $0.chatItem }, newCollection: newDecoratedItems.map { $0.chatItem })
        let itemCompanionCollection = self.createCompanionCollection(fromChatItems: newDecoratedItems, previousCompanionCollection: oldItems)
        let layoutModel = self.createLayoutModel(itemCompanionCollection, collectionViewWidth: collectionViewWidth)
        let updateModelClosure : () -> Void = { [weak self] in
            self?.layoutModel = layoutModel
            self?.chatItemCompanionCollection = itemCompanionCollection
        }
        return (changes, updateModelClosure)
    }

    private func createCompanionCollection(fromChatItems newItems: [DecoratedChatItem], previousCompanionCollection oldItems: ChatItemCompanionCollection) -> ChatItemCompanionCollection {
        return ChatItemCompanionCollection(items: newItems.map { (decoratedChatItem) -> ChatItemCompanion in
            let chatItem = decoratedChatItem.chatItem
            var presenter: ChatItemPresenterProtocol!
            // We assume that a same messageId can't mutate from one cell class to a different one.
            // If we ever need to support that then generation of changes needs to suppport reloading items.
            // Oherwise updateVisibleCells may try to update existing cell with a new presenter which is working with a different type of cell

            // Optimization: reuse presenter if it's the same instance.
            if let oldChatItemCompanion = oldItems[chatItem.uid] where oldChatItemCompanion.chatItem === chatItem {
                presenter = oldChatItemCompanion.presenter
            } else {
                presenter = self.createPresenterForChatItem(decoratedChatItem.chatItem)
            }
            return ChatItemCompanion(chatItem: decoratedChatItem.chatItem, presenter: presenter, decorationAttributes: decoratedChatItem.decorationAttributes)
        })
    }

    private func createLayoutModel(items: ChatItemCompanionCollection, collectionViewWidth: CGFloat) -> ChatCollectionViewLayoutModel {
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
        var itemsForMainThread = [(index: Int, itemCompanion: ChatItemCompanion)]()

        for (index, itemCompanion) in items.enumerate() {
            var height: CGFloat?
            let bottomMargin: CGFloat = itemCompanion.decorationAttributes?.bottomMargin ?? 0
            if !isInbackground || itemCompanion.presenter.canCalculateHeightInBackground {
                height = itemCompanion.presenter.heightForCell(maximumWidth: collectionViewWidth, decorationAttributes: itemCompanion.decorationAttributes)
            } else {
                itemsForMainThread.append((index: index, itemCompanion: itemCompanion))
            }
            intermediateLayoutData.append((height: height, bottomMargin: bottomMargin))
        }

        if itemsForMainThread.count > 0 {
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                for (index, itemCompanion) in itemsForMainThread {
                    let height = itemCompanion.presenter.heightForCell(maximumWidth: collectionViewWidth, decorationAttributes: itemCompanion.decorationAttributes)
                    intermediateLayoutData[index].height = height
                }
            })
        }
        return createLayoutModel(intermediateLayoutData: intermediateLayoutData)
    }

    public func chatCollectionViewLayoutModel() -> ChatCollectionViewLayoutModel {
        if self.layoutModel.calculatedForWidth != self.collectionView.bounds.width {
            self.layoutModel = self.createLayoutModel(self.chatItemCompanionCollection, collectionViewWidth: self.collectionView.bounds.width)
        }
        return self.layoutModel
    }

}
