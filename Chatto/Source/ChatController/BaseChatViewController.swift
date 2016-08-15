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

public class BaseChatViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    public typealias ChatItemCompanionCollection = ReadOnlyOrderedDictionary<ChatItemCompanion>

    public struct Constants {
        public var updatesAnimationDuration: NSTimeInterval = 0.33
        public var defaultContentInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        public var defaultScrollIndicatorInsets = UIEdgeInsetsZero
        public var preferredMaxMessageCount: Int? = 500 // If not nil, will ask data source to reduce number of messages when limit is reached. @see ChatDataSourceDelegateProtocol
        public var preferredMaxMessageCountAdjustment: Int = 400 // When the above happens, will ask to adjust with this value. It may be wise for this to be smaller to reduce number of adjustments
        public var autoloadingFractionalThreshold: CGFloat = 0.05 // in [0, 1]
    }

    public var constants = Constants()

    public struct UpdatesConfig {
        public var fastUpdates = false // Allows another performBatchUpdates to be called before completion of a previous one (not recommended). Changing this value after viewDidLoad is not supported
        public var coalesceUpdates = false // If receiving data source updates too fast, while an update it's being processed, only the last one will be executed
    }

    public var updatesConfig =  UpdatesConfig()

    public private(set) var collectionView: UICollectionView!
    public final internal(set) var chatItemCompanionCollection: ChatItemCompanionCollection = ReadOnlyOrderedDictionary(items: [])
    private var _chatDataSource: ChatDataSourceProtocol?
    public final var chatDataSource: ChatDataSourceProtocol? {
        get {
            return _chatDataSource
        }
        set {
            self.setChatDataSource(newValue, triggeringUpdateType: .Normal)
        }
    }

    // Custom update on setting the data source. if triggeringUpdateType is nil it won't enqueue any update (you should do it later manually)
    public final func setChatDataSource(dataSource: ChatDataSourceProtocol?, triggeringUpdateType updateType: UpdateType?) {
        self._chatDataSource = dataSource
        self._chatDataSource?.delegate = self
        if let updateType = updateType {
            self.enqueueModelUpdate(updateType: updateType)
        }
    }

    deinit {
        self.collectionView?.delegate = nil
        self.collectionView?.dataSource = nil
    }

    public override func loadView() {
        self.view = BaseChatViewControllerView() // http://stackoverflow.com/questions/24596031/uiviewcontroller-with-inputaccessoryview-is-not-deallocated
        self.view.backgroundColor = UIColor.whiteColor()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.addCollectionView()
        self.addInputViews()
        self.setupKeyboardTracker()
        self.setupTapGestureRecognizer()
    }

    private func setupTapGestureRecognizer() {
        self.collectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BaseChatViewController.userDidTapOnCollectionView)))
    }

    public var endsEditingWhenTappingOnChatBackground = true
    @objc
    public func userDidTapOnCollectionView() {
        if self.endsEditingWhenTappingOnChatBackground {
            self.view.endEditing(true)
        }
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.keyboardTracker.startTracking()
    }

    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.keyboardTracker.stopTracking()
    }

    private func addCollectionView() {
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.createCollectionViewLayout)
        self.collectionView.contentInset = self.constants.defaultContentInsets
        self.collectionView.scrollIndicatorInsets = self.constants.defaultScrollIndicatorInsets
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.backgroundColor = UIColor.clearColor()
        self.collectionView.keyboardDismissMode = .Interactive
        self.collectionView.showsVerticalScrollIndicator = true
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.allowsSelection = false
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.autoresizingMask = .None
        self.view.addSubview(self.collectionView)
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Top, relatedBy: .Equal, toItem: self.collectionView, attribute: .Top, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Leading, relatedBy: .Equal, toItem: self.collectionView, attribute: .Leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Bottom, relatedBy: .Equal, toItem: self.collectionView, attribute: .Bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Trailing, relatedBy: .Equal, toItem: self.collectionView, attribute: .Trailing, multiplier: 1, constant: 0))
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.accessoryViewRevealer = AccessoryViewRevealer(collectionView: self.collectionView)

        self.presenterFactory = self.createPresenterFactory()
        self.presenterFactory.configure(withCollectionView: self.collectionView)

        self.automaticallyAdjustsScrollViewInsets = false
    }

    var unfinishedBatchUpdatesCount: Int = 0
    var onAllBatchUpdatesFinished: (() -> Void)?

    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private func addInputViews() {
        self.inputContainer = UIView(frame: CGRect.zero)
        self.inputContainer.autoresizingMask = .None
        self.inputContainer.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.inputContainer)
        self.view.addConstraint(NSLayoutConstraint(item: self.inputContainer, attribute: .Top, relatedBy: .GreaterThanOrEqual, toItem: self.topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Leading, relatedBy: .Equal, toItem: self.inputContainer, attribute: .Leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Trailing, relatedBy: .Equal, toItem: self.inputContainer, attribute: .Trailing, multiplier: 1, constant: 0))
        self.inputContainerBottomConstraint = NSLayoutConstraint(item: self.view, attribute: .Bottom, relatedBy: .Equal, toItem: self.inputContainer, attribute: .Bottom, multiplier: 1, constant: 0)
        self.view.addConstraint(self.inputContainerBottomConstraint)

        let inputView = self.createChatInputView()
        self.inputContainer.addSubview(inputView)
        self.inputContainer.addConstraint(NSLayoutConstraint(item: self.inputContainer, attribute: .Top, relatedBy: .Equal, toItem: inputView, attribute: .Top, multiplier: 1, constant: 0))
        self.inputContainer.addConstraint(NSLayoutConstraint(item: self.inputContainer, attribute: .Leading, relatedBy: .Equal, toItem: inputView, attribute: .Leading, multiplier: 1, constant: 0))
        self.inputContainer.addConstraint(NSLayoutConstraint(item: self.inputContainer, attribute: .Bottom, relatedBy: .Equal, toItem: inputView, attribute: .Bottom, multiplier: 1, constant: 0))
        self.inputContainer.addConstraint(NSLayoutConstraint(item: self.inputContainer, attribute: .Trailing, relatedBy: .Equal, toItem: inputView, attribute: .Trailing, multiplier: 1, constant: 0))
    }

    var isAdjustingInputContainer: Bool = false
    public func setupKeyboardTracker() {
        let layoutBlock = { [weak self] (bottomMargin: CGFloat) in
            guard let sSelf = self else { return }
            sSelf.isAdjustingInputContainer = true
            sSelf.inputContainerBottomConstraint.constant = max(bottomMargin, sSelf.bottomLayoutGuide.length)
            sSelf.view.layoutIfNeeded()
            sSelf.isAdjustingInputContainer = false
        }
        self.keyboardTracker = KeyboardTracker(viewController: self, inputContainer: self.inputContainer, layoutBlock: layoutBlock, notificationCenter: self.notificationCenter)
        (self.view as? BaseChatViewControllerView)?.bmaInputAccessoryView = self.keyboardTracker?.trackingView
    }

    var notificationCenter = NSNotificationCenter.defaultCenter()
    var keyboardTracker: KeyboardTracker!

    public var isFirstLayout: Bool = true
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.adjustCollectionViewInsets()
        self.keyboardTracker.adjustTrackingViewSizeIfNeeded()

        if self.isFirstLayout {
            self.updateQueue.start()
            self.isFirstLayout = false
            // If we have been pushed on nav controller and hidesBottomBarWhenPushed = true, then ignore bottomLayoutMargin
            // because it has incorrect value when we actually have a bottom bar (tabbar)
            if hidesBottomBarWhenPushed && navigationController?.viewControllers.count > 1 && navigationController?.viewControllers.last == self {
                self.inputContainerBottomConstraint.constant = 0
            } else {
                self.inputContainerBottomConstraint.constant = self.bottomLayoutGuide.length
            }
        }
    }

    private func adjustCollectionViewInsets() {
        let isInteracting = self.collectionView.panGestureRecognizer.numberOfTouches() > 0
        let isBouncingAtTop = isInteracting && self.collectionView.contentOffset.y < -self.collectionView.contentInset.top
        if isBouncingAtTop { return }

        let inputHeightWithKeyboard = self.view.bounds.height - self.inputContainer.frame.minY
        let newInsetBottom = self.constants.defaultContentInsets.bottom + inputHeightWithKeyboard
        let insetBottomDiff = newInsetBottom - self.collectionView.contentInset.bottom
        let newInsetTop = self.topLayoutGuide.length + self.constants.defaultContentInsets.top

        let contentSize = self.collectionView.collectionViewLayout.collectionViewContentSize()
        let allContentFits: Bool = {
            let availableHeight = self.collectionView.bounds.height - (newInsetTop + newInsetBottom)
            return availableHeight >= contentSize.height
        }()

        let newContentOffsetY: CGFloat = {
            let minOffset = -newInsetTop
            let maxOffset = contentSize.height - (self.collectionView.bounds.height - newInsetBottom)
            let targetOffset = self.collectionView.contentOffset.y + insetBottomDiff
            return max(min(maxOffset, targetOffset), minOffset)
        }()

        self.collectionView.contentInset = {
            var currentInsets = self.collectionView.contentInset
            currentInsets.bottom = newInsetBottom
            currentInsets.top = newInsetTop
            return currentInsets
        }()

        self.collectionView.scrollIndicatorInsets = {
            var currentInsets = self.collectionView.scrollIndicatorInsets
            currentInsets.bottom = self.constants.defaultScrollIndicatorInsets.bottom + inputHeightWithKeyboard
            currentInsets.top = self.topLayoutGuide.length + self.constants.defaultScrollIndicatorInsets.top
            return currentInsets
        }()

        let inputIsAtBottom = self.view.bounds.maxY - self.inputContainer.frame.maxY <= 0

        if allContentFits {
            self.collectionView.contentOffset.y = -self.collectionView.contentInset.top
        } else if !isInteracting || inputIsAtBottom {
            self.collectionView.contentOffset.y = newContentOffsetY
        }
    }

    func rectAtIndexPath(indexPath: NSIndexPath?) -> CGRect? {
        if let indexPath = indexPath {
            return self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath)?.frame
        }
        return nil
    }

    var autoLoadingEnabled: Bool = false
    var accessoryViewRevealer: AccessoryViewRevealer!
    public private(set) var inputContainer: UIView!
    var presenterFactory: ChatItemPresenterFactoryProtocol!
    let presentersByCell = NSMapTable(keyOptions: .WeakMemory, valueOptions: .WeakMemory)
    var visibleCells: [NSIndexPath: UICollectionViewCell] = [:] // @see visibleCellsAreValid(changes:)

    public internal(set) var updateQueue: SerialTaskQueueProtocol = SerialTaskQueue()

    /**
     - You can use a decorator to:
        - Provide the ChatCollectionViewLayout with margins between messages
        - Provide to your pressenters additional attributes to help them configure their cells (for instance if a bubble should show a tail)
        - You can also add new items (for instance time markers or failed cells)
    */
    public var chatItemsDecorator: ChatItemsDecoratorProtocol?

    public var createCollectionViewLayout: UICollectionViewLayout {
        let layout = ChatCollectionViewLayout()
        layout.delegate = self
        return layout
    }

    var layoutModel = ChatCollectionViewLayoutModel.createModel(0, itemsLayoutData: [])

    // MARK: Subclass overrides

    public func createPresenterFactory() -> ChatItemPresenterFactoryProtocol {
        // Default implementation
        return ChatItemPresenterFactory(presenterBuildersByType: self.createPresenterBuilders())
    }

    public func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        assert(false, "Override in subclass")
        return [ChatItemType: [ChatItemPresenterBuilderProtocol]]()
    }

    public func createChatInputView() -> UIView {
        assert(false, "Override in subclass")
        return UIView()
    }

    /**
        When paginating up we need to change the scroll position as the content is pushed down.
        We take distance to top from beforeUpdate indexPath and then we make afterUpdate indexPath to appear at the same distance
    */
    public func referenceIndexPathsToRestoreScrollPositionOnUpdate(itemsBeforeUpdate itemsBeforeUpdate: ChatItemCompanionCollection, changes: CollectionChanges) -> (beforeUpdate: NSIndexPath?, afterUpdate: NSIndexPath?) {
        let firstItemMoved = changes.movedIndexPaths.first
        return (firstItemMoved?.indexPathOld, firstItemMoved?.indexPathNew)
    }
}

extension BaseChatViewController { // Rotation

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        let shouldScrollToBottom = self.isScrolledAtBottom()
        let referenceIndexPath = self.collectionView.indexPathsForVisibleItems().first
        let oldRect = self.rectAtIndexPath(referenceIndexPath)
        coordinator.animateAlongsideTransition({ (context) -> Void in
            if shouldScrollToBottom {
                self.scrollToBottom(animated: false)
            } else {
                let newRect = self.rectAtIndexPath(referenceIndexPath)
                self.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
            }
        }, completion: nil)
    }
}
