//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public final class NewChatMessageCollectionAdapter: NSObject,
                                                    ChatMessageCollectionAdapterProtocol,
                                                    ChatDataSourceDelegateProtocol,
                                                    ChatCollectionViewLayoutModelProviderProtocol {

    // MARK: - Private type declarations

    private struct ModelUpdates {
        let updateType: UpdateType
        let changes: CollectionChanges
        let collection: ChatItemCompanionCollection
        let layoutModel: ChatCollectionViewLayoutModel
    }

    // MARK: - Private properties

    private let configuration: Configuration
    private let collectionUpdateProvider: CollectionUpdateProviderProtocol
    private let layoutFactory: ChatCollectionViewLayoutModelFactoryProtocol
    private let collectionUpdatesQueue: SerialTaskQueueProtocol
    private let referenceIndexPathRestoreProvider: ReferenceIndexPathRestoreProvider

    // MARK: - State

    private weak var collectionView: UICollectionView?
    private var layoutModel = ChatCollectionViewLayoutModel.createModel(0, itemsLayoutData: [])
    private var nextDidEndScrollingAnimationHandlers: [() -> Void] = []
    private let presentersByCell = NSMapTable<UICollectionViewCell, AnyObject>(keyOptions: .weakMemory, valueOptions: .weakMemory)
    private var visibleCells: [IndexPath: UICollectionViewCell] = [:] // @see visibleCellsAreValid(changes:)

    // MARK: - Instantiation

    init(configuration: Configuration,
         collectionUpdateProvider: CollectionUpdateProviderProtocol,
         collectionUpdatesQueue: SerialTaskQueueProtocol,
         layoutFactory: ChatCollectionViewLayoutModelFactoryProtocol,
         referenceIndexPathRestoreProvider: @escaping ReferenceIndexPathRestoreProvider) {
        self.configuration = configuration
        self.collectionUpdateProvider = collectionUpdateProvider
        self.collectionUpdatesQueue = collectionUpdatesQueue
        self.layoutFactory = layoutFactory
        self.referenceIndexPathRestoreProvider = referenceIndexPathRestoreProvider
    }


    // MARK: - ChatMessageCollectionAdapterProtocol

    public var chatItemCompanionCollection: ChatItemCompanionCollection = ChatItemCompanionCollection(items: [])

    public var delegate: ChatMessageCollectionAdapterDelegate?

    public func startProcessingUpdates() {
        self.collectionUpdatesQueue.start()
    }

    public func stopProcessingUpdates() {
        self.collectionUpdatesQueue.stop()
    }

    public func setup(in collectionView: UICollectionView) {
        self.collectionView = collectionView
        collectionView.dataSource = self
        self.collectionUpdateProvider.setup(in: collectionView)
    }

    public func refreshContent(completionBlock: (() -> Void)?) {
        self.enqueueModelUpdate(type: .normal, completion: completionBlock)
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

    // MARK: - UICollectionViewDataSource

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.chatItemCompanionCollection.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let presenter = self.presenter(for: indexPath)
        let cell = presenter.dequeueCell(collectionView: collectionView, indexPath: indexPath)
        let decorationAttributes = self.chatItemCompanionCollection[indexPath.item].decorationAttributes
        presenter.configureCell(cell, decorationAttributes: decorationAttributes)
        return cell
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView,
                          didEndDisplaying cell: UICollectionViewCell,
                            forItemAt indexPath: IndexPath) {
        // Carefull: this index path can refer to old data source after an update. Don't use it to grab items from the model
        // Instead let's use a mapping presenter <--> cell
        if let oldPresenterForCell = self.presentersByCell.object(forKey: cell) as? ChatItemPresenterProtocol {
            self.presentersByCell.removeObject(forKey: cell)
            oldPresenterForCell.cellWasHidden(cell)
        }

        // TODO: Remove from configuration
        guard self.configuration.fastUpdates else { return }

        if let visibleCell = self.visibleCells[indexPath], visibleCell === cell {
            self.visibleCells[indexPath] = nil
        } else {
            self.visibleCells.forEach { indexPath, storedCell in
                guard cell === storedCell else { return }

                // TODO: Measure how often does it happen
                // Inconsistency found, likely due to very fast updates
                self.visibleCells[indexPath] = nil
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                            forItemAt indexPath: IndexPath) {
        // Here indexPath should always referer to updated data source.
        let presenter = self.presenter(for: indexPath)
        self.presentersByCell.setObject(presenter, forKey: cell)

        // TODO: Remove from configuration
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
        self.presenter(for: indexPath).shouldShowMenu()
    }

    public func collectionView(_ collectionView: UICollectionView,
                        canPerformAction action: Selector,
                            forItemAt indexPath: IndexPath,
                              withSender sender: Any?) -> Bool {
        self.presenter(for: indexPath).canPerformMenuControllerAction(action)
    }

    public func collectionView(_ collectionView: UICollectionView,
                           performAction action: Selector,
                            forItemAt indexPath: IndexPath,
                              withSender sender: Any?) {
        self.presenter(for: indexPath).performMenuControllerAction(action)
    }

    // MARK: - UIScrollViewDelegate

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        for handler in self.nextDidEndScrollingAnimationHandlers {
            handler()
        }
        self.nextDidEndScrollingAnimationHandlers = []
    }

    // MARK: - ChatDataSourceDelegateProtocol

    public func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol) {
        self.enqueueModelUpdate(type: .normal)
    }

    public func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol, updateType: UpdateType) {
        self.enqueueModelUpdate(type: updateType)
    }

    // MARK: - ChatCollectionViewLayoutModelProviderProtocol

    public var chatCollectionViewLayoutModel: ChatCollectionViewLayoutModel {
        guard let collectionView = self.collectionView else { return self.layoutModel }

        if self.layoutModel.calculatedForWidth != collectionView.bounds.width {
            self.updateLayoutModel()
        }
        return self.layoutModel
    }


    // MARK: - Private methods

    private func updateLayoutModel() {
        guard let collectionView = self.collectionView else { return }
        let items = self.chatItemCompanionCollection
        let layoutModel = self.layoutFactory.createLayoutModel(
            items: items,
            collectionViewWidth: collectionView.bounds.width
        )
        self.layoutModel = layoutModel

    }

    private func enqueueModelUpdate(type: UpdateType, completion: (() -> Void)? = nil) {
        let task: TaskClosure = { [weak self] runNextTask in
            self?.updateModels(updateType: type) { [weak self] updates in
                self?.performBatchUpdates(updates: updates) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.chatMessageCollectionAdapterDidUpdateItems(withUpdateType: type)
                    completion?()
                    DispatchQueue.main.async {
                        // Reduces inconsistencies before next update: https://github.com/diegosanchezr/UICollectionViewStressing
                        runNextTask()
                    }
                }
            }
        }
        self.collectionUpdatesQueue.addTask(task)
    }

    private func presenter(for indexPath: IndexPath) -> ChatItemPresenterProtocol {
        let index = indexPath.item
        // This can happen from didEndDisplayingCell if we reloaded with less messages
        guard self.chatItemCompanionCollection.indices.contains(index) else { return DummyChatItemPresenter() }
        return self.chatItemCompanionCollection[index].presenter
    }

    private func performBatchUpdates(updates: ModelUpdates, completion: @escaping () -> Void) {
        guard let collectionView = self.collectionView else { return }

        let updateType = updates.updateType
        let collection = updates.collection
        let changes = updates.changes
        let layout = updates.layoutModel

        let updateModelClosure = { [weak self] in
            guard let self = self else { return }
            self.chatItemCompanionCollection = collection
            self.layoutModel = layout
        }

        let usesBatchUpdates: Bool = {
            let visibleCellsAreValid = self.visibleCellsAreValid(changes: changes)
            let wantsReloadData = updateType != .normal && updateType != .firstSync
            return !wantsReloadData && visibleCellsAreValid
        }()

        let scrollAction: ScrollAction
        do { // Scroll action
            if updateType != .pagination && updateType != .firstSync && collectionView.isScrolledAtBottom() {
                scrollAction = .scrollToBottom
            } else {
                let (oldReferenceIndexPath, newReferenceIndexPath) = self.referenceIndexPathRestoreProvider(collection, changes)
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
            guard let self = self, let collectionView = collectionView else { return }

            switch scrollAction {
            case .scrollToBottom:
                collectionView.scrollToBottom(
                    animated: updateType == .normal,
                    animationDuration: self.configuration.updatesAnimationDuration
                )
            case .preservePosition(let oldRect, let indexPath):
                let newRect = self.rectAtIndexPath(indexPath)
                collectionView.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
            }
        }

        if usesBatchUpdates {
            UIView.animate(
                withDuration: self.configuration.updatesAnimationDuration,
                animations: { [weak self] () -> Void in
                    guard let self = self else { return }

                    collectionView.performBatchUpdates({ [weak self] in
                        guard let self = self else { return }

                        updateModelClosure()
                        self.updateVisibleCells(changes) // For instance, to support removal of tails

                        collectionView.deleteItems(at: Array(changes.deletedIndexPaths))
                        collectionView.insertItems(at: Array(changes.insertedIndexPaths))

                        for move in changes.movedIndexPaths {
                            collectionView.moveItem(at: move.indexPathOld, to: move.indexPathNew)
                        }
                    }, completion: { _ in
                        myCompletion()
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
        }

        adjustScrollViewToBottom()

        if !usesBatchUpdates || self.configuration.fastUpdates {
            myCompletion()
        }
    }

    private func createModelUpdates(updateType: UpdateType) -> ModelUpdates {
        // TODO: Fix fatalError
        guard let collectionView = self.collectionView else { fatalError() }
        let old = self.chatItemCompanionCollection
        let new = self.collectionUpdateProvider.updateCollection(old: old)
        let changes = generateChanges(oldCollection: old.map(HashableItem.init),
                                      newCollection: new.map(HashableItem.init))
        let layoutModel = self.layoutFactory.createLayoutModel(
            items: new,
            collectionViewWidth: collectionView.bounds.width
        )
        return ModelUpdates(
            updateType: updateType,
            changes: changes,
            collection: new,
            layoutModel: layoutModel
        )
    }

    private func updateModels(updateType: UpdateType,
                              completion: @escaping (ModelUpdates) -> Void) {
        let performInBackground = updateType != .firstLoad

        if performInBackground {
            DispatchQueue.global(qos: .userInitiated).async {
                let updates = self.createModelUpdates(updateType: updateType)
                DispatchQueue.main.async {
                    completion(updates)
                }
            }
        } else {
            let updates = self.createModelUpdates(updateType: updateType)
            completion(updates)
        }
    }

    private func rectAtIndexPath(_ indexPath: IndexPath?) -> CGRect? {
        guard let collectionView = self.collectionView else { return nil }
        guard let indexPath = indexPath else { return nil }

        return collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame
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

    private func updateVisibleCells(_ changes: CollectionChanges) {
        // Datasource should be already updated!
        assert(self.visibleCellsAreValid(changes: changes), "Invalid visible cells. Don't call me")

        let cellsToUpdate = updated(collection: self.visibleCellsFromCollectionViewApi(), withChanges: changes)
        self.visibleCells = cellsToUpdate

        cellsToUpdate.forEach { indexPath, cell in
            let presenter = self.presenter(for: indexPath)
            presenter.configureCell(cell, decorationAttributes: self.chatItemCompanionCollection[indexPath.item].decorationAttributes)
            presenter.cellWillBeShown(cell) // `createModelUpdates` may have created a new presenter instance for existing visible cell so we need to tell it that its cell is visible
        }
    }
}

// TODO: Remove later
public extension NewChatMessageCollectionAdapter {
    static func make(configuration: Configuration,
                       updateQueue: SerialTaskQueueProtocol,
          chatItemPresenterFactory: ChatItemPresenterFactoryProtocol,
                chatItemsDecorator: ChatItemsDecoratorProtocol,
 referenceIndexPathRestoreProvider: @escaping ReferenceIndexPathRestoreProvider,
             chatMessagesViewModel: ChatMessagesViewModelProtocol) -> NewChatMessageCollectionAdapter {

        let configuration: NewChatMessageCollectionAdapter.Configuration = .default
        let collectionUpdateProvider = CollectionUpdateProvider(
            configuration: configuration,
            chatItemsDecorator: chatItemsDecorator,
            chatItemPresenterFactory: chatItemPresenterFactory,
            chatMessagesViewModel: chatMessagesViewModel
        )

        let layoutFactory = ChatCollectionViewLayoutModelFactory()

        let adapter = NewChatMessageCollectionAdapter(configuration: configuration,
                                           collectionUpdateProvider: collectionUpdateProvider,
                                             collectionUpdatesQueue: updateQueue,
                                                      layoutFactory: layoutFactory,
                                  referenceIndexPathRestoreProvider: referenceIndexPathRestoreProvider)
        chatMessagesViewModel.delegate = adapter
        return adapter
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

