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

public protocol ChatViewControllerProtocol: ChatMessagesCollectionHolderProtocol, ChatInputBarPresentingController {
    func configure(style: ChatViewControllerStyle)
}

public final class BaseChatViewController: UIViewController {

    public typealias ChatMessagesViewControllerProtocol = ChatMessagesViewProtocol & UIViewController

    private let messagesViewController: ChatMessagesViewControllerProtocol
    private let configuration: Configuration
    private let keyboardUpdatesHandler: KeyboardUpdatesHandlerProtocol
    private let collectionViewEventsHandlers: [CollectionViewEventsHandling]
    private let viewEventsHandlers: [ViewPresentationEventsHandling]

    public var collectionView: UICollectionView { self.messagesViewController.collectionView }

    public let inputBarContainer: UIView = UIView(frame: .zero)
    private(set) public lazy var inputContainerBottomConstraint: NSLayoutConstraint = self.makeInputContainerBottomConstraint()
    public let inputContentContainer: UIView = UIView(frame: .zero)
    public var chatItemCompanionCollection: ChatItemCompanionCollection {
        self.messagesViewController.chatItemCompanionCollection
    }

    private var isAdjustingInputContainer: Bool = false

    private var previousBoundsUsedForInsetsAdjustment: CGRect?

    public var layoutConfiguration: ChatLayoutConfigurationProtocol = ChatLayoutConfiguration.defaultConfiguration {
        didSet {
            self.adjustCollectionViewInsets(shouldUpdateContentOffset: false)
        }
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

    private var allContentFits: Bool {
        let collectionView = self.collectionView
        let inputHeightWithKeyboard = self.view.bounds.height - self.inputBarContainer.frame.minY
        let insetTop = self.view.safeAreaInsets.top + self.layoutConfiguration.contentInsets.top
        let insetBottom = self.layoutConfiguration.contentInsets.bottom + inputHeightWithKeyboard
        let availableHeight = collectionView.bounds.height - (insetTop + insetBottom)
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize

        return availableHeight >= contentSize.height
    }

    // MARK: - Init

    public init(messagesViewController: ChatMessagesViewControllerProtocol,
                collectionViewEventsHandlers: [CollectionViewEventsHandling],
                keyboardUpdatesHandler: KeyboardUpdatesHandlerProtocol,
                viewEventsHandlers: [ViewPresentationEventsHandling],
                configuration: Configuration = .default) {
        self.messagesViewController = messagesViewController
        self.collectionViewEventsHandlers = collectionViewEventsHandlers
        self.keyboardUpdatesHandler = keyboardUpdatesHandler
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

    override public func viewDidLoad() {
        super.viewDidLoad()

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

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.keyboardUpdatesHandler.startTracking()

        self.viewEventsHandlers.forEach {
            $0.onViewWillAppear()
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.viewEventsHandlers.forEach {
            $0.onViewDidAppear()
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        self.viewEventsHandlers.forEach {
            $0.onBeforeViewWillDisappear()
        }

        super.viewWillDisappear(animated)

        self.keyboardUpdatesHandler.stopTracking()

        self.viewEventsHandlers.forEach {
            $0.onViewWillDisappear()
        }
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.viewEventsHandlers.forEach {
            $0.onViewDidDisappear()
        }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.adjustCollectionViewInsets(shouldUpdateContentOffset: true)

        self.keyboardUpdatesHandler.adjustLayoutIfNeeded()
        self.updateInputContainerBottomBaseOffset()

        self.viewEventsHandlers.forEach {
            $0.onViewDidLayoutSubviews()
        }
    }

    // MARK: - Setup

    private func setupTapGestureRecognizer() {
        let collectionView = self.collectionView

        collectionView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(BaseChatViewController.userDidTapOnCollectionView))
        )
    }

    @objc
    private func userDidTapOnCollectionView() {
        guard self.configuration.endsEditingWhenTappingOnChatBackground else {
            return
        }

        self.view.endEditing(true)

        self.viewEventsHandlers.forEach {
            $0.onDidEndEditing()
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
    }

    private func addInputBarContainer() {
        self.inputBarContainer.translatesAutoresizingMaskIntoConstraints = false
        self.inputBarContainer.backgroundColor = .white
        self.view.addSubview(self.inputBarContainer)
        let guide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.inputBarContainer.topAnchor.constraint(greaterThanOrEqualTo: guide.topAnchor),
            self.inputBarContainer.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            self.inputBarContainer.trailingAnchor.constraint(equalTo: guide.trailingAnchor)
        ])
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

    private func adjustCollectionViewInsets(shouldUpdateContentOffset: Bool) {
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
            let currentBottomPosition = collectionView.bounds.maxY - collectionView.contentInset.bottom
            let isScrolledToBottom = contentSize.height - currentBottomPosition <= CGFloat.bma_epsilon
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

extension BaseChatViewController: ChatMessagesCollectionHolderProtocol {
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
    public var maximumInputSize: CGSize {
        return self.view.bounds.size
    }

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

    public func changeInputContentBottomMargin(to value: CGFloat, animation: ChatInputBarAnimationProtocol?, completion: (() -> Void)?) {
        self.isAdjustingInputContainer = true
        self.inputContainerBottomAdditionalOffset = value
        if let animation = animation {
            animation.animate(view: self.view, completion: completion)
        } else {
            self.view.layoutIfNeeded()
            completion?()
        }

        self.isAdjustingInputContainer = false
    }
}

extension BaseChatViewController: ChatViewControllerProtocol {
    public func configure(style: ChatViewControllerStyle) {
        self.inputContentContainer.backgroundColor = style.inputBarBackgroundColor
        self.messagesViewController.configure(
            backgroundColor: style.messagesBackgroundColor
        )
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

public struct ChatViewControllerStyle {
    public var inputBarBackgroundColor: UIColor
    public var messagesBackgroundColor: UIColor

    public init(
        inputBarBackgroundColor: UIColor,
        messagesBackgroundColor: UIColor
    ) {
        self.inputBarBackgroundColor = inputBarBackgroundColor
        self.messagesBackgroundColor = messagesBackgroundColor
    }
}

public extension ChatViewControllerStyle {
    static var `default`: Self {
        return .init(
            inputBarBackgroundColor: .white,
            messagesBackgroundColor: ChatMessagesViewController.Style.default.backgroundColor
        )
    }
}
