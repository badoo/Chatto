//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import UIKit

public protocol ChatMessageCollectionAdapterProtocol: UICollectionViewDataSource, UICollectionViewDelegate {
    var chatItemCompanionCollection: ChatItemCompanionCollection { get }
    var delegate: ChatMessageCollectionAdapterDelegate? { get set }

    func startProcessingUpdates()
    func stopProcessingUpdates()
    func setup(in collectionView: UICollectionView)

    // TODO: Remove from the adapter
    func indexPath(of itemId: String) -> IndexPath?
    func refreshContent(completionBlock: (() -> Void)?)
    func scheduleSpotlight(for: String)
}

public protocol ChatMessageCollectionAdapterDelegate: AnyObject {
    var isFirstLoad: Bool { get }

    func chatMessageCollectionAdapter(_ : ChatMessageCollectionAdapterProtocol, onDisplayCellWithIndexPath: IndexPath)
    func chatMessageCollectionAdapter(_ : ChatMessageCollectionAdapter, didUpdateItemsWithUpdateType: UpdateType)

    func chatMessageCollectionAdapterShouldAnimateCellOnDisplay(_ : ChatMessageCollectionAdapterProtocol) -> Bool
}

public final class ChatMessageCollectionAdapter: NSObject, ChatMessageCollectionAdapterProtocol {

    private let chatItemsDecorator: ChatItemsDecoratorProtocol
    private let chatItemPresenterFactory: ChatItemPresenterFactoryProtocol
    private let chatMessagesViewModel: ChatMessagesViewModelProtocol
    private let configuration: Configuration
    private let updateQueue: SerialTaskQueueProtocol

    private var nextDidEndScrollingAnimationHandlers: [() -> Void]
    private weak var collectionView: UICollectionView?

    public weak var delegate: ChatMessageCollectionAdapterDelegate?

    // TODO: Check properties that can be moved to private
    private(set) var isLoadingContents: Bool
    private(set) var layoutModel = ChatCollectionViewLayoutModel.createModel(0, itemsLayoutData: [])
    private(set) var onAllBatchUpdatesFinished: (() -> Void)?
    private(set) var unfinishedBatchUpdatesCount: Int = 0
    private(set) var visibleCells: [IndexPath: UICollectionViewCell] = [:] // @see visibleCellsAreValid(changes:)
    private let presentersByCell = NSMapTable<UICollectionViewCell, AnyObject>(keyOptions: .weakMemory, valueOptions: .weakMemory)

    public private(set) var chatItemCompanionCollection = ChatItemCompanionCollection(items: [])

    public init(chatItemsDecorator: ChatItemsDecoratorProtocol,
                chatItemPresenterFactory: ChatItemPresenterFactoryProtocol,
                chatMessagesViewModel: ChatMessagesViewModelProtocol,
                configuration: Configuration,
                updateQueue: SerialTaskQueueProtocol) {
        self.chatItemsDecorator = chatItemsDecorator
        self.chatItemPresenterFactory = chatItemPresenterFactory
        self.chatMessagesViewModel = chatMessagesViewModel
        self.configuration = configuration
        self.updateQueue = updateQueue

        self.isLoadingContents = true
        self.nextDidEndScrollingAnimationHandlers = []

        super.init()

        self.configureChatMessagesViewModel()
    }

    public func startProcessingUpdates() {
        self.updateQueue.start()
    }

    public func stopProcessingUpdates() {
        self.updateQueue.stop()
    }

    private func configureChatMessagesViewModel() {
        self.chatMessagesViewModel.delegate = self
    }

    public func setup(in collectionView: UICollectionView) {
        collectionView.dataSource = self
        self.chatItemPresenterFactory.configure(withCollectionView: collectionView)

        self.collectionView = collectionView
    }

    // TODO: Proxy
    public func indexPath(of itemId: String) -> IndexPath? {
        guard let itemIndex = self.chatItemCompanionCollection.indexOf(itemId) else {
            return nil
        }

        return IndexPath(row: itemIndex, section: 0)
    }

    public func refreshContent(completionBlock: (() -> Void)?) {
        self.enqueueModelUpdate(updateType: .normal, completionBlock: completionBlock)
    }

    public func scheduleSpotlight(for itemId: String) {
        guard let collectionView = self.collectionView else { return }
        guard let itemIndexPath = self.indexPath(of: itemId) else { return }
        guard let presenter = self.chatItemCompanionCollection[itemId]?.presenter else { return }

        let contentOffsetWillBeChanged = !collectionView.indexPathsForVisibleItems.contains(itemIndexPath)

        if contentOffsetWillBeChanged {
            self.nextDidEndScrollingAnimationHandlers.append { [weak presenter] in
                presenter?.spotlight()
            }
        } else {
            presenter.spotlight()
        }
    }
}

extension ChatMessageCollectionAdapter: ChatDataSourceDelegateProtocol {
    public func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol) {
        self.enqueueModelUpdate(updateType: .normal)
    }

    public func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol, updateType: UpdateType) {
        self.enqueueModelUpdate(updateType: updateType)
    }

    private func enqueueModelUpdate(updateType: UpdateType, completionBlock: (() -> Void)? = nil) {
        if self.configuration.coalesceUpdates {
            self.updateQueue.flushQueue()
        }

        let updateBlock: TaskClosure = { [weak self] runNextTask in
            guard let sSelf = self else { return }

            let oldItems = sSelf.chatItemCompanionCollection
            let newItems = sSelf.chatMessagesViewModel.chatItems
            sSelf.updateModels(
                newItems: newItems,
                oldItems: oldItems,
                updateType: updateType
            ) {
                guard let sSelf = self else { return }
                if sSelf.updateQueue.isEmpty {
                    sSelf.enqueueMessageCountReductionIfNeeded()
                }

                self?.delegate?.chatMessageCollectionAdapter(
                    sSelf,
                    didUpdateItemsWithUpdateType: updateType
                )
                completionBlock?()
                DispatchQueue.main.async {
                    // Reduces inconsistencies before next update: https://github.com/diegosanchezr/UICollectionViewStressing
                    runNextTask()
                }
            }
        }

        self.updateQueue.addTask(updateBlock)
    }

    private func updateModels(newItems: [ChatItemProtocol],
                              oldItems: ChatItemCompanionCollection,
                              updateType: UpdateType,
                              completion: @escaping () -> Void) {
        guard let collectionView = self.collectionView else {
            completion()
            return
        }

        let collectionViewWidth = collectionView.bounds.width
        let updateType: UpdateType = (self.delegate?.isFirstLoad == true) ? .firstLoad : updateType
        let performInBackground = updateType != .firstLoad

        self.isLoadingContents = true
        let performBatchUpdates: (CollectionChanges, @escaping () -> Void) -> Void  = { [weak self] changes, updateModelClosure in
            self?.performBatchUpdates(
                updateModelClosure: updateModelClosure,
                changes: changes,
                updateType: updateType
            ) {
                self?.isLoadingContents = false
                completion()
            }
        }

        let createModelUpdate = {
            return self.createModelUpdates(
                newItems: newItems,
                oldItems: oldItems,
                collectionViewWidth: collectionViewWidth
            )
        }

        if performInBackground {
            DispatchQueue.global(qos: .userInitiated).async {
                let modelUpdate = createModelUpdate()
                DispatchQueue.main.async {
                    performBatchUpdates(modelUpdate.changes, modelUpdate.updateModelClosure)
                }
            }
        } else {
            let modelUpdate = createModelUpdate()
            performBatchUpdates(modelUpdate.changes, modelUpdate.updateModelClosure)
        }
    }

    private func enqueueMessageCountReductionIfNeeded() {
        let chatItems = self.chatMessagesViewModel.chatItems

        guard let preferredMaxMessageCount = self.configuration.preferredMaxMessageCount,
              chatItems.count > preferredMaxMessageCount else { return }

        self.updateQueue.addTask { [weak self] completion in
            guard let sSelf = self else { return }

            sSelf.chatMessagesViewModel.adjustNumberOfMessages(
                preferredMaxCount: sSelf.configuration.preferredMaxMessageCountAdjustment,
                focusPosition: sSelf.focusPosition
            ) { didAdjust in
                guard didAdjust, let sSelf = self else {
                    completion()
                    return
                }
                let newItems = sSelf.chatMessagesViewModel.chatItems
                let oldItems = sSelf.chatItemCompanionCollection
                sSelf.updateModels(
                    newItems: newItems,
                    oldItems: oldItems,
                    updateType: .messageCountReduction,
                    completion: completion
                )
            }
        }
    }

    private func createModelUpdates(newItems: [ChatItemProtocol], oldItems: ChatItemCompanionCollection, collectionViewWidth: CGFloat) -> (changes: CollectionChanges, updateModelClosure: () -> Void) {
        let newDecoratedItems = self.chatItemsDecorator.decorateItems(newItems)
        let changes = generateChanges(
            oldCollection: oldItems.map(HashableItem.init),
            newCollection: newDecoratedItems.map(HashableItem.init)
        )
        let itemCompanionCollection = self.createCompanionCollection(fromChatItems: newDecoratedItems, previousCompanionCollection: oldItems)
        let layoutModel = self.createLayoutModel(itemCompanionCollection, collectionViewWidth: collectionViewWidth)
        let updateModelClosure : () -> Void = { [weak self] in
            self?.layoutModel = layoutModel
            self?.chatItemCompanionCollection = itemCompanionCollection
        }
        return (changes, updateModelClosure)
    }

    // Returns scrolling position in interval [0, 1], 0 top, 1 bottom
    public var focusPosition: Double {
        guard let collectionView = self.collectionView else { return 0 }

        if collectionView.isCloseToBottom(threshold: self.configuration.autoloadingFractionalThreshold) {
            return 1
        }

        if collectionView.isCloseToTop(threshold: self.configuration.autoloadingFractionalThreshold) {
            return 0
        }

        let contentHeight = collectionView.contentSize.height
        guard contentHeight > 0 else {
            return 0.5
        }

        // Rough estimation
        let collectionViewContentYOffset = collectionView.contentOffset.y
        let midContentOffset = collectionViewContentYOffset + collectionView.visibleRect().height / 2
        return min(max(0, Double(midContentOffset / contentHeight)), 1.0)
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
                        return self.chatItemPresenterFactory.createChatItemPresenter(decoratedChatItem.chatItem)
                }

                oldChatItemCompanion.presenter.update(with: decoratedChatItem.chatItem)
                return oldChatItemCompanion.presenter
            }()

            return ChatItemCompanion(uid: decoratedChatItem.uid, chatItem: decoratedChatItem.chatItem, presenter: presenter, decorationAttributes: decoratedChatItem.decorationAttributes)
        })
    }

    private func createLayoutModel(_ items: ChatItemCompanionCollection, collectionViewWidth: CGFloat) -> ChatCollectionViewLayoutModel {
        // swiftlint:disable:next nesting
        typealias IntermediateItemLayoutData = (height: CGFloat?, bottomMargin: CGFloat)
        typealias ItemLayoutData = (height: CGFloat, bottomMargin: CGFloat)
        // swiftlint:disable:previous nesting

        func createLayoutModel(intermediateLayoutData: [IntermediateItemLayoutData]) -> ChatCollectionViewLayoutModel {
            let layoutData = intermediateLayoutData.map { (intermediateLayoutData: IntermediateItemLayoutData) -> ItemLayoutData in
                return (height: intermediateLayoutData.height!, bottomMargin: intermediateLayoutData.bottomMargin)
            }
            return ChatCollectionViewLayoutModel.createModel(collectionViewWidth, itemsLayoutData: layoutData)
        }

        let isInBackground = !Thread.isMainThread
        var intermediateLayoutData = [IntermediateItemLayoutData]()
        var itemsForMainThread = [(index: Int, itemCompanion: ChatItemCompanion)]()

        for (index, itemCompanion) in items.enumerated() {
            var height: CGFloat?
            let bottomMargin: CGFloat = itemCompanion.decorationAttributes?.bottomMargin ?? 0
            if !isInBackground || itemCompanion.presenter.canCalculateHeightInBackground {
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

    private func performBatchUpdates(updateModelClosure: @escaping () -> Void, // swiftlint:disable:this cyclomatic_complexity
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
                    self?.performBatchUpdates(
                        updateModelClosure: updateModelClosure,
                        changes: changes,
                        updateType: updateType,
                        completion: completion
                    )
                }
                return
            }
            // ... if they are still invalid the only thing we can do is a reloadData
            let mustDoReloadData = !visibleCellsAreValid // Only way to recover from this inconsistent state
            usesBatchUpdates = !wantsReloadData && !mustDoReloadData
        }

        let scrollAction: ScrollAction
        do { // Scroll action
            if updateType != .pagination && collectionView.isScrolledAtBottom() {
                scrollAction = .scrollToBottom
            } else {
                let (oldReferenceIndexPath, newReferenceIndexPath) = self.referenceIndexPathsToRestoreScrollPositionOnUpdate(itemsBeforeUpdate: self.chatItemCompanionCollection, changes: changes)
                let oldRect = self.rectAtIndexPath(oldReferenceIndexPath)
                scrollAction = .preservePosition(
                    rectForReferenceIndexPathBeforeUpdate: oldRect,
                    referenceIndexPathAfterUpdate: newReferenceIndexPath
                )
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
            UIView.animate(withDuration: self.configuration.updatesAnimationDuration, animations: { () -> Void in
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
            })
        } else {
            self.visibleCells = [:]
            updateModelClosure()
            collectionView.reloadData()
            collectionView.collectionViewLayout.prepare()
        }

        switch scrollAction {
        case .scrollToBottom:
            collectionView.scrollToBottom(
                animated: updateType == .normal,
                animationDuration: self.configuration.updatesAnimationDuration
            )
        case .preservePosition(rectForReferenceIndexPathBeforeUpdate: let oldRect, referenceIndexPathAfterUpdate: let indexPath):
            let newRect = self.rectAtIndexPath(indexPath)

            collectionView.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
        }

        if !usesBatchUpdates || self.configuration.fastUpdates {
            myCompletion()
        }
    }

    private func visibleCellsAreValid(changes: CollectionChanges) -> Bool {
        guard self.configuration.fastUpdates else {
            return true
        }

        // After performBatchUpdates, indexPathForCell may return a cell refering to the state before the update
        // if self.updatesConfig.fastUpdates is enabled, very fast updates could result in `updateVisibleCells` updating wrong cells.
        // See more: https://github.com/diegosanchezr/UICollectionViewStressing
        let updatesFromVisibleCells = updated(collection: self.visibleCells, withChanges: changes)
        let updatesFromCollectionViewApi = updated(collection: self.visibleCellsFromCollectionViewApi(), withChanges: changes)

        return updatesFromVisibleCells == updatesFromCollectionViewApi
    }

    private func visibleCellsFromCollectionViewApi() -> [IndexPath: UICollectionViewCell] {
        guard let collectionView = self.collectionView else { return [:] }

        var visibleCells: [IndexPath: UICollectionViewCell] = [:]
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let cell = collectionView.cellForItem(at: indexPath) else { return }

            visibleCells[indexPath] = cell
        }

        return visibleCells
    }

    private func referenceIndexPathsToRestoreScrollPositionOnUpdate(itemsBeforeUpdate: ChatItemCompanionCollection, changes: CollectionChanges) -> (beforeUpdate: IndexPath?, afterUpdate: IndexPath?) {
        let firstItemMoved = changes.movedIndexPaths.first
        return (firstItemMoved?.indexPathOld as IndexPath?, firstItemMoved?.indexPathNew as IndexPath?)
    }

    private func rectAtIndexPath(_ indexPath: IndexPath?) -> CGRect? {
        guard let collectionView = self.collectionView else { return nil }
        guard let indexPath = indexPath else { return nil }

        return collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame
    }

    private func updateVisibleCells(_ changes: CollectionChanges) {
        // Datasource should be already updated!
        assert(self.visibleCellsAreValid(changes: changes), "Invalid visible cells. Don't call me")

        let cellsToUpdate = updated(collection: self.visibleCellsFromCollectionViewApi(), withChanges: changes)
        self.visibleCells = cellsToUpdate

        cellsToUpdate.forEach { (indexPath, cell) in
            let presenter = self.presenterForIndex(
                indexPath.item,
                chatItemCompanionCollection: self.chatItemCompanionCollection
            )
            presenter.configureCell(cell, decorationAttributes: self.chatItemCompanionCollection[indexPath.item].decorationAttributes)
            presenter.cellWillBeShown(cell) // `createModelUpdates` may have created a new presenter instance for existing visible cell so we need to tell it that its cell is visible
        }
    }

    func presenterForIndexPath(_ indexPath: IndexPath) -> ChatItemPresenterProtocol {
        return self.presenterForIndex(
            indexPath.item,
            chatItemCompanionCollection: self.chatItemCompanionCollection
        )
    }

    func presenterForIndex(_ index: Int, chatItemCompanionCollection items: ChatItemCompanionCollection) -> ChatItemPresenterProtocol {
        // This can happen from didEndDisplayingCell if we reloaded with less messages
        return index < items.count ? items[index].presenter : DummyChatItemPresenter()
    }
}

extension ChatMessageCollectionAdapter: ChatCollectionViewLayoutDelegate {
    public func chatCollectionViewLayoutModel() -> ChatCollectionViewLayoutModel {
        guard let collectionView = self.collectionView else { return self.layoutModel }

        if self.layoutModel.calculatedForWidth != collectionView.bounds.width {
            self.layoutModel = self.createLayoutModel(self.chatItemCompanionCollection, collectionViewWidth: collectionView.bounds.width)
        }
        return self.layoutModel
    }
}

extension ChatMessageCollectionAdapter {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.chatItemCompanionCollection.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let presenter = self.presenterForIndexPath(indexPath)
        let cell = presenter.dequeueCell(collectionView: collectionView, indexPath: indexPath)
        let decorationAttributes = self.chatItemCompanionCollection[indexPath.item].decorationAttributes
        presenter.configureCell(cell, decorationAttributes: decorationAttributes)
            return cell
    }
}

extension ChatMessageCollectionAdapter {

    public func collectionView(_ collectionView: UICollectionView,
                               didEndDisplaying cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        // Carefull: this index path can refer to old data source after an update. Don't use it to grab items from the model
        // Instead let's use a mapping presenter <--> cell
        if let oldPresenterForCell = self.presentersByCell.object(forKey: cell) as? ChatItemPresenterProtocol {
            self.presentersByCell.removeObject(forKey: cell)
            oldPresenterForCell.cellWasHidden(cell)
        }

        guard self.configuration.fastUpdates else { return }

        if let visibleCell = self.visibleCells[indexPath], visibleCell === cell {
            self.visibleCells[indexPath] = nil
        } else {
            self.visibleCells.forEach { indexPath, storedCell in
                guard cell === storedCell else { return }

                // Inconsistency found, likely due to very fast updates
                self.visibleCells[indexPath] = nil
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        // Here indexPath should always referer to updated data source.
        let presenter = self.presenterForIndexPath(indexPath)
        self.presentersByCell.setObject(presenter, forKey: cell)

        if self.configuration.fastUpdates {
            self.visibleCells[indexPath] = cell
        }

        let shouldAnimate = self.delegate?.chatMessageCollectionAdapterShouldAnimateCellOnDisplay(self) ?? false
        if !shouldAnimate {
            UIView.performWithoutAnimation {
                // See https://github.com/badoo/Chatto/issues/133
                presenter.cellWillBeShown(cell)
                cell.layoutIfNeeded()
            }
        } else {
            presenter.cellWillBeShown(cell)
        }

        self.delegate?.chatMessageCollectionAdapter(
            self,
            onDisplayCellWithIndexPath: indexPath
        )
    }

    public func collectionView(_ collectionView: UICollectionView,
                               shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return self.presenterForIndexPath(indexPath).shouldShowMenu()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               canPerformAction action: Selector,
                               forItemAt indexPath: IndexPath,
                               withSender sender: Any?) -> Bool {
        return self.presenterForIndexPath(indexPath).canPerformMenuControllerAction(action)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               performAction action: Selector,
                               forItemAt indexPath: IndexPath,
                               withSender sender: Any?) {
        self.presenterForIndexPath(indexPath).performMenuControllerAction(action)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        for handler in self.nextDidEndScrollingAnimationHandlers {
            handler()
        }
        self.nextDidEndScrollingAnimationHandlers = []
    }
}

extension ChatMessageCollectionAdapter {
    public struct Configuration {
        var autoloadingFractionalThreshold: CGFloat
        var coalesceUpdates: Bool
        var fastUpdates: Bool
        var preferredMaxMessageCount: Int?
        var preferredMaxMessageCountAdjustment: Int
        var updatesAnimationDuration: TimeInterval

        public init(autoloadingFractionalThreshold: CGFloat,
                    coalesceUpdates: Bool,
                    fastUpdates: Bool,
                    preferredMaxMessageCount: Int?,
                    preferredMaxMessageCountAdjustment: Int,
                    updatesAnimationDuration: TimeInterval) {
            self.autoloadingFractionalThreshold = autoloadingFractionalThreshold
            self.coalesceUpdates = coalesceUpdates
            self.fastUpdates = fastUpdates
            self.preferredMaxMessageCount = preferredMaxMessageCount
            self.preferredMaxMessageCountAdjustment = preferredMaxMessageCountAdjustment
            self.updatesAnimationDuration = updatesAnimationDuration
        }
    }
}

struct HashableItem: Hashable {
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

private enum ScrollAction {
    case scrollToBottom
    case preservePosition(rectForReferenceIndexPathBeforeUpdate: CGRect?, referenceIndexPathAfterUpdate: IndexPath?)
}
