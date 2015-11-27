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

public protocol ChatItemsDecoratorProtocol {
    func decorateItems(chatItems: [ChatItemProtocol]) -> [DecoratedChatItem]
}

public struct DecoratedChatItem {
    public let chatItem: ChatItemProtocol
    public let decorationAttributes: ChatItemDecorationAttributesProtocol?
    public init(chatItem: ChatItemProtocol, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        self.chatItem = chatItem
        self.decorationAttributes = decorationAttributes
    }
}

public class ChatViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    public struct Constants {
        var updatesAnimationDuration: NSTimeInterval = 0.33
        var defaultContentinsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        var defaultScrollIndicatorInsets = UIEdgeInsetsZero
        var preferredMaxMessageCount: Int? = 500 // It not nil, will ask data source to reduce number of messages when limit is reached. @see ChatDataSourceDelegateProtocol
        var preferredMaxMessageCountAdjustment: Int = 400 // When the above happens, will ask to adjust with this value. It may be wise for this to be smaller to reduce number of adjustments
        var autoloadingFractionalThreshold: CGFloat = 0.05 // in [0, 1]
    }

    public var constants = Constants()

    public private(set) var collectionView: UICollectionView!
    var decoratedChatItems = [DecoratedChatItem]()
    public var chatDataSource: ChatDataSourceProtocol? {
        didSet {
            self.chatDataSource?.delegate = self
            self.enqueueModelUpdate(context: .Reload)
        }
    }

    deinit {
        self.collectionView.delegate = nil
        self.collectionView.dataSource = nil
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.addCollectionView()
        self.addInputViews()
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
        self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: self.createCollectionViewLayout)
        self.collectionView.contentInset = self.constants.defaultContentinsets
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

        self.presenterBuildersByType = self.createPresenterBuilders()

        for presenterBuilder in self.presenterBuildersByType.flatMap({ $0.1 }) {
            presenterBuilder.presenterType.registerCells(self.collectionView)
        }
        DummyChatItemPresenter.registerCells(self.collectionView)
    }

    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private func addInputViews() {
        self.inputContainer = UIView(frame: CGRectZero)
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

        self.keyboardTracker = KeyboardTracker(viewController: self, inputContainer: self.inputContainer, inputContainerBottomContraint: self.inputContainerBottomConstraint, notificationCenter: self.notificationCenter)
    }
    var notificationCenter = NSNotificationCenter.defaultCenter()
    var keyboardTracker: KeyboardTracker!

    public override var inputAccessoryView: UIView {
        return self.keyboardTracker.trackingView
    }

    public var isFirstLayout: Bool = true
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.adjustCollectionViewInsets()
        self.keyboardTracker.layoutTrackingViewIfNeeded()

        if self.isFirstLayout {
            self.updateQueue.start()
            self.isFirstLayout = false
        }
    }

    private func adjustCollectionViewInsets() {
        let isInteracting = self.collectionView.panGestureRecognizer.numberOfTouches() > 0
        let isBouncingAtTop = isInteracting && self.collectionView.contentOffset.y < -self.collectionView.contentInset.top
        if isBouncingAtTop { return }

        let inputHeightWithKeyboard = self.view.bounds.height - self.inputContainer.frame.minY
        let newInsetBottom = self.constants.defaultContentinsets.bottom + inputHeightWithKeyboard
        let insetBottomDiff = newInsetBottom - self.collectionView.contentInset.bottom

        let allContentFits = self.collectionView.bounds.height - newInsetBottom - (self.collectionView.contentSize.height + self.collectionView.contentInset.top) >= 0

        let currentDistanceToBottomInset = max(0, self.collectionView.bounds.height - self.collectionView.contentInset.bottom - (self.collectionView.contentSize.height - self.collectionView.contentOffset.y))
        let newContentOffsetY = self.collectionView.contentOffset.y + insetBottomDiff - currentDistanceToBottomInset

        self.collectionView.contentInset.bottom = newInsetBottom
        self.collectionView.scrollIndicatorInsets.bottom = self.constants.defaultScrollIndicatorInsets.bottom + inputHeightWithKeyboard
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
    var inputContainer: UIView!
    var presenterBuildersByType = [ChatItemType: [ChatItemPresenterBuilderProtocol]]()
    var presenters = [ChatItemPresenterProtocol]()
    let presentersByChatItem = NSMapTable(keyOptions: .WeakMemory, valueOptions: .StrongMemory)
    let presentersByCell = NSMapTable(keyOptions: .WeakMemory, valueOptions: .WeakMemory)
    var updateQueue: SerialTaskQueueProtocol = SerialTaskQueue()

    public func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        assert(false, "Override in subclass")
        return [ChatItemType: [ChatItemPresenterBuilderProtocol]]()
    }

    public func createChatInputView() -> UIView {
        assert(false, "Override in subclass")
        return UIView()
    }

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
}

extension ChatViewController { // Rotation

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
