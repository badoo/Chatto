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

private struct HashableItem: Hashable {
    private let uid: String
    private let type: String

    init(_ decoratedChatItem: DecoratedChatItem) {
        self.uid = decoratedChatItem.uid
        self.type = decoratedChatItem.chatItem.type
    }

    init(_ chatItemCompanion: ChatItemCompanion) {
        self.uid = chatItemCompanion.uid
        self.type = chatItemCompanion.chatItem.type
    }
}

extension BaseChatViewController {

    public func enqueueModelUpdate(updateType: UpdateType, completion: (() -> Void)? = nil) {
        let newItems = self.chatDataSource?.chatItems ?? []

        if self.updatesConfig.coalesceUpdates {
            self.updateQueue.flushQueue()
        }

        self.updateQueue.addTask({ [weak self] (runNextTask) -> Void in
            guard let sSelf = self else { return }

            let oldItems = sSelf.chatItemCompanionCollection
            sSelf.updateModels(newItems: newItems, oldItems: oldItems, updateType: updateType, completion: {
                guard let sSelf = self else { return }
                if sSelf.updateQueue.isEmpty {
                    sSelf.enqueueMessageCountReductionIfNeeded()
                }
                completion?()
                DispatchQueue.main.async(execute: { () -> Void in
                    // Reduces inconsistencies before next update: https://github.com/diegosanchezr/UICollectionViewStressing
                    runNextTask()
                })
            })
        })
    }

    public func enqueueMessageCountReductionIfNeeded() {
        guard let preferredMaxMessageCount = self.constants.preferredMaxMessageCount, (self.chatDataSource?.chatItems.count ?? 0) > preferredMaxMessageCount else { return }
        self.updateQueue.addTask { [weak self] (completion) -> Void in
            guard let sSelf = self else { return }
            sSelf.chatDataSource?.adjustNumberOfMessages(preferredMaxCount: sSelf.constants.preferredMaxMessageCountAdjustment, focusPosition: sSelf.focusPosition, completion: { (didAdjust) -> Void in
                guard didAdjust, let sSelf = self else {
                    completion()
                    return
                }
                let newItems = sSelf.chatDataSource?.chatItems ?? []
                let oldItems = sSelf.chatItemCompanionCollection
                sSelf.updateModels(newItems: newItems, oldItems: oldItems, updateType: .messageCountReduction, completion: completion )
            })
        }
    }

    // Returns scrolling position in interval [0, 1], 0 top, 1 bottom
    public var focusPosition: Double {
        guard let collectionView = self.collectionView else { return 0 }
        if self.isCloseToBottom() {
            return 1
        } else if self.isCloseToTop() {
            return 0
        }

        let contentHeight = collectionView.contentSize.height
        guard contentHeight > 0 else {
            return 0.5
        }

        // Rough estimation
        let collectionViewContentYOffset = collectionView.contentOffset.y
        let midContentOffset = collectionViewContentYOffset + self.visibleRect().height / 2
        return min(max(0, Double(midContentOffset / contentHeight)), 1.0)
    }

    func updateVisibleCells(_ changes: CollectionChanges) {
        // Datasource should be already updated!

        assert(self.visibleCellsAreValid(changes: changes), "Invalid visible cells. Don't call me")

        let cellsToUpdate = updated(collection: self.visibleCellsFromCollectionViewApi(), withChanges: changes)
        self.visibleCells = cellsToUpdate

        cellsToUpdate.forEach { (indexPath, cell) in
            let presenter = self.presenterForIndexPath(indexPath)
            presenter.configureCell(cell, decorationAttributes: self.decorationAttributesForIndexPath(indexPath))
            presenter.cellWillBeShown(cell) // `createModelUpdates` may have created a new presenter instance for existing visible cell so we need to tell it that its cell is visible
        }
    }

    private func visibleCellsFromCollectionViewApi() -> [IndexPath: UICollectionViewCell] {
        var visibleCells: [IndexPath: UICollectionViewCell] = [:]
        guard let collectionView = self.collectionView else { return visibleCells }
        collectionView.indexPathsForVisibleItems.forEach({ (indexPath) in
            if let cell = collectionView.cellForItem(at: indexPath) {
                visibleCells[indexPath] = cell
            }
        })
        return visibleCells
    }

    private func visibleCellsAreValid(changes: CollectionChanges) -> Bool {
        // Afer performBatchUpdates, indexPathForCell may return a cell refering to the state before the update
        // if self.updatesConfig.fastUpdates is enabled, very fast updates could result in `updateVisibleCells` updating wrong cells.
        // See more: https://github.com/diegosanchezr/UICollectionViewStressing

        if self.updatesConfig.fastUpdates {
            return updated(collection: self.visibleCells, withChanges: changes) == updated(collection: self.visibleCellsFromCollectionViewApi(), withChanges: changes)
        } else {
            return true // never seen inconsistency without fastUpdates
        }
    }

    private enum ScrollAction {
        case scrollToBottom
        case preservePosition(rectForReferenceIndexPathBeforeUpdate: CGRect?, referenceIndexPathAfterUpdate: IndexPath?)
    }

    func performBatchUpdates(updateModelClosure: @escaping () -> Void,
                             changes: CollectionChanges,
                             updateType: UpdateType,
                             completion: @escaping () -> Void) {
        guard let collectionView = self.collectionView else {
            completion()
            return
        }
        let usesBatchUpdates: Bool
        do { // Recover from too fast updates...
            let visibleCellsAreValid = self.visibleCellsAreValid(changes: changes)
            let wantsReloadData = updateType != .normal
            let hasUnfinishedBatchUpdates = self.unfinishedBatchUpdatesCount > 0 // This can only happen when enabling self.updatesConfig.fastUpdates

            // a) It's unsafe to perform reloadData while there's a performBatchUpdates animating: https://github.com/diegosanchezr/UICollectionViewStressing/tree/master/GhostCells
            // Note: using reloadSections instead reloadData is safe and might not need a delay. However, using always reloadSections causes flickering on pagination and a crash on the first layout that needs a workaround. Let's stick to reloaData for now
            // b) If it's a performBatchUpdates but visible cells are invalid let's wait until all finish (otherwise we would give wrong cells to presenters in updateVisibleCells)
            let mustDelayUpdate = hasUnfinishedBatchUpdates && (wantsReloadData || !visibleCellsAreValid)
            guard !mustDelayUpdate else {
                // For reference, it is possible to force the current performBatchUpdates to finish in the next run loop, by cancelling animations:
                // self.collectionView.subviews.forEach { $0.layer.removeAllAnimations() }
                self.onAllBatchUpdatesFinished = { [weak self] in
                    self?.onAllBatchUpdatesFinished = nil
                    self?.performBatchUpdates(updateModelClosure: updateModelClosure, changes: changes, updateType: updateType, completion: completion)
                }
                return
            }
            // ... if they are still invalid the only thing we can do is a reloadData
            let mustDoReloadData = !visibleCellsAreValid // Only way to recover from this inconsistent state
            usesBatchUpdates = !wantsReloadData && !mustDoReloadData
        }

        let scrollAction: ScrollAction
        do { // Scroll action
            if updateType != .pagination && self.isScrolledAtBottom() {
                scrollAction = .scrollToBottom
            } else {
                let (oldReferenceIndexPath, newReferenceIndexPath) = self.referenceIndexPathsToRestoreScrollPositionOnUpdate(itemsBeforeUpdate: self.chatItemCompanionCollection, changes: changes)
                let oldRect = self.rectAtIndexPath(oldReferenceIndexPath)
                scrollAction = .preservePosition(rectForReferenceIndexPathBeforeUpdate: oldRect, referenceIndexPathAfterUpdate: newReferenceIndexPath)
            }
        }

        let myCompletion: () -> Void
        do { // Completion
            var myCompletionExecuted = false
            myCompletion = {
                if myCompletionExecuted { return }
                myCompletionExecuted = true
                completion()
            }
        }

        if usesBatchUpdates {
            UIView.animate(withDuration: self.constants.updatesAnimationDuration, animations: { () -> Void in
                self.unfinishedBatchUpdatesCount += 1
                collectionView.performBatchUpdates({ () -> Void in
                    updateModelClosure()
                    self.updateVisibleCells(changes) // For instance, to support removal of tails

                    collectionView.deleteItems(at: Array(changes.deletedIndexPaths))
                    collectionView.insertItems(at: Array(changes.insertedIndexPaths))
                    for move in changes.movedIndexPaths {
                        collectionView.moveItem(at: move.indexPathOld, to: move.indexPathNew)
                    }
                }, completion: { [weak self] (_) -> Void in
                    defer { myCompletion() }
                    guard let sSelf = self else { return }
                    sSelf.unfinishedBatchUpdatesCount -= 1
                    if sSelf.unfinishedBatchUpdatesCount == 0, let onAllBatchUpdatesFinished = self?.onAllBatchUpdatesFinished {
                        DispatchQueue.main.async(execute: onAllBatchUpdatesFinished)
                    }
                })
                if self.placeMessagesFromBottom {
                    self.adjustCollectionViewInsets(shouldUpdateContentOffset: false)
                }
            })
        } else {
            self.visibleCells = [:]
            updateModelClosure()
            collectionView.reloadData()
            collectionView.collectionViewLayout.prepare()
            if self.placeMessagesFromBottom {
                self.adjustCollectionViewInsets(shouldUpdateContentOffset: false)
            }
        }

        switch scrollAction {
        case .scrollToBottom:
            self.scrollToBottom(animated: updateType == .normal)
        case .preservePosition(rectForReferenceIndexPathBeforeUpdate: let oldRect, referenceIndexPathAfterUpdate: let indexPath):
            let newRect = self.rectAtIndexPath(indexPath)
            self.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
        }

        if !usesBatchUpdates || self.updatesConfig.fastUpdates {
            myCompletion()
        }
    }

    private func updateModels(newItems: [ChatItemProtocol], oldItems: ChatItemCompanionCollection, updateType: UpdateType, completion: @escaping () -> Void) {
        guard let collectionView = self.collectionView else {
            completion()
            return
        }
        let collectionViewWidth = collectionView.bounds.width
        let updateType = self.isFirstLayout ? .firstLoad : updateType
        let performInBackground = updateType != .firstLoad

        self.autoLoadingEnabled = false
        let perfomBatchUpdates: (_ changes: CollectionChanges, _ updateModelClosure: @escaping () -> Void) -> Void  = { [weak self] (changes, updateModelClosure) in
            self?.performBatchUpdates(
                updateModelClosure: updateModelClosure,
                changes: changes,
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
                collectionViewWidth: collectionViewWidth)
        }

        if performInBackground {
            DispatchQueue.global(qos: .userInitiated).async { () -> Void in
                let modelUpdate = createModelUpdate()
                DispatchQueue.main.async(execute: { () -> Void in
                    perfomBatchUpdates(modelUpdate.changes, modelUpdate.updateModelClosure)
                })
            }
        } else {
            let modelUpdate = createModelUpdate()
            perfomBatchUpdates(modelUpdate.changes, modelUpdate.updateModelClosure)
        }
    }

    private func createModelUpdates(newItems: [ChatItemProtocol], oldItems: ChatItemCompanionCollection, collectionViewWidth: CGFloat) -> (changes: CollectionChanges, updateModelClosure: () -> Void) {
        let newDecoratedItems = self.chatItemsDecorator?.decorateItems(newItems) ?? newItems.map { DecoratedChatItem(chatItem: $0, decorationAttributes: nil) }
        let changes = Chatto.generateChanges(oldCollection: oldItems.map(HashableItem.init),
                                             newCollection: newDecoratedItems.map(HashableItem.init))
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

            /*
             We use an assumption, that message having a specific messageId never changes its type.
             If such changes has to be supported, then generation of changes has to suppport reloading items.
             Otherwise, updateVisibleCells may try to update the existing cells with new presenters which aren't able to work with another types.
             */

            let presenter: ChatItemPresenterProtocol = {
                guard let oldChatItemCompanion = oldItems[decoratedChatItem.uid] ?? oldItems[decoratedChatItem.chatItem.uid],
                    oldChatItemCompanion.chatItem.type == decoratedChatItem.chatItem.type,
                    oldChatItemCompanion.presenter.isItemUpdateSupported else {
                        return self.createPresenterForChatItem(decoratedChatItem.chatItem)
                }

                oldChatItemCompanion.presenter.update(with: decoratedChatItem.chatItem)
                return oldChatItemCompanion.presenter
            }()

            return ChatItemCompanion(uid: decoratedChatItem.uid, chatItem: decoratedChatItem.chatItem, presenter: presenter, decorationAttributes: decoratedChatItem.decorationAttributes)
        })
    }

    private func createLayoutModel(_ items: ChatItemCompanionCollection, collectionViewWidth: CGFloat) -> ChatCollectionViewLayoutModel {
        typealias IntermediateItemLayoutData = (height: CGFloat?, bottomMargin: CGFloat)
        typealias ItemLayoutData = (height: CGFloat, bottomMargin: CGFloat)

        func createLayoutModel(intermediateLayoutData: [IntermediateItemLayoutData]) -> ChatCollectionViewLayoutModel {
            let layoutData = intermediateLayoutData.map { (intermediateLayoutData: IntermediateItemLayoutData) -> ItemLayoutData in
                return (height: intermediateLayoutData.height!, bottomMargin: intermediateLayoutData.bottomMargin)
            }
            return ChatCollectionViewLayoutModel.createModel(collectionViewWidth, itemsLayoutData: layoutData)
        }

        let isInbackground = !Thread.isMainThread
        var intermediateLayoutData = [IntermediateItemLayoutData]()
        var itemsForMainThread = [(index: Int, itemCompanion: ChatItemCompanion)]()

        for (index, itemCompanion) in items.enumerated() {
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
            DispatchQueue.main.sync(execute: { () -> Void in
                for (index, itemCompanion) in itemsForMainThread {
                    let height = itemCompanion.presenter.heightForCell(maximumWidth: collectionViewWidth, decorationAttributes: itemCompanion.decorationAttributes)
                    intermediateLayoutData[index].height = height
                }
            })
        }
        return createLayoutModel(intermediateLayoutData: intermediateLayoutData)
    }

    public func chatCollectionViewLayoutModel() -> ChatCollectionViewLayoutModel {
        guard let collectionView = self.collectionView else { return self.layoutModel }
        if self.layoutModel.calculatedForWidth != collectionView.bounds.width {
            self.layoutModel = self.createLayoutModel(self.chatItemCompanionCollection, collectionViewWidth: collectionView.bounds.width)
        }
        return self.layoutModel
    }

}
