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

public protocol ReplyActionHandler: AnyObject {
    func handleReply(for: ChatItemProtocol)
}

open class BaseChatViewController: UIViewController,
                                   UICollectionViewDataSource,
                                   UICollectionViewDelegate,
                                   ChatDataSourceDelegateProtocol,
                                   InputPositionControlling,
                                   ReplyIndicatorRevealerDelegate {

    public let configuration: Configuration
    let presentersByCell = NSMapTable<UICollectionViewCell, AnyObject>(keyOptions: .weakMemory, valueOptions: .weakMemory)

    public weak var keyboardEventsHandler: KeyboardEventsHandling?
    public weak var scrollViewEventsHandler: ScrollViewEventsHandling?
    public var replyActionHandler: ReplyActionHandler?
    public var replyFeedbackGenerator: ReplyFeedbackGeneratorProtocol? = BaseChatViewController.makeReplyFeedbackGenerator()
    public var customPresentersConfigurationPoint = false // If true then confugureCollectionViewWithPresenters() will not be called in viewDidLoad() method and has to be called manually
    public private(set) var collectionView: UICollectionView?
    public private(set) var inputBarContainer: UIView!
    public private(set) var inputContentContainer: UIView!
    public private(set) var isFirstLayout: Bool = true
    public internal(set) var presenterFactory: ChatItemPresenterFactoryProtocol!
    public internal(set) var updateQueue: SerialTaskQueueProtocol = SerialTaskQueue()
    public final internal(set) var chatItemCompanionCollection = ChatItemCompanionCollection(items: [])
    // If set to false user is responsible to make sure that view provided in loadView() implements BaseChatViewContollerViewProtocol.
    // Must be set before loadView is called.
    public var substitutesMainViewAutomatically = true
    /**
     - You can use a decorator to:
        - Provide the ChatCollectionViewLayout with margins between messages
        - Provide to your pressenters additional attributes to help them configure their cells (for instance if a bubble should show a tail)
        - You can also add new items (for instance time markers or failed cells)
    */
    public var chatItemsDecorator: ChatItemsDecoratorProtocol?

    var inputContainerBottomConstraint: NSLayoutConstraint!
    var unfinishedBatchUpdatesCount: Int = 0
    var onAllBatchUpdatesFinished: (() -> Void)?
    var autoLoadingEnabled: Bool = false
    var cellPanGestureHandler: CellPanGestureHandler!
    var layoutModel = ChatCollectionViewLayoutModel.createModel(0, itemsLayoutData: [])
    var isAdjustingInputContainer: Bool = false
    var notificationCenter = NotificationCenter.default
    var keyboardTracker: KeyboardTracker!
    var visibleCells: [IndexPath: UICollectionViewCell] = [:] // @see visibleCellsAreValid(changes:)

    private var previousBoundsUsedForInsetsAdjustment: CGRect?

    public var layoutConfiguration: ChatLayoutConfigurationProtocol = ChatLayoutConfiguration.defaultConfiguration {
        didSet {
            self.adjustCollectionViewInsets(shouldUpdateContentOffset: false)
        }
    }

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

    public final var cellPanGestureHandlerConfig: CellPanGestureHandlerConfig = .defaultConfig() {
        didSet {
            self.cellPanGestureHandler?.config = self.cellPanGestureHandlerConfig
        }
    }

    public var keyboardStatus: KeyboardStatus {
        return self.keyboardTracker.keyboardStatus
    }

    public var maximumInputSize: CGSize {
        return self.view.bounds.size
    }

    public var inputContentBottomMargin: CGFloat {
        return self.inputContainerBottomConstraint.constant
    }

    private var inputContainerBottomBaseOffset: CGFloat = 0 {
        didSet { self.updateInputContainerBottomConstraint() }
    }

    private var inputContainerBottomAdditionalOffset: CGFloat = 0 {
        didSet { self.updateInputContainerBottomConstraint() }
    }

    public var allContentFits: Bool {
        guard let collectionView = self.collectionView else { return false }
        let inputHeightWithKeyboard = self.view.bounds.height - self.inputBarContainer.frame.minY
        let insetTop = self.view.safeAreaInsets.top + self.layoutConfiguration.contentInsets.top
        let insetBottom = self.layoutConfiguration.contentInsets.bottom + inputHeightWithKeyboard
        let availableHeight = collectionView.bounds.height - (insetTop + insetBottom)
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
        return availableHeight >= contentSize.height
    }

    // MARK: - Init

    public init(configuration: Configuration) {
        self.configuration = configuration

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.collectionView?.delegate = nil
        self.collectionView?.dataSource = nil
    }

    // MARK: - Lifecycle

    open override func loadView() { // swiftlint:disable:this prohibited_super_call
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

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.keyboardTracker.startTracking()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.keyboardTracker?.stopTracking()
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.adjustCollectionViewInsets(shouldUpdateContentOffset: true)
        self.keyboardTracker.adjustTrackingViewSizeIfNeeded()

        if self.isFirstLayout {
            self.updateQueue.start()
            self.isFirstLayout = false
        }

        self.updateInputContainerBottomBaseOffset()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard self.isViewLoaded else { return }
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

    // MARK: - Setup

    private func setupTapGestureRecognizer() {
        self.collectionView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BaseChatViewController.userDidTapOnCollectionView)))
    }

    @objc
    open func userDidTapOnCollectionView() {
        if self.configuration.editing.endsEditingWhenTappingOnChatBackground {
            self.view.endEditing(true)
        }
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
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: collectionView.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])

        let guide = self.view.safeAreaLayoutGuide
        let leadingAnchor: NSLayoutXAxisAnchor = guide.leadingAnchor
        let trailingAnchor: NSLayoutXAxisAnchor = guide.trailingAnchor

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.chatto_setContentInsetAdjustment(enabled: false, in: self)
        collectionView.chatto_setAutomaticallyAdjustsScrollIndicatorInsets(false)
        collectionView.chatto_setIsPrefetchingEnabled(false)

        self.cellPanGestureHandler = CellPanGestureHandler(collectionView: collectionView)
        self.cellPanGestureHandler.replyDelegate = self
        self.cellPanGestureHandler.config = self.cellPanGestureHandlerConfig
        self.collectionView = collectionView

        if !self.customPresentersConfigurationPoint {
            self.confugureCollectionViewWithPresenters()
        }
    }

    private func addInputBarContainer() {
        self.inputBarContainer = UIView(frame: CGRect.zero)
        self.inputBarContainer.autoresizingMask = UIView.AutoresizingMask()
        self.inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        self.inputBarContainer.backgroundColor = .white
        self.view.addSubview(self.inputBarContainer)
        NSLayoutConstraint.activate([
            self.inputBarContainer.topAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor)
        ])
        let guide = self.view.safeAreaLayoutGuide
        let leadingAnchor: NSLayoutXAxisAnchor = guide.leadingAnchor
        let trailingAnchor: NSLayoutXAxisAnchor = guide.trailingAnchor

        NSLayoutConstraint.activate([
            self.inputBarContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.inputBarContainer.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        self.inputContainerBottomConstraint = self.view.bottomAnchor.constraint(equalTo: self.inputBarContainer.bottomAnchor)
        self.view.addConstraint(self.inputContainerBottomConstraint)
    }

    private func addInputView() {
        let inputView = self.createChatInputView()
        self.inputBarContainer.addSubview(inputView)
        NSLayoutConstraint.activate([
            self.inputBarContainer.topAnchor.constraint(equalTo: inputView.topAnchor),
            self.inputBarContainer.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),
            self.inputBarContainer.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            self.inputBarContainer.trailingAnchor.constraint(equalTo: inputView.trailingAnchor)
        ])
    }

    private func addInputContentContainer() {
        self.inputContentContainer = UIView(frame: CGRect.zero)
        self.inputContentContainer.autoresizingMask = UIView.AutoresizingMask()
        self.inputContentContainer.translatesAutoresizingMaskIntoConstraints = false
        self.inputContentContainer.backgroundColor = .white
        self.view.addSubview(self.inputContentContainer)
        NSLayoutConstraint.activate([
            self.view.bottomAnchor.constraint(equalTo: self.inputContentContainer.bottomAnchor),
            self.view.leadingAnchor.constraint(equalTo: self.inputContentContainer.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: self.inputContentContainer.trailingAnchor),
            self.inputContentContainer.topAnchor.constraint(equalTo: self.inputBarContainer.bottomAnchor)
        ])
    }

    private func updateInputContainerBottomBaseOffset() {
        let offset = self.view.safeAreaInsets.bottom
        if self.inputContainerBottomBaseOffset != offset {
            self.inputContainerBottomBaseOffset = offset
        }
    }

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

    private func updateInputContainerBottomConstraint() {
        self.inputContainerBottomConstraint.constant = max(self.inputContainerBottomBaseOffset, self.inputContainerBottomAdditionalOffset)
        self.view.setNeedsLayout()
    }


    // Custom update on setting the data source. if triggeringUpdateType is nil it won't enqueue any update (you should do it later manually)
    public final func setChatDataSource(_ dataSource: ChatDataSourceProtocol?, triggeringUpdateType updateType: UpdateType?) {
        self._chatDataSource = dataSource
        self._chatDataSource?.delegate = self
        if let updateType = updateType {
            self.enqueueModelUpdate(updateType: updateType)
        }
    }

    func adjustCollectionViewInsets(shouldUpdateContentOffset: Bool) {
        guard let collectionView = self.collectionView else { return }
        let isInteracting = collectionView.panGestureRecognizer.numberOfTouches > 0
        let isBouncingAtTop = isInteracting && collectionView.contentOffset.y < -collectionView.contentInset.top
        if !self.placeMessagesFromBottom && isBouncingAtTop { return }

        let inputHeightWithKeyboard = self.view.bounds.height - self.inputBarContainer.frame.minY
        let newInsetBottom = self.layoutConfiguration.contentInsets.bottom + inputHeightWithKeyboard
        let insetBottomDiff = newInsetBottom - collectionView.contentInset.bottom
        var newInsetTop = self.view.safeAreaInsets.top + self.layoutConfiguration.contentInsets.top
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize

        let needToPlaceMessagesAtBottom = self.placeMessagesFromBottom && self.allContentFits
        if needToPlaceMessagesAtBottom {
            let realContentHeight = contentSize.height + newInsetTop + newInsetBottom
            newInsetTop += collectionView.bounds.height - realContentHeight
        }

        let insetTopDiff = newInsetTop - collectionView.contentInset.top
        let needToUpdateContentInset = self.placeMessagesFromBottom && (insetTopDiff != 0 || insetBottomDiff != 0)

        let prevContentOffsetY = collectionView.contentOffset.y

        let boundsHeightDiff: CGFloat = {
            guard shouldUpdateContentOffset, let lastUsedBounds = self.previousBoundsUsedForInsetsAdjustment else {
                return 0
            }
            let diff = lastUsedBounds.height - collectionView.bounds.height
            // When collectionView is scrolled to bottom and height increases,
            // collectionView adjusts its contentOffset automatically
            let isScrolledToBottom = contentSize.height <= collectionView.bounds.maxY - collectionView.contentInset.bottom
            return isScrolledToBottom ? max(0, diff) : diff
        }()
        self.previousBoundsUsedForInsetsAdjustment = collectionView.bounds

        let newContentOffsetY: CGFloat = {
            let minOffset = -newInsetTop
            let maxOffset = contentSize.height - (collectionView.bounds.height - newInsetBottom)
            let targetOffset = prevContentOffsetY + insetBottomDiff + boundsHeightDiff
            return max(min(maxOffset, targetOffset), minOffset)
        }()

        collectionView.contentInset = {
            var currentInsets = collectionView.contentInset
            currentInsets.bottom = newInsetBottom
            currentInsets.top = newInsetTop
            return currentInsets
        }()

        collectionView.chatto_setVerticalScrollIndicatorInsets({
            var currentInsets = collectionView.scrollIndicatorInsets
            currentInsets.bottom = self.layoutConfiguration.scrollIndicatorInsets.bottom + inputHeightWithKeyboard
            currentInsets.top = self.view.safeAreaInsets.top + self.layoutConfiguration.scrollIndicatorInsets.top
            return currentInsets
        }())

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

    open func createCollectionViewLayout() -> UICollectionViewLayout {
        let layout = ChatCollectionViewLayout()
        layout.delegate = self
        return layout
    }

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

    open func didPassThreshold(at: IndexPath) {
        self.replyFeedbackGenerator?.generateFeedback()
    }

    open func didFinishReplyGesture(at indexPath: IndexPath) {
        let item = self.chatItemCompanionCollection[indexPath.item].chatItem
        self.replyActionHandler?.handleReply(for: item)
    }

    open func didCancelReplyGesture(at: IndexPath) {}

    open func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol, updateType: UpdateType) {
        self.enqueueModelUpdate(updateType: updateType)
    }

    open func changeInputContentBottomMarginTo(_ newValue: CGFloat, animated: Bool = false, duration: CFTimeInterval, initialSpringVelocity: CGFloat = 0.0, callback: (() -> Void)? = nil) {
        guard self.inputContainerBottomConstraint.constant != newValue else { callback?(); return }
        if animated {
            self.isAdjustingInputContainer = true
            self.inputContainerBottomAdditionalOffset = newValue
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
            self.inputContainerBottomAdditionalOffset = newValue
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

    // MARK: ReplyIndicatorRevealerDelegate

    private static func makeReplyFeedbackGenerator() -> ReplyFeedbackGeneratorProtocol? {
        return ReplyFeedbackGenerator()
    }

    public func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol) {
        self.enqueueModelUpdate(updateType: .normal)
    }

    public func changeInputContentBottomMarginTo(_ newValue: CGFloat, animated: Bool = false, callback: (() -> Void)? = nil) {
        self.changeInputContentBottomMarginTo(newValue, animated: animated, duration: CATransaction.animationDuration(), callback: callback)
    }

    private func changeInputContentBottomMarginWithoutAnimationTo(_ newValue: CGFloat, callback: (() -> Void)?) {
        self.isAdjustingInputContainer = true
        self.inputContainerBottomAdditionalOffset = newValue
        self.view.layoutIfNeeded()
        callback?()
        self.isAdjustingInputContainer = false
    }
}

public extension BaseChatViewController {

    struct Configuration {

        public struct Animations {
            public var updatesAnimationDuration: TimeInterval

            public init(updatesAnimationDuration: TimeInterval) {
                self.updatesAnimationDuration = updatesAnimationDuration
            }
        }

        public struct Editing {
            public var endsEditingWhenTappingOnChatBackground: Bool

            public init(endsEditingWhenTappingOnChatBackground: Bool) {
                self.endsEditingWhenTappingOnChatBackground = endsEditingWhenTappingOnChatBackground
            }
        }

        public struct Messages {
            // If not nil, will ask data source to reduce number of messages when limit is reached. @see ChatDataSourceDelegateProtocol
            public var preferredMaxMessageCount: Int?
            // When the above happens, will ask to adjust with this value. It may be wise for this to be smaller to reduce number of adjustments
            public var preferredMaxMessageCountAdjustment: Int

            public init(preferredMaxMessageCount: Int?,
                        preferredMaxMessageCountAdjustment: Int) {
                self.preferredMaxMessageCount = preferredMaxMessageCount
                self.preferredMaxMessageCountAdjustment = preferredMaxMessageCountAdjustment
            }
        }


        public struct Updates {
            // in [0, 1]
            public var autoloadingFractionalThreshold: CGFloat
            // If receiving data source updates too fast, while an update it's being processed, only the last one will be executed
            public var coalesceUpdates: Bool
            // Allows another performBatchUpdates to be called before completion of a previous one (not recommended).
            // Changing this value after viewDidLoad is not supported
            public var fastUpdates: Bool

            public init(autoloadingFractionalThreshold: CGFloat,
                        coalesceUpdates: Bool,
                        fastUpdates: Bool) {
                self.autoloadingFractionalThreshold = autoloadingFractionalThreshold
                self.coalesceUpdates = coalesceUpdates
                self.fastUpdates = fastUpdates
            }
        }

        public var animation: Animations
        public var editing: Editing
        public var messages: Messages
        public var updates: Updates

        public init(animation: Animations,
                    editing: Editing,
                    messages: Messages,
                    updates: Updates) {
            self.animation = animation
            self.editing = editing
            self.messages = messages
            self.updates = updates
        }
    }
}

public extension BaseChatViewController.Configuration.Animations {
    static var `default`: Self {
        return .init(
            updatesAnimationDuration: 0.33
        )
    }
}

public extension BaseChatViewController.Configuration.Editing {
    static var `default`: Self {
        return .init(
            endsEditingWhenTappingOnChatBackground: true
        )
    }
}

public extension BaseChatViewController.Configuration.Messages {
    static var `default`: Self {
        return .init(
            preferredMaxMessageCount: 500,
            preferredMaxMessageCountAdjustment: 400
        )
    }
}


public extension BaseChatViewController.Configuration.Updates {
    static var `default`: Self {
        return .init(
            autoloadingFractionalThreshold: 0.05,
            coalesceUpdates: true,
            fastUpdates: true
        )
    }
}

public extension BaseChatViewController.Configuration {
    static var `default`: Self {
        return .init(
            animation: .default,
            editing: .default,
            messages: .default,
            updates: .default
        )
    }
}
