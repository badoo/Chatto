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

import Foundation
import Chatto

public protocol ViewModelBuilderProtocol {
    associatedtype ModelT: MessageModelProtocol
    associatedtype ViewModelT: MessageViewModelProtocol
    func canCreateViewModel(fromModel model: Any) -> Bool
    func createViewModel(_ model: ModelT) -> ViewModelT
}

public protocol BaseMessageInteractionHandlerProtocol {
    associatedtype ViewModelT
    func userDidTapOnFailIcon(viewModel: ViewModelT, failIconView: UIView)
    func userDidTapOnAvatar(viewModel: ViewModelT)
    func userDidTapOnBubble(viewModel: ViewModelT)
    func userDidBeginLongPressOnBubble(viewModel: ViewModelT)
    func userDidEndLongPressOnBubble(viewModel: ViewModelT)
    func userDidSelectMessage(viewModel: ViewModelT)
    func userDidDeselectMessage(viewModel: ViewModelT)
}

open class BaseMessagePresenter<BubbleViewT, ViewModelBuilderT, InteractionHandlerT>: BaseChatItemPresenter<BaseMessageCollectionViewCell<BubbleViewT>> where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT,
    BubbleViewT: UIView,
    BubbleViewT: MaximumLayoutWidthSpecificable,
    BubbleViewT: BackgroundSizingQueryable {

    public typealias CellT = BaseMessageCollectionViewCell<BubbleViewT>
    public typealias ModelT = ViewModelBuilderT.ModelT
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT

    public init (
        messageModel: ModelT,
        viewModelBuilder: ViewModelBuilderT,
        interactionHandler: InteractionHandlerT?,
        sizingCell: BaseMessageCollectionViewCell<BubbleViewT>,
        cellStyle: BaseMessageCollectionViewCellStyleProtocol) {
            self.messageModel = messageModel
            self.sizingCell = sizingCell
            self.viewModelBuilder = viewModelBuilder
            self.cellStyle = cellStyle
            self.interactionHandler = interactionHandler
    }

    public internal(set) var messageModel: ModelT {
        didSet { self.messageViewModel = self.createViewModel() }
    }

    open override var isItemUpdateSupported: Bool {
        /*
         By default, item updates are not supported.
         But this behaviour could be changed by the descendants.
         In this case, an update method checks item type, sets a new value for a message model and creates a new message view model.
         */
        return false
    }

    open override func update(with chatItem: ChatItemProtocol) {
        assert(self.isItemUpdateSupported, "Updated is called on presenter which doesn't support updates: \(type(of: chatItem)).")
        guard let newMessageModel = chatItem as? ModelT else { assertionFailure("Unexpected type of the message: \(type(of: chatItem))."); return }
        self.messageModel = newMessageModel
    }

    public let sizingCell: BaseMessageCollectionViewCell<BubbleViewT>
    public let viewModelBuilder: ViewModelBuilderT
    public let interactionHandler: InteractionHandlerT?
    public let cellStyle: BaseMessageCollectionViewCellStyleProtocol

    public private(set) final lazy var messageViewModel: ViewModelT = self.createViewModel()

    open func createViewModel() -> ViewModelT {
        let viewModel = self.viewModelBuilder.createViewModel(self.messageModel)
        return viewModel
    }

    public final override func configureCell(_ cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        guard let cell = cell as? CellT else {
            assert(false, "Invalid cell given to presenter")
            return
        }
        guard let decorationAttributes = decorationAttributes as? ChatItemDecorationAttributes else {
            assert(false, "Expecting decoration attributes")
            return
        }

        self.decorationAttributes = decorationAttributes
        self.configureCell(cell, decorationAttributes: decorationAttributes, animated: false, additionalConfiguration: nil)
    }

    public var decorationAttributes: ChatItemDecorationAttributes!
    open func configureCell(_ cell: CellT, decorationAttributes: ChatItemDecorationAttributes, animated: Bool, additionalConfiguration: (() -> Void)?) {
        cell.performBatchUpdates({ () -> Void in
            self.messageViewModel.decorationAttributes = decorationAttributes.messageDecorationAttributes
            // just in case something went wrong while showing UIMenuController
            self.messageViewModel.isUserInteractionEnabled = true
            cell.baseStyle = self.cellStyle
            cell.messageViewModel = self.messageViewModel

            cell.allowAccessoryViewRevealing = !decorationAttributes.messageDecorationAttributes.isShowingSelectionIndicator
            cell.onBubbleTapped = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.onCellBubbleTapped()
            }
            cell.onBubbleLongPressBegan = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.onCellBubbleLongPressBegan()
            }
            cell.onBubbleLongPressEnded = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.onCellBubbleLongPressEnded()
            }
            cell.onAvatarTapped = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.onCellAvatarTapped()
            }
            cell.onFailedButtonTapped = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.onCellFailedButtonTapped(cell.failedButton)
            }
            cell.onSelection = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.onCellSelection()
            }
            additionalConfiguration?()
        }, animated: animated, completion: nil)
    }

    open override func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        guard let decorationAttributes = decorationAttributes as? ChatItemDecorationAttributes else {
            assert(false, "Expecting decoration attributes")
            return 0
        }
        self.configureCell(self.sizingCell, decorationAttributes: decorationAttributes, animated: false, additionalConfiguration: nil)
        return self.sizingCell.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    open override var canCalculateHeightInBackground: Bool {
        return self.sizingCell.canCalculateSizeInBackground
    }

    open override func cellWillBeShown() {
        self.messageViewModel.willBeShown()
    }

    open override func cellWasHidden() {
        self.messageViewModel.wasHidden()
    }

    open override func shouldShowMenu() -> Bool {
        guard self.canShowMenu() else { return false }
        guard let cell = self.cell else {
            assert(false, "Investigate -> Fix or remove assert")
            return false
        }
        cell.bubbleView.isUserInteractionEnabled = false // This is a hack for UITextView, shouldn't harm to all bubbles
        NotificationCenter.default.addObserver(self, selector: #selector(BaseMessagePresenter.willShowMenu(_:)), name: UIMenuController.willShowMenuNotification, object: nil)
        return true
    }

    @objc
    func willShowMenu(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.willShowMenuNotification, object: nil)
        guard let cell = self.cell, let menuController = notification.object as? UIMenuController else {
            assert(false, "Investigate -> Fix or remove assert")
            return
        }
        cell.bubbleView.isUserInteractionEnabled = true
        menuController.setMenuVisible(false, animated: false)
        menuController.setTargetRect(cell.bubbleView.bounds, in: cell.bubbleView)
        menuController.setMenuVisible(true, animated: true)
    }

    open func canShowMenu() -> Bool {
        // Override in subclass
        return false
    }

    open func onCellBubbleTapped() {
        self.interactionHandler?.userDidTapOnBubble(viewModel: self.messageViewModel)
    }

    open func onCellBubbleLongPressBegan() {
        self.interactionHandler?.userDidBeginLongPressOnBubble(viewModel: self.messageViewModel)
    }

    open func onCellBubbleLongPressEnded() {
        self.interactionHandler?.userDidEndLongPressOnBubble(viewModel: self.messageViewModel)
    }

    open func onCellAvatarTapped() {
        self.interactionHandler?.userDidTapOnAvatar(viewModel: self.messageViewModel)
    }

    open func onCellFailedButtonTapped(_ failedButtonView: UIView) {
        self.interactionHandler?.userDidTapOnFailIcon(viewModel: self.messageViewModel, failIconView: failedButtonView)
    }

    open func onCellSelection() {
        if self.messageViewModel.decorationAttributes.isSelected {
            self.interactionHandler?.userDidDeselectMessage(viewModel: self.messageViewModel)
        } else {
            self.interactionHandler?.userDidSelectMessage(viewModel: self.messageViewModel)
        }
    }
}
