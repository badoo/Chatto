//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import UIKit

public protocol ChatMessagesViewControllerDelegate: AnyObject {
    func chatMessagesViewControllerShouldAnimateCellOnDisplay(_: ChatMessagesViewController) -> Bool
    func chatMessagesViewController(_: ChatMessagesViewController, didUpdateItemsWithUpdateType: UpdateType)

    func chatMessagesViewController(_: ChatMessagesViewController, didScroll: UIScrollView)
    func chatMessagesViewController(_: ChatMessagesViewController, onDisplayCellWithIndexPath: IndexPath)
    func chatMessagesViewController(_: ChatMessagesViewController, willBeginDragging: UIScrollView)
    func chatMessagesViewController(_: ChatMessagesViewController, scrollViewDidEndDragging: UIScrollView, willDecelerate decelerate: Bool)
    func chatMessagesViewController(_: ChatMessagesViewController,
                                    willEndDragging: UIScrollView,
                                    withVelocity velocity: CGPoint,
                                    targetContentOffset: UnsafeMutablePointer<CGPoint>)
}

public protocol ChatMessagesViewControllerProtocol: UICollectionViewController {
    var delegate: ChatMessagesViewControllerDelegate? { get set }

    // TODO: Proxy
    var chatItemCompanionCollection: ChatItemCompanionCollection { get }

    func autoLoadMoreContentIfNeeded()
    func refreshContent(completionBlock: (() -> Void)?)
    func scroll(toItemId: String,
                position: UICollectionView.ScrollPosition,
                animated: Bool,
                spotlight: Bool)
}

public final class ChatMessagesViewController: UICollectionViewController, ChatMessagesViewControllerProtocol {

    private let config: Config
    private let layout: UICollectionViewLayout & ChatCollectionViewLayoutProtocol
    private let messagesAdapter: ChatMessageCollectionAdapterProtocol
    private let presenterFactory: ChatItemPresenterFactoryProtocol
    private let style: Style
    private let viewModel: ChatMessagesViewModelProtocol

    private var layoutModel: ChatCollectionViewLayoutModel
    private var isFirstLayout: Bool

    public weak var delegate: ChatMessagesViewControllerDelegate?
    public var chatItemCompanionCollection: ChatItemCompanionCollection {
        self.messagesAdapter.chatItemCompanionCollection
    }
    
    public init(config: Config,
                layout: UICollectionViewLayout & ChatCollectionViewLayoutProtocol,
                messagesAdapter: ChatMessageCollectionAdapterProtocol,
                presenterFactory: ChatItemPresenterFactoryProtocol,
                style: Style,
                viewModel: ChatMessagesViewModelProtocol) {
        self.config = config
        self.layout = layout
        self.messagesAdapter = messagesAdapter
        self.presenterFactory = presenterFactory
        self.style = style
        self.viewModel = viewModel

        self.layoutModel = ChatCollectionViewLayoutModel.createModel(0, itemsLayoutData: [])
        self.isFirstLayout = true
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.configureMessageAdapter()
        self.configurePresenterFactory()
        self.configureStyle()
        self.configureView()
        self.configureCollectionView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !self.isFirstLayout {
            self.messagesAdapter.startProcessingUpdates()
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.messagesAdapter.stopProcessingUpdates()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.isFirstLayout {
            self.messagesAdapter.startProcessingUpdates()
        }
        self.isFirstLayout = false
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard self.isViewLoaded else { return }
        guard let collectionView = self.collectionView else { return }

        let shouldScrollToBottom = self.collectionView.isScrolledAtBottom()
        let referenceIndexPath = collectionView.indexPathsForVisibleItems.first
        let oldRect = self.rect(at: referenceIndexPath)

        coordinator.animate { [weak self] _ in
            guard let self = self else { return }

            if shouldScrollToBottom {
                self.collectionView.scrollToBottom(
                    animated: false,
                    animationDuration: self.style.updatesAnimationDuration
                )

                return
            }

            let newRect = self.rect(at: referenceIndexPath)
            self.collectionView.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
        }
    }

    private func configureMessageAdapter() {
        self.messagesAdapter.delegate = self
        self.messagesAdapter.setup(in: self.collectionView)
    }

    private func configureStyle() {
        self.collectionView.collectionViewLayout = self.layout
        self.collectionView.allowsSelection = false
        self.collectionView.alwaysBounceVertical = self.style.alwaysBounceVertical
        self.collectionView.backgroundColor = self.style.backgroundColor
        self.collectionView.contentInset = self.style.contentInsets
        self.collectionView.keyboardDismissMode = self.style.keyboardDismissMode
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.showsVerticalScrollIndicator = self.style.shouldShowVerticalScrollView
        self.collectionView.scrollIndicatorInsets = self.style.scrollIndicatorInsets
    }

    private func configurePresenterFactory() {
        self.presenterFactory.configure(withCollectionView: self.collectionView)
    }

    private func configureView() {
        self.collectionView.chatto_setContentInsetAdjustment(enabled: false, in: self)
        self.collectionView.chatto_setAutomaticallyAdjustsScrollIndicatorInsets(false)
        self.collectionView.chatto_setIsPrefetchingEnabled(false)
    }

    private func configureCollectionView() {
        self.collectionView.delegate = self
    }

    private func rect(at indexPath: IndexPath?) -> CGRect? {
        guard let collectionView = self.collectionView else { return nil }
        guard let indexPath = indexPath else { return nil }

        return collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame
    }
}

// Proxy
public extension ChatMessagesViewController {
    func indexPath(of itemId: String) -> IndexPath? {
        return self.messagesAdapter.indexPath(of: itemId)
    }

    func refreshContent(completionBlock: (() -> Void)? = nil) {
        self.messagesAdapter.refreshContent(completionBlock: completionBlock)
    }

    func autoLoadMoreContentIfNeeded() {
        guard self.config.autoLoadingEnabled else { return }

        let isCloseToTop = self.collectionView.isCloseToTop(threshold: self.config.autoMarginThreshold)
        let hasMorePreviousContentToLoad = self.viewModel.hasMorePrevious
        if isCloseToTop && hasMorePreviousContentToLoad {
            self.viewModel.loadPrevious()
            return
        }

        let isCloseToBottom = self.collectionView.isCloseToBottom(threshold: self.config.autoMarginThreshold)
        let hasMoreNextContentToLoad = self.viewModel.hasMoreNext
        if isCloseToBottom && hasMoreNextContentToLoad {
            self.viewModel.loadNext()
            return
        }
    }

    func scroll(toItemId itemId: String,
                position: UICollectionView.ScrollPosition,
                animated: Bool,
                spotlight: Bool) {
        guard let itemIndexPath = self.messagesAdapter.indexPath(of: itemId),
              let rect = self.collectionView.rect(at: itemIndexPath) else { return }

        if animated {
            let pageHeight = collectionView.bounds.height
            let twoPagesHeight = pageHeight * 2
            let isScrollingUp = rect.minY < collectionView.contentOffset.y

            if isScrollingUp {
                let isNeedToScrollUpMoreThenTwoPages = rect.minY < collectionView.contentOffset.y - twoPagesHeight
                if isNeedToScrollUpMoreThenTwoPages {
                    let lastPageOriginY = collectionView.contentSize.height - pageHeight
                    var preScrollRect = rect
                    preScrollRect.origin.y = min(lastPageOriginY, rect.minY + pageHeight)
                    collectionView.scrollRectToVisible(preScrollRect, animated: false)
                }
            } else {
                let isNeedToScrollDownMoreThenTwoPages = rect.minY > collectionView.contentOffset.y + twoPagesHeight
                if isNeedToScrollDownMoreThenTwoPages {
                    var preScrollRect = rect
                    preScrollRect.origin.y = max(0, rect.minY - pageHeight)
                    collectionView.scrollRectToVisible(preScrollRect, animated: false)
                }
            }
        }

        if spotlight {
            self.messagesAdapter.scheduleSpotlight(for: itemId)
        }

        self.collectionView.scrollToItem(
            at: itemIndexPath,
            at: position,
            animated: animated
        )
    }
}

extension ChatMessagesViewController {
    public override func collectionView(_ collectionView: UICollectionView,
                                        didEndDisplaying cell: UICollectionViewCell,
                                        forItemAt indexPath: IndexPath) {
        self.messagesAdapter.collectionView?(
            collectionView,
            didEndDisplaying: cell,
            forItemAt: indexPath
        )
    }

    public override func collectionView(_ collectionView: UICollectionView,
                                        willDisplay cell: UICollectionViewCell,
                                        forItemAt indexPath: IndexPath) {
        self.messagesAdapter.collectionView?(
            collectionView,
            willDisplay: cell,
            forItemAt: indexPath
        )
    }

    public override func collectionView(_ collectionView: UICollectionView,
                                        shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return self.messagesAdapter.collectionView?(collectionView, shouldShowMenuForItemAt: indexPath) ?? false
    }

    public override func collectionView(_ collectionView: UICollectionView,
                                        canPerformAction action: Selector,
                                        forItemAt indexPath: IndexPath,
                                        withSender sender: Any?) -> Bool {
        return self.messagesAdapter.collectionView?(
            collectionView,
            canPerformAction: action,
            forItemAt: indexPath,
            withSender: sender
        ) ?? false
    }

    public override func collectionView(_ collectionView: UICollectionView,
                                        performAction action: Selector,
                                        forItemAt indexPath: IndexPath,
                                        withSender sender: Any?) {
        self.messagesAdapter.collectionView?(
            collectionView,
            performAction: action,
            forItemAt: indexPath,
            withSender: sender
        )
    }

    public override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.messagesAdapter.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.collectionView.isDragging {
            self.autoLoadMoreContentIfNeeded()
        }

        self.messagesAdapter.scrollViewDidScroll?(scrollView)

        self.delegate?.chatMessagesViewController(
            self,
            didScroll: self.collectionView
        )
    }

    public override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.messagesAdapter.scrollViewWillBeginDragging?(scrollView)
        self.delegate?.chatMessagesViewController(self, willBeginDragging: scrollView)
    }

    public override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.messagesAdapter.scrollViewWillEndDragging?(
            scrollView,
            withVelocity: velocity,
            targetContentOffset: targetContentOffset
        )

        self.delegate?.chatMessagesViewController(
            self,
            willEndDragging: scrollView,
            withVelocity: velocity,
            targetContentOffset: targetContentOffset
        )
    }

    public override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
         self.autoLoadMoreContentIfNeeded()
     }

    public override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.messagesAdapter.scrollViewDidEndDragging?(
            scrollView,
            willDecelerate: decelerate
        )

        self.delegate?.chatMessagesViewController(
            self,
            scrollViewDidEndDragging: scrollView,
            willDecelerate: decelerate
        )
    }
}

extension ChatMessagesViewController: ChatMessageCollectionAdapterDelegate {
    public var isFirstLoad: Bool { self.isFirstLayout }

    public func chatMessageCollectionAdapter(_: ChatMessageCollectionAdapterProtocol, onDisplayCellWithIndexPath indexPath: IndexPath) {
        self.delegate?.chatMessagesViewController(self, onDisplayCellWithIndexPath: indexPath)
    }

    public func chatMessageCollectionAdapterShouldAnimateCellOnDisplay(_ : ChatMessageCollectionAdapterProtocol) -> Bool {
        return self.delegate?.chatMessagesViewControllerShouldAnimateCellOnDisplay(self) ?? false
    }

    public func chatMessageCollectionAdapter(_ : ChatMessageCollectionAdapter, didUpdateItemsWithUpdateType updateType: UpdateType) {
        self.delegate?.chatMessagesViewController(self, didUpdateItemsWithUpdateType: updateType)
    }
}

public extension ChatMessagesViewController {
    struct Style {
        public var alwaysBounceVertical: Bool
        public var backgroundColor: UIColor
        public var contentInsets: UIEdgeInsets
        public var keyboardDismissMode: UIScrollView.KeyboardDismissMode
        public var scrollIndicatorInsets: UIEdgeInsets
        public var shouldShowVerticalScrollView: Bool
        public var updatesAnimationDuration: TimeInterval

        public init(alwaysBounceVertical: Bool,
                    backgroundColor: UIColor,
                    contentInsets: UIEdgeInsets,
                    keyboardDismissMode: UIScrollView.KeyboardDismissMode,
                    scrollIndicatorInsets: UIEdgeInsets,
                    shouldShowVerticalScrollView: Bool,
                    updatesAnimationDuration: TimeInterval) {
            self.alwaysBounceVertical = alwaysBounceVertical
            self.backgroundColor = backgroundColor
            self.contentInsets = contentInsets
            self.keyboardDismissMode = keyboardDismissMode
            self.scrollIndicatorInsets = scrollIndicatorInsets
            self.shouldShowVerticalScrollView = shouldShowVerticalScrollView
            self.updatesAnimationDuration = updatesAnimationDuration
        }
    }

    struct Config {
        public var autoLoadingEnabled: Bool
        public var autoMarginThreshold: CGFloat

        public init(autoLoadingEnabled: Bool,
                    autoMarginThreshold: CGFloat) {
            self.autoLoadingEnabled = autoLoadingEnabled
            self.autoMarginThreshold = autoMarginThreshold
        }
    }
}

public extension ChatMessagesViewController.Style {
    static var `default`: Self {
        return .init(
            alwaysBounceVertical: true,
            backgroundColor: .clear,
            contentInsets: .init(
                top: 10,
                left: 0,
                bottom: 10,
                right: 0
            ),
            keyboardDismissMode: .interactive,
            scrollIndicatorInsets: .zero,
            shouldShowVerticalScrollView: true,
            updatesAnimationDuration: 0.33
        )
    }
}

public extension ChatMessagesViewController.Config {
    static var `default`: Self {
        return .init(
            autoLoadingEnabled: true,
            autoMarginThreshold: 0.05

        )
    }
}
