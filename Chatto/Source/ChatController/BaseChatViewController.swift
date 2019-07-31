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

public protocol KeyboardEventsHandling: AnyObject {
    func onKeyboardStateDidChange(_ height: CGFloat, _ status: KeyboardStatus)
}

public protocol ScrollViewEventsHandling: AnyObject {
    func onScrollViewDidScroll(_ scrollView: UIScrollView)
    func onScrollViewDidEndDragging(_ scrollView: UIScrollView, _ decelerate: Bool)
}

open class BaseChatViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ChatDataSourceDelegateProtocol, InputPositionControlling {

    open weak var keyboardEventsHandler: KeyboardEventsHandling?
    open weak var scrollViewEventsHandler: ScrollViewEventsHandling?

    open var layoutConfiguration: ChatLayoutConfigurationProtocol = ChatLayoutConfiguration.defaultConfiguration {
        didSet {
            self.adjustCollectionViewInsets(shouldUpdateContentOffset: false)
        }
    }

    public struct Constants {
        public var updatesAnimationDuration: TimeInterval = 0.33
        public var preferredMaxMessageCount: Int? = 500 // If not nil, will ask data source to reduce number of messages when limit is reached. @see ChatDataSourceDelegateProtocol
        public var preferredMaxMessageCountAdjustment: Int = 400 // When the above happens, will ask to adjust with this value. It may be wise for this to be smaller to reduce number of adjustments
        public var autoloadingFractionalThreshold: CGFloat = 0.05 // in [0, 1]
    }

    public var constants = Constants()

    public struct UpdatesConfig {

        // Allows another performBatchUpdates to be called before completion of a previous one (not recommended).
        // Changing this value after viewDidLoad is not supported
        public var fastUpdates = true

        // If receiving data source updates too fast, while an update it's being processed, only the last one will be executed
        public var coalesceUpdates = true
    }

    public var updatesConfig =  UpdatesConfig()

    open var customPresentersConfigurationPoint = false // If true then confugureCollectionViewWithPresenters() will not be called in viewDidLoad() method and has to be called manually

    public private(set) var collectionView: UICollectionView?
    public final internal(set) var chatItemCompanionCollection = ChatItemCompanionCollection(items: [])
    private var _chatDataSource: ChatDataSourceProtocol?
    public final var chatDataSource: ChatDataSourceProtocol? {
        get {
            return _chatDataSource
        }
        set {
            self.setChatDataSource(newValue, triggeringUpdateType: .normal)
        }
    }

    // If set to false messages will start appearing on top and goes down
    // If true then messages will start from bottom and goes up.
    public var placeMessagesFromBottom = false {
        didSet {
            self.adjustCollectionViewInsets(shouldUpdateContentOffset: false)
        }
    }

    // If set to false user is responsible to make sure that view provided in loadView() implements BaseChatViewContollerViewProtocol.
    // Must be set before loadView is called.
    public var substitutesMainViewAutomatically = true

    // Custom update on setting the data source. if triggeringUpdateType is nil it won't enqueue any update (you should do it later manually)
    public final func setChatDataSource(_ dataSource: ChatDataSourceProtocol?, triggeringUpdateType updateType: UpdateType?) {
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

    open override func loadView() {
        if substitutesMainViewAutomatically {
            self.view = BaseChatViewControllerView() // http://stackoverflow.com/questions/24596031/uiviewcontroller-with-inputaccessoryview-is-not-deallocated
            self.view.backgroundColor = UIColor.white
        } else {
            super.loadView()
        }

    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.addCollectionView()
        self.addInputBarContainer()
        self.addInputView()
        self.addInputContentContainer()
        self.setupKeyboardTracker()
        self.setupTapGestureRecognizer()
    }

    private func setupTapGestureRecognizer() {
        self.collectionView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BaseChatViewController.userDidTapOnCollectionView)))
    }

    public var endsEditingWhenTappingOnChatBackground = true
    @objc
    open func userDidTapOnCollectionView() {
        if self.endsEditingWhenTappingOnChatBackground {
            self.view.endEditing(true)
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.keyboardTracker.startTracking()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.keyboardTracker.stopTracking()
    }

    private func addCollectionView() {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.createCollectionViewLayout())
        collectionView.contentInset = self.layoutConfiguration.contentInsets
        collectionView.scrollIndicatorInsets = self.layoutConfiguration.scrollIndicatorInsets
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.keyboardDismissMode = .interactive
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.autoresizingMask = []
        self.view.addSubview(collectionView)
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .top, relatedBy: .equal, toItem: collectionView, attribute: .top, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .leading, relatedBy: .equal, toItem: collectionView, attribute: .leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: collectionView, attribute: .bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: collectionView, attribute: .trailing, multiplier: 1, constant: 0))
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.chatto_setContentInsetAdjustment(enabled: false, in: self)

        self.accessoryViewRevealer = AccessoryViewRevealer(collectionView: collectionView)
        self.collectionView = collectionView

        if !self.customPresentersConfigurationPoint {
            self.confugureCollectionViewWithPresenters()
        }
    }

    var unfinishedBatchUpdatesCount: Int = 0
    var onAllBatchUpdatesFinished: (() -> Void)?

    var inputContainerBottomConstraint: NSLayoutConstraint!
    private func addInputBarContainer() {
        self.inputBarContainer = UIView(frame: CGRect.zero)
        self.inputBarContainer.autoresizingMask = UIView.AutoresizingMask()
        self.inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        self.inputBarContainer.backgroundColor = .white
        self.view.addSubview(self.inputBarContainer)
        self.view.addConstraint(NSLayoutConstraint(item: self.inputBarContainer, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: self.topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .leading, relatedBy: .equal, toItem: self.inputBarContainer, attribute: .leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: self.inputBarContainer, attribute: .trailing, multiplier: 1, constant: 0))
        self.inputContainerBottomConstraint = NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: self.inputBarContainer, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraint(self.inputContainerBottomConstraint)
    }

    private func addInputView() {
        let inputView = self.createChatInputView()
        self.inputBarContainer.addSubview(inputView)
        self.inputBarContainer.addConstraint(NSLayoutConstraint(item: self.inputBarContainer, attribute: .top, relatedBy: .equal, toItem: inputView, attribute: .top, multiplier: 1, constant: 0))
        self.inputBarContainer.addConstraint(NSLayoutConstraint(item: self.inputBarContainer, attribute: .leading, relatedBy: .equal, toItem: inputView, attribute: .leading, multiplier: 1, constant: 0))
        self.inputBarContainer.addConstraint(NSLayoutConstraint(item: self.inputBarContainer, attribute: .bottom, relatedBy: .equal, toItem: inputView, attribute: .bottom, multiplier: 1, constant: 0))
        self.inputBarContainer.addConstraint(NSLayoutConstraint(item: self.inputBarContainer, attribute: .trailing, relatedBy: .equal, toItem: inputView, attribute: .trailing, multiplier: 1, constant: 0))
    }

    private func addInputContentContainer() {
        self.inputContentContainer = UIView(frame: CGRect.zero)
        self.inputContentContainer.autoresizingMask = UIView.AutoresizingMask()
        self.inputContentContainer.translatesAutoresizingMaskIntoConstraints = false
        self.inputContentContainer.backgroundColor = .white
        self.view.addSubview(self.inputContentContainer)
        self.view.addConstraint(NSLayoutConstraint(item: self.inputContentContainer, attribute: .top, relatedBy: .equal, toItem: self.inputBarContainer, attribute: .bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .leading, relatedBy: .equal, toItem: self.inputContentContainer, attribute: .leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: self.inputContentContainer, attribute: .trailing, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: self.inputContentContainer, attribute: .bottom, multiplier: 1, constant: 0))
    }

    private func setupInputContainerBottomConstraint() {
        if #available(iOS 11.0, *) {
            self.inputContainerBottomConstraint.constant = self.bottomLayoutGuide.length
        } else {
            // If we have been pushed on nav controller and hidesBottomBarWhenPushed = true, then ignore bottomLayoutMargin
            // because it has incorrect value when we actually have a bottom bar (tabbar)
            // Also if instance of BaseChatViewController is added as childViewController to another view controller, we had to check all this stuf on parent instance instead of self
            // UPD: Fixed in iOS 11.0
            let navigatedController: UIViewController
            if let parent = self.parent, !(parent is UINavigationController || parent is UITabBarController) {
                navigatedController = parent
            } else {
                navigatedController = self
            }

            if navigatedController.hidesBottomBarWhenPushed && (navigationController?.viewControllers.count ?? 0) > 1 && navigationController?.viewControllers.last == navigatedController {
                self.inputContainerBottomConstraint.constant = 0
            } else {
                self.inputContainerBottomConstraint.constant = self.bottomLayoutGuide.length
            }
        }
    }

    var isAdjustingInputContainer: Bool = false

    open func setupKeyboardTracker() {
        let heightBlock = { [weak self] (bottomMargin: CGFloat, keyboardStatus: KeyboardStatus) in
            guard let sSelf = self else { return }
            if let keyboardObservingDelegate = sSelf.keyboardEventsHandler {
                keyboardObservingDelegate.onKeyboardStateDidChange(bottomMargin, keyboardStatus)
            } else {
                sSelf.changeInputContentBottomMarginTo(bottomMargin)
            }
        }
        self.keyboardTracker = KeyboardTracker(viewController: self, inputBarContainer: self.inputBarContainer, heightBlock: heightBlock, notificationCenter: self.notificationCenter)

        (self.view as? BaseChatViewControllerViewProtocol)?.bmaInputAccessoryView = self.keyboardTracker?.trackingView
    }

    var notificationCenter = NotificationCenter.default
    var keyboardTracker: KeyboardTracker!

    public private(set) var isFirstLayout: Bool = true
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.adjustCollectionViewInsets(shouldUpdateContentOffset: true)
        self.keyboardTracker.adjustTrackingViewSizeIfNeeded()

        if self.isFirstLayout {
            self.updateQueue.start()
            self.isFirstLayout = false
            self.setupInputContainerBottomConstraint()
        }
    }

    public var allContentFits: Bool {
        guard let collectionView = self.collectionView else { return false }
        let inputHeightWithKeyboard = self.view.bounds.height - self.inputBarContainer.frame.minY
        let insetTop = self.topLayoutGuide.length + self.layoutConfiguration.contentInsets.top
        let insetBottom = self.layoutConfiguration.contentInsets.bottom + inputHeightWithKeyboard
        let availableHeight = collectionView.bounds.height - (insetTop + insetBottom)
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
        return availableHeight >= contentSize.height
    }

    func adjustCollectionViewInsets(shouldUpdateContentOffset: Bool) {
        guard let collectionView = self.collectionView else { return }
        let isInteracting = collectionView.panGestureRecognizer.numberOfTouches > 0
        let isBouncingAtTop = isInteracting && collectionView.contentOffset.y < -collectionView.contentInset.top
        if !self.placeMessagesFromBottom && isBouncingAtTop { return }

        let inputHeightWithKeyboard = self.view.bounds.height - self.inputBarContainer.frame.minY
        let newInsetBottom = self.layoutConfiguration.contentInsets.bottom + inputHeightWithKeyboard
        let insetBottomDiff = newInsetBottom - collectionView.contentInset.bottom
        var newInsetTop = self.topLayoutGuide.length + self.layoutConfiguration.contentInsets.top
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize

        let needToPlaceMessagesAtBottom = self.placeMessagesFromBottom && self.allContentFits
        if needToPlaceMessagesAtBottom {
            let realContentHeight = contentSize.height + newInsetTop + newInsetBottom
            newInsetTop += collectionView.bounds.height - realContentHeight
        }

        let insetTopDiff = newInsetTop - collectionView.contentInset.top
        let needToUpdateContentInset = self.placeMessagesFromBottom && (insetTopDiff != 0 || insetBottomDiff != 0)

        let prevContentOffsetY = collectionView.contentOffset.y

        let newContentOffsetY: CGFloat = {
            let minOffset = -newInsetTop
            let maxOffset = contentSize.height - (collectionView.bounds.height - newInsetBottom)
            let targetOffset = prevContentOffsetY + insetBottomDiff
            return max(min(maxOffset, targetOffset), minOffset)
        }()

        collectionView.contentInset = {
            var currentInsets = collectionView.contentInset
            currentInsets.bottom = newInsetBottom
            currentInsets.top = newInsetTop
            return currentInsets
        }()

        collectionView.scrollIndicatorInsets = {
            var currentInsets = collectionView.scrollIndicatorInsets
            currentInsets.bottom = self.layoutConfiguration.scrollIndicatorInsets.bottom + inputHeightWithKeyboard
            currentInsets.top = self.topLayoutGuide.length + self.layoutConfiguration.scrollIndicatorInsets.top
            return currentInsets
        }()

        guard shouldUpdateContentOffset else { return }

        let inputIsAtBottom = self.view.bounds.maxY - self.inputBarContainer.frame.maxY <= 0
        if isInteracting && (needToPlaceMessagesAtBottom || needToUpdateContentInset) {
            collectionView.contentOffset.y = prevContentOffsetY
        } else if self.allContentFits {
            collectionView.contentOffset.y = -collectionView.contentInset.top
        } else if !isInteracting || inputIsAtBottom {
            collectionView.contentOffset.y = newContentOffsetY
        }
    }

    func rectAtIndexPath(_ indexPath: IndexPath?) -> CGRect? {
        guard let collectionView = self.collectionView else { return nil }
        guard let indexPath = indexPath else { return nil }

        return collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame
    }

    var autoLoadingEnabled: Bool = false
    var accessoryViewRevealer: AccessoryViewRevealer!
    public private(set) var inputBarContainer: UIView!
    public private(set) var inputContentContainer: UIView!
    public internal(set) var presenterFactory: ChatItemPresenterFactoryProtocol!
    let presentersByCell = NSMapTable<UICollectionViewCell, AnyObject>(keyOptions: .weakMemory, valueOptions: .weakMemory)
    var visibleCells: [IndexPath: UICollectionViewCell] = [:] // @see visibleCellsAreValid(changes:)

    public internal(set) var updateQueue: SerialTaskQueueProtocol = SerialTaskQueue()

    /**
     - You can use a decorator to:
        - Provide the ChatCollectionViewLayout with margins between messages
        - Provide to your pressenters additional attributes to help them configure their cells (for instance if a bubble should show a tail)
        - You can also add new items (for instance time markers or failed cells)
    */
    public var chatItemsDecorator: ChatItemsDecoratorProtocol?

    open func createCollectionViewLayout() -> UICollectionViewLayout {
        let layout = ChatCollectionViewLayout()
        layout.delegate = self
        return layout
    }

    var layoutModel = ChatCollectionViewLayoutModel.createModel(0, itemsLayoutData: [])

    // MARK: Subclass overrides

    open func createPresenterFactory() -> ChatItemPresenterFactoryProtocol {
        // Default implementation
        return ChatItemPresenterFactory(presenterBuildersByType: self.createPresenterBuilders())
    }

    open func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        assert(false, "Override in subclass")
        return [ChatItemType: [ChatItemPresenterBuilderProtocol]]()
    }

    open func createChatInputView() -> UIView {
        assert(false, "Override in subclass")
        return UIView()
    }

    /**
        When paginating up we need to change the scroll position as the content is pushed down.
        We take distance to top from beforeUpdate indexPath and then we make afterUpdate indexPath to appear at the same distance
    */
    open func referenceIndexPathsToRestoreScrollPositionOnUpdate(itemsBeforeUpdate: ChatItemCompanionCollection, changes: CollectionChanges) -> (beforeUpdate: IndexPath?, afterUpdate: IndexPath?) {
        let firstItemMoved = changes.movedIndexPaths.first
        return (firstItemMoved?.indexPathOld as IndexPath?, firstItemMoved?.indexPathNew as IndexPath?)
    }

    // MARK: ChatDataSourceDelegateProtocol

    open func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol, updateType: UpdateType) {
        self.enqueueModelUpdate(updateType: updateType)
    }

    open func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol) {
        self.enqueueModelUpdate(updateType: .normal)
    }

    public var keyboardStatus: KeyboardStatus {
        return self.keyboardTracker.keyboardStatus
    }

    public var maximumInputSize: CGSize {
        return self.view.bounds.size
    }

    open var inputContentBottomMargin: CGFloat {
        return self.inputContainerBottomConstraint.constant
    }

    open func changeInputContentBottomMarginTo(_ newValue: CGFloat, animated: Bool = false, callback: (() -> Void)? = nil) {
        self.changeInputContentBottomMarginTo(newValue, animated: animated, duration: CATransaction.animationDuration(), callback: callback)
    }

    open func changeInputContentBottomMarginTo(_ newValue: CGFloat, animated: Bool = false, duration: CFTimeInterval, initialSpringVelocity: CGFloat = 0.0, callback: (() -> Void)? = nil) {
        guard self.inputContainerBottomConstraint.constant != newValue else { callback?(); return }
        if animated {
            self.isAdjustingInputContainer = true
            self.inputContainerBottomConstraint.constant = max(newValue, self.bottomLayoutGuide.length)
            CATransaction.begin()
            UIView.animate(
                withDuration: duration,
                delay: 0.0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: initialSpringVelocity,
                options: .curveLinear,
                animations: { self.view.layoutIfNeeded() },
                completion: { _ in })
            CATransaction.setCompletionBlock(callback) // this callback is guaranteed to be called
            CATransaction.commit()
            self.isAdjustingInputContainer = false
        } else {
            self.changeInputContentBottomMarginWithoutAnimationTo(newValue, callback: callback)
        }
    }

    open func changeInputContentBottomMarginTo(_ newValue: CGFloat, animated: Bool = false, duration: CFTimeInterval, timingFunction: CAMediaTimingFunction, callback: (() -> Void)? = nil) {
        guard self.inputContainerBottomConstraint.constant != newValue else { callback?(); return }
        if animated {
            self.isAdjustingInputContainer = true
            CATransaction.begin()
            CATransaction.setAnimationTimingFunction(timingFunction)
            self.inputContainerBottomConstraint.constant = max(newValue, self.bottomLayoutGuide.length)
            UIView.animate(
                withDuration: duration,
                animations: { self.view.layoutIfNeeded() },
                completion: { _ in }
            )
            CATransaction.setCompletionBlock(callback) // this callback is guaranteed to be called
            CATransaction.commit()
            self.isAdjustingInputContainer = false
        } else {
            self.changeInputContentBottomMarginWithoutAnimationTo(newValue, callback: callback)
        }
    }

    private func changeInputContentBottomMarginWithoutAnimationTo(_ newValue: CGFloat, callback: (() -> Void)?) {
        self.isAdjustingInputContainer = true
        self.inputContainerBottomConstraint.constant = max(newValue, self.bottomLayoutGuide.length)
        self.view.layoutIfNeeded()
        callback?()
        self.isAdjustingInputContainer = false
    }
}

extension BaseChatViewController { // Rotation

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard isViewLoaded else { return }
        guard let collectionView = self.collectionView else { return }
        let shouldScrollToBottom = self.isScrolledAtBottom()
        let referenceIndexPath = collectionView.indexPathsForVisibleItems.first
        let oldRect = self.rectAtIndexPath(referenceIndexPath)
        coordinator.animate(alongsideTransition: { (_) -> Void in
            if shouldScrollToBottom {
                self.scrollToBottom(animated: false)
            } else {
                let newRect = self.rectAtIndexPath(referenceIndexPath)
                self.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
            }
        }, completion: nil)
    }
}
