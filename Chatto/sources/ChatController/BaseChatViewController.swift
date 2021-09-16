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

public protocol ReplyActionHandler: AnyObject {
    func handleReply(for: ChatItemProtocol)
}

public protocol BaseChatViewControllerViewModelProtocol: AnyObject {
    var onDidUpdate: (() -> Void)? { get set }
}

public protocol ItemPositionScrollable: AnyObject {
    func scrollToItem(withId: String,
                      position: UICollectionView.ScrollPosition,
                      animated: Bool)
}

open class BaseChatViewController: UIViewController,
                                   InputPositionControlling,
                                   KeyboardInputAdjustableViewController,
                                   ReplyIndicatorRevealerDelegate {

    public let messagesViewController: ChatMessagesViewControllerProtocol
    public let configuration: Configuration

    private let inputBarPresenter: BaseChatInputBarPresenterProtocol
    private let keyboardEventsHandlers: [KeyboardEventsHandling]
    private let keyboardTracker: KeyboardTrackerProtocol
    private let collectionViewEventsHandlers: [CollectionViewEventsHandling]
    private let viewEventsHandlers: [ViewPresentationEventsHandling]

    private lazy var keyboardUpdatesHandler: KeyboardUpdatesHandler = self.makeKeyboardUpdatesHandler()
    public var replyActionHandler: ReplyActionHandler?
    public var replyFeedbackGenerator: ReplyFeedbackGeneratorProtocol? = BaseChatViewController.makeReplyFeedbackGenerator()

    public var collectionView: UICollectionView { self.messagesViewController.collectionView }

    public let inputBarContainer: UIView = UIView(frame: .zero)
    public let inputContentContainer: UIView = UIView(frame: .zero)
    public var chatItemCompanionCollection: ChatItemCompanionCollection {
        self.messagesViewController.chatItemCompanionCollection
    }
    /**
     - You can use a decorator to:
        - Provide the ChatCollectionViewLayout with margins between messages
        - Provide to your pressenters additional attributes to help them configure their cells (for instance if a bubble should show a tail)
        - You can also add new items (for instance time markers or failed cells)
    */

    private(set) public lazy var inputContainerBottomConstraint: NSLayoutConstraint = self.makeInputContainerBottomConstraint()
    private var cellPanGestureHandler: CellPanGestureHandler!
    private var isAdjustingInputContainer: Bool = false

    private var previousBoundsUsedForInsetsAdjustment: CGRect?

    public var layoutConfiguration: ChatLayoutConfigurationProtocol = ChatLayoutConfiguration.defaultConfiguration {
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

    private func makeKeyboardUpdatesHandler() -> KeyboardUpdatesHandler {
        let keyboardUpdatesHandler = KeyboardUpdatesHandler(
            keyboardTracker: self.keyboardTracker
        )
        keyboardUpdatesHandler.keyboardInputAdjustableViewController = self
        keyboardUpdatesHandler.delegate = self

        return keyboardUpdatesHandler
    }

    public var allContentFits: Bool {
        let collectionView = self.collectionView
        let inputHeightWithKeyboard = self.view.bounds.height - self.inputBarContainer.frame.minY
        let insetTop = self.view.safeAreaInsets.top + self.layoutConfiguration.contentInsets.top
        let insetBottom = self.layoutConfiguration.contentInsets.bottom + inputHeightWithKeyboard
        let availableHeight = collectionView.bounds.height - (insetTop + insetBottom)
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize

        return availableHeight >= contentSize.height
    }

    // MARK: - Init

    public init(inputBarPresenter: BaseChatInputBarPresenterProtocol,
                keyboardEventsHandlers: [KeyboardEventsHandling],
                keyboardTracker: KeyboardTrackerProtocol,
                messagesViewController: ChatMessagesViewControllerProtocol,
                collectionViewEventsHandlers: [CollectionViewEventsHandling],
                viewEventsHandlers: [ViewPresentationEventsHandling],
                configuration: Configuration = .default,
                notificationCenter: NotificationCenter = .default) {
        self.inputBarPresenter = inputBarPresenter
        self.keyboardEventsHandlers = keyboardEventsHandlers
        self.keyboardTracker = keyboardTracker
        self.messagesViewController = messagesViewController
        self.collectionViewEventsHandlers = collectionViewEventsHandlers
        self.viewEventsHandlers = viewEventsHandlers
        self.configuration = configuration

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func loadView() { // swiftlint:disable:this prohibited_super_call
        self.view = BaseChatViewControllerView() // http://stackoverflow.com/questions/24596031/uiviewcontroller-with-inputaccessoryview-is-not-deallocated
        self.view.backgroundColor = UIColor.white
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.setupInputBarPresenter()
        self.setupCollectionView()
        self.addInputBarContainer()
        self.addInputContentContainer()
        self.setupKeyboardTracker()
        self.setupTapGestureRecognizer()

        self.refreshContent()

        self.viewEventsHandlers.forEach {
            $0.onViewDidLoad()
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.keyboardUpdatesHandler.startTracking()

        self.viewEventsHandlers.forEach {
            $0.onViewWillAppear()
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.viewEventsHandlers.forEach {
            $0.onViewDidAppear()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.keyboardUpdatesHandler.stopTracking()

        self.viewEventsHandlers.forEach {
            $0.onViewWillDisappear()
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.viewEventsHandlers.forEach {
            $0.onViewDidDisappear()
        }
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.adjustCollectionViewInsets(shouldUpdateContentOffset: true)
        self.keyboardUpdatesHandler.adjustLayoutIfNeeded()

        self.updateInputContainerBottomBaseOffset()
    }

    // MARK: - Setup

    private func setupInputBarPresenter() {
        self.inputBarPresenter.viewController = self
    }

    private func setupTapGestureRecognizer() {
        let collectionView = self.collectionView

        collectionView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(BaseChatViewController.userDidTapOnCollectionView))
        )
    }

    @objc
    open func userDidTapOnCollectionView() {
        if self.configuration.endsEditingWhenTappingOnChatBackground {
            self.view.endEditing(true)
        }
    }

    private func setupCollectionView() {
        self.addChild(self.messagesViewController)
        defer { self.messagesViewController.didMove(toParent: self) }

        self.view.addSubview(self.messagesViewController.view)
        self.messagesViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: self.messagesViewController.view.topAnchor),
            self.view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: self.messagesViewController.view.trailingAnchor),
            self.view.bottomAnchor.constraint(equalTo: self.messagesViewController.view.bottomAnchor),
            self.view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: self.messagesViewController.view.leadingAnchor)
        ])

        self.cellPanGestureHandler = CellPanGestureHandler(collectionView: self.messagesViewController.collectionView)
        self.cellPanGestureHandler.replyDelegate = self
        self.cellPanGestureHandler.config = self.cellPanGestureHandlerConfig
    }

    private func addInputBarContainer() {
        self.inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        self.inputBarContainer.backgroundColor = .white
        self.view.addSubview(self.inputBarContainer)
        let guide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.inputBarContainer.topAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.inputBarContainer.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            self.inputBarContainer.trailingAnchor.constraint(equalTo: guide.trailingAnchor)
        ])
        self.inputContainerBottomConstraint = self.view.bottomAnchor.constraint(equalTo: self.inputBarContainer.bottomAnchor)
        self.view.addConstraint(self.inputContainerBottomConstraint)
    }

    private func makeInputContainerBottomConstraint() -> NSLayoutConstraint {
        return self.view.bottomAnchor.constraint(equalTo: self.inputBarContainer.bottomAnchor)
    }

    private func addInputContentContainer() {
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

    private func setupKeyboardTracker() {
        (self.view as? BaseChatViewControllerViewProtocol)?.bmaInputAccessoryView = self.keyboardUpdatesHandler.keyboardTrackingView
    }

    private func updateInputContainerBottomConstraint() {
        self.inputContainerBottomConstraint.constant = max(self.inputContainerBottomBaseOffset, self.inputContainerBottomAdditionalOffset)
        self.view.setNeedsLayout()
    }

    func adjustCollectionViewInsets(shouldUpdateContentOffset: Bool) {
        guard self.isViewLoaded else { return }

        let collectionView = self.collectionView

        let isInteracting = collectionView.panGestureRecognizer.numberOfTouches > 0
        let isBouncingAtTop = isInteracting && collectionView.contentOffset.y < -collectionView.contentInset.top
        if isBouncingAtTop { return }

        let inputHeightWithKeyboard = self.view.bounds.height - self.inputBarContainer.frame.minY
        let newInsetBottom = self.layoutConfiguration.contentInsets.bottom + inputHeightWithKeyboard
        let insetBottomDiff = newInsetBottom - collectionView.contentInset.bottom
        let newInsetTop = self.view.safeAreaInsets.top + self.layoutConfiguration.contentInsets.top
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
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
        if self.allContentFits {
            collectionView.contentOffset.y = -collectionView.contentInset.top
        } else if !isInteracting || inputIsAtBottom {
            collectionView.contentOffset.y = newContentOffsetY
        }
    }

    // MARK: Subclass overrides

    public func didPassThreshold(at: IndexPath) {
        self.replyFeedbackGenerator?.generateFeedback()
    }

    public func didFinishReplyGesture(at indexPath: IndexPath) {
        let item = self.chatItemCompanionCollection[indexPath.item].chatItem
        self.replyActionHandler?.handleReply(for: item)
    }

    public func didCancelReplyGesture(at: IndexPath) {}

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

    // MARK: - ChatMessagesViewControllerDelegate

    public func chatMessagesViewControllerShouldAnimateCellOnDisplay(_ : ChatMessagesViewController) -> Bool {
        return !self.isAdjustingInputContainer
    }

    // Proxy APIs
    public func refreshContent(completionBlock: (() -> Void)? = nil) {
        self.messagesViewController.refreshContent(completionBlock: completionBlock)
    }

    public var isScrolledAtBottom: Bool {
        return self.collectionView.isScrolledAtBottom()
    }

    public func scrollToBottom(animated: Bool) {
        self.messagesViewController.scrollToBottom(animated: animated)
    }

    public func autoLoadMoreContentIfNeeded() {
        self.messagesViewController.autoLoadMoreContentIfNeeded()
    }
}

extension BaseChatViewController: ChatMessagesViewControllerDelegate {

    public func chatMessagesViewController(_: ChatMessagesViewController,
                                           scrollViewDidEndDragging scrollView: UIScrollView,
                                           willDecelerate decelerate: Bool) {
        self.collectionViewEventsHandlers.forEach {
            $0.onScrollViewDidEndDragging(scrollView, decelerate: decelerate)
        }
    }

    public func chatMessagesViewController(_ viewController: ChatMessagesViewController, onDisplayCellWithIndexPath indexPath: IndexPath) {
        self.collectionViewEventsHandlers.forEach {
            $0.onCollectionView(
                viewController.collectionView,
                didDisplayCellWithIndexPath: indexPath,
                companionCollection: self.chatItemCompanionCollection
            )
        }
    }

    public func chatMessagesViewController(_ viewController: ChatMessagesViewController, didUpdateItemsWithUpdateType updateType: UpdateType) {
        self.collectionViewEventsHandlers.forEach {
            $0.onCollectionView(
                viewController.collectionView,
                didUpdateItemsWithUpdateType: updateType
            )
        }
    }

    public func chatMessagesViewController(_ viewController: ChatMessagesViewController, didScroll scrollView: UIScrollView) {
        self.collectionViewEventsHandlers.forEach {
            $0.onScrollViewDidScroll(scrollView)
        }
    }

    public func chatMessagesViewController(_ : ChatMessagesViewController, willEndDragging scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.collectionViewEventsHandlers.forEach {
            $0.onScrollViewWillEndDragging(
                scrollView,
                velocity: velocity,
                targetContentOffset: targetContentOffset
            )
        }
    }

    public func chatMessagesViewController(_ : ChatMessagesViewController, willBeginDragging scrollView: UIScrollView) {
        self.collectionViewEventsHandlers.forEach {
            $0.onScrollViewWillBeginDragging(scrollView)
        }
    }
}

extension BaseChatViewController: ItemPositionScrollable {
    public func scrollToItem(withId id: String, position: UICollectionView.ScrollPosition, animated: Bool) {
        self.scrollToItem(
            withId: id,
            position: position,
            animated: animated,
            spotlight: false
        )
    }

    public func scrollToItem(withId itemId: String,
                             position: UICollectionView.ScrollPosition = .centeredVertically,
                             animated: Bool = false,
                             spotlight: Bool = false) {
        self.messagesViewController.scroll(
            toItemId: itemId,
            position: position,
            animated: animated,
            spotlight: spotlight
        )
        // Programmatic scroll don't trigger autoloading, so, we need to trigger it manually
        self.autoLoadMoreContentIfNeeded()
    }
}

extension BaseChatViewController: ChatInputBarPresentingController {
    public func setup(inputView: UIView) {
        self.inputBarContainer.subviews.forEach { $0.removeFromSuperview() }

        inputView.translatesAutoresizingMaskIntoConstraints = false
        self.inputBarContainer.addSubview(inputView)
        NSLayoutConstraint.activate([
            self.inputBarContainer.topAnchor.constraint(equalTo: inputView.topAnchor),
            self.inputBarContainer.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),
            self.inputBarContainer.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            self.inputBarContainer.trailingAnchor.constraint(equalTo: inputView.trailingAnchor)
        ])
    }
}

extension BaseChatViewController: KeyboardUpdatesHandlerDelegate {
    public func keyboardUpdatesHandler(_ keyboardUpdatesHandler: KeyboardUpdatesHandler, didAdjustBottomMarginTo bottomMargin: CGFloat) {
        self.keyboardEventsHandlers.forEach {
            $0.onKeyboardStateDidChange(bottomMargin, self.keyboardTracker.keyboardStatus)
        }
    }
}

public extension BaseChatViewController {

    struct Configuration {
        public var endsEditingWhenTappingOnChatBackground: Bool

        public init(endsEditingWhenTappingOnChatBackground: Bool) {
            self.endsEditingWhenTappingOnChatBackground = endsEditingWhenTappingOnChatBackground
        }
    }
}

public extension BaseChatViewController.Configuration {
    static var `default`: Self {
        return .init(
            endsEditingWhenTappingOnChatBackground: true
        )
    }
}
