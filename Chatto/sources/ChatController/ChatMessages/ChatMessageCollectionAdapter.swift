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
    func scheduleSpotlight(for itemId: String)
}

public protocol ChatMessageCollectionAdapterDelegate: AnyObject {
    var isFirstLoad: Bool { get }

    func chatMessageCollectionAdapterDidUpdateItems(withUpdateType updateType: UpdateType)
    func chatMessageCollectionAdapterShouldAnimateCellOnDisplay() -> Bool
}

public typealias ReferenceIndexPathRestoreProvider = (ChatItemCompanionCollection, CollectionChanges) -> (IndexPath?, IndexPath?)

// TODO: Add unit tests
/**
 Component responsible to coordinate all chat messages updates and their display logic in a collection view.

 After its initialisation, this component will start observing view model updates and dispatch update operations into the `updateQueue`. Taking into account the initial `configuration` injected into this component, whenever we receive a chat items update call, the elements difference between updates gets calculated and propagated into the collection view.
 In order to decouple this component from the customisation of elements to be displayed, we delegate this responsibility to the `chatItemsDecorator` and `chatItemPresenterFactory` injected during its initialisation. These item customisation components will be used while presenting chat items in the collection view.
 */
public final class ChatMessageCollectionAdapter: NSObject, ChatMessageCollectionAdapterProtocol {

    private let chatItemsDecorator: ChatItemsDecoratorProtocol
    private let chatItemPresenterFactory: ChatItemPresenterFactoryProtocol
    private let chatMessagesViewModel: ChatMessagesViewModelProtocol
    private let collectionViewLayoutModelFactory: ChatCollectionViewLayoutModelFactoryProtocol
    private let configuration: Configuration
    private let referenceIndexPathRestoreProvider: ReferenceIndexPathRestoreProvider
    private let collectionUpdatesQueue: SerialTaskQueueProtocol

    private var nextDidEndScrollingAnimationHandlers: [() -> Void]
    private var isFirstUpdate: Bool // TODO: To remove
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
                referenceIndexPathRestoreProvider: @escaping ReferenceIndexPathRestoreProvider,
                updateQueue: SerialTaskQueueProtocol,
                collectionViewLayoutModelFactory: ChatCollectionViewLayoutModelFactoryProtocol = ChatCollectionViewLayoutModelFactory()) {
        self.chatItemsDecorator = chatItemsDecorator
        self.chatItemPresenterFactory = chatItemPresenterFactory
        self.chatMessagesViewModel = chatMessagesViewModel
        self.collectionViewLayoutModelFactory = collectionViewLayoutModelFactory
        self.configuration = configuration
        self.referenceIndexPathRestoreProvider = referenceIndexPathRestoreProvider
        self.collectionUpdatesQueue = updateQueue

        self.isFirstUpdate = true
        self.isLoadingContents = true
        self.nextDidEndScrollingAnimationHandlers = []

        super.init()

        self.configureChatMessagesViewModel()
    }

    public func startProcessingUpdates() {
        self.collectionUpdatesQueue.start()
    }

    public func stopProcessingUpdates() {
        self.collectionUpdatesQueue.stop()
    }

    private func configureChatMessagesViewModel() {
        self.chatMessagesViewModel.delegate = self
    }

    public func setup(in collectionView: UICollectionView) {
        collectionView.dataSource = self

        if self.configuration.isRegisteringPresentersAutomatically {
            self.chatItemPresenterFactory.configure(withCollectionView: collectionView)
        }

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
        if !self.configuration.isRegisteringPresentersAutomatically
           && self.isFirstUpdate,
           let collectionView = self.collectionView {

            self.chatItemPresenterFactory.configure(withCollectionView: collectionView)
            self.isFirstUpdate = false
        }
        self.enqueueModelUpdate(updateType: updateType)
    }

    private func enqueueModelUpdate(updateType: UpdateType, completionBlock: (() -> Void)? = nil) {
        if self.configuration.coalesceUpdates {
            self.collectionUpdatesQueue.flushQueue()
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

                if sSelf.collectionUpdatesQueue.isEmpty {
                    sSelf.enqueueMessageCountReductionIfNeeded()
                }

                sSelf.delegate?.chatMessageCollectionAdapterDidUpdateItems(withUpdateType: updateType)
                completionBlock?()
                DispatchQueue.main.async {
                    // Reduces inconsistencies before next update: https://github.com/diegosanchezr/UICollectionViewStressing
                    runNextTask()
                }
            }
        }

        self.collectionUpdatesQueue.addTask(updateBlock)
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
        let performBatchUpdates: (ChatCollectionItemsDiffer.Diff) -> Void = { [weak self] diff in
            self?.performBatchUpdates(
                updateModelClosure: { [weak self] in
                    self?.layoutModel = diff.layoutModel
                    self?.chatItemCompanionCollection = diff.itemCompanionCollection
                },
                changes: diff.changes,
                updateType: updateType
            ) {
                self?.isLoadingContents = false
                completion()
            }
        }


        let layoutModelsProcessor = ChatCollectionItemsDiffer(
            chatItemsDecorator: self.chatItemsDecorator,
            chatItemPresenterFactory: self.chatItemPresenterFactory,
            chatCollectionViewLayoutModelFactory: self.collectionViewLayoutModelFactory
        )

        let createCollectionItemsDiffBlock: () -> ChatCollectionItemsDiffer.Diff? = {
            return layoutModelsProcessor.calculateChanges(
                newItems: newItems,
                oldItems: oldItems,
                collectionViewWidth: collectionViewWidth
            )
        }

        if performInBackground {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let collectionItemsDiff = createCollectionItemsDiffBlock() else { return }

                DispatchQueue.main.async {
                    performBatchUpdates(collectionItemsDiff)
                }
            }
        } else {
            guard let collectionItemsDiff = createCollectionItemsDiffBlock() else { return }
            
            performBatchUpdates(collectionItemsDiff)
        }
    }

    private func enqueueMessageCountReductionIfNeeded() {
        let chatItems = self.chatMessagesViewModel.chatItems

        guard let preferredMaxMessageCount = self.configuration.preferredMaxMessageCount,
              chatItems.count > preferredMaxMessageCount else { return }

        self.collectionUpdatesQueue.addTask { [weak self] completion in
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
                let (oldReferenceIndexPath, newReferenceIndexPath) = self.referenceIndexPathRestoreProvider(self.chatItemCompanionCollection, changes)
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

        let adjustScrollViewToBottom = { [weak self, weak collectionView] in
            guard let sSelf = self, let collectionView = collectionView else { return }

            switch scrollAction {
            case .scrollToBottom:
                collectionView.scrollToBottom(
                    animated: updateType == .normal,
                    animationDuration: sSelf.configuration.updatesAnimationDuration
                )
            case .preservePosition(let oldRect, let indexPath):
                let newRect = sSelf.rectAtIndexPath(indexPath)
                collectionView.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
            }
        }

        if usesBatchUpdates {
            UIView.animate(
                withDuration: self.configuration.updatesAnimationDuration,
                animations: { [weak self] () -> Void in
                    guard let sSelf = self else { return }

                    sSelf.unfinishedBatchUpdatesCount += 1

                    collectionView.performBatchUpdates({ [weak self] in
                        guard let sSelf = self else { return }

                        updateModelClosure()
                        sSelf.updateVisibleCells(changes) // For instance, to support removal of tails

                        collectionView.deleteItems(at: Array(changes.deletedIndexPaths))
                        collectionView.insertItems(at: Array(changes.insertedIndexPaths))

                        for move in changes.movedIndexPaths {
                            collectionView.moveItem(at: move.indexPathOld, to: move.indexPathNew)
                        }
                    }, completion: { [weak self] _ in
                        defer { myCompletion() }

                        guard let sSelf = self else { return }

                        sSelf.unfinishedBatchUpdatesCount -= 1
                        if sSelf.unfinishedBatchUpdatesCount == 0, let onAllBatchUpdatesFinished = self?.onAllBatchUpdatesFinished {
                            DispatchQueue.main.async(execute: onAllBatchUpdatesFinished)
                        }

                        adjustScrollViewToBottom()
                    })
                }
            )
        } else {
            self.visibleCells = [:]
            updateModelClosure()
            collectionView.reloadData()
            collectionView.collectionViewLayout.prepare()

            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
            adjustScrollViewToBottom()
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

    private func presenterForIndexPath(_ indexPath: IndexPath) -> ChatItemPresenterProtocol {
        return self.presenterForIndex(
            indexPath.item,
            chatItemCompanionCollection: self.chatItemCompanionCollection
        )
    }

    private func presenterForIndex(_ index: Int, chatItemCompanionCollection items: ChatItemCompanionCollection) -> ChatItemPresenterProtocol {
        // This can happen from didEndDisplayingCell if we reloaded with less messages
        return index < items.count ? items[index].presenter : DummyChatItemPresenter()
    }
}

extension ChatMessageCollectionAdapter: ChatCollectionViewLayoutModelProviderProtocol {
    public var chatCollectionViewLayoutModel: ChatCollectionViewLayoutModel {
        guard let collectionView = self.collectionView else { return self.layoutModel }

        if self.layoutModel.calculatedForWidth != collectionView.bounds.width {
            self.layoutModel = self.collectionViewLayoutModelFactory.createLayoutModel(
                self.chatItemCompanionCollection,
                collectionViewWidth: collectionView.bounds.width
            )
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

        let shouldAnimate = self.delegate?.chatMessageCollectionAdapterShouldAnimateCellOnDisplay() ?? false
        if !shouldAnimate {
            UIView.performWithoutAnimation {
                // See https://github.com/badoo/Chatto/issues/133
                presenter.cellWillBeShown(cell)
                cell.layoutIfNeeded()
            }
        } else {
            presenter.cellWillBeShown(cell)
        }
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

public extension ChatMessageCollectionAdapter {
    struct Configuration {
        public var autoloadingFractionalThreshold: CGFloat
        public var coalesceUpdates: Bool
        public var fastUpdates: Bool
        public var isRegisteringPresentersAutomatically: Bool
        public var preferredMaxMessageCount: Int?
        public var preferredMaxMessageCountAdjustment: Int
        public var updatesAnimationDuration: TimeInterval

        public init(autoloadingFractionalThreshold: CGFloat,
                    coalesceUpdates: Bool,
                    fastUpdates: Bool,
                    isRegisteringPresentersAutomatically: Bool,
                    preferredMaxMessageCount: Int?,
                    preferredMaxMessageCountAdjustment: Int,
                    updatesAnimationDuration: TimeInterval) {
            self.autoloadingFractionalThreshold = autoloadingFractionalThreshold
            self.coalesceUpdates = coalesceUpdates
            self.fastUpdates = fastUpdates
            self.isRegisteringPresentersAutomatically = isRegisteringPresentersAutomatically
            self.preferredMaxMessageCount = preferredMaxMessageCount
            self.preferredMaxMessageCountAdjustment = preferredMaxMessageCountAdjustment
            self.updatesAnimationDuration = updatesAnimationDuration
        }
    }
}

public extension ChatMessageCollectionAdapter.Configuration {
    static var `default`: Self {
        return .init(
            autoloadingFractionalThreshold: 0.05,
            coalesceUpdates: true,
            fastUpdates: true,
            isRegisteringPresentersAutomatically: true,
            preferredMaxMessageCount: 500,
            preferredMaxMessageCountAdjustment: 400,
            updatesAnimationDuration: 0.33
        )
    }
}

private enum ScrollAction {
    case scrollToBottom
    case preservePosition(rectForReferenceIndexPathBeforeUpdate: CGRect?, referenceIndexPathAfterUpdate: IndexPath?)
}

public final class ReferenceIndexPathRestoreProviderFactory {
    public static func makeDefault() -> ReferenceIndexPathRestoreProvider {
        return { itemsBeforeUpdate, changes in
            let firstItemMoved = changes.movedIndexPaths.first
            return (firstItemMoved?.indexPathOld as IndexPath?, firstItemMoved?.indexPathNew as IndexPath?)
        }
    }
}
