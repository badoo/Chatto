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
    typealias ModelT: MessageModelProtocol
    typealias ViewModelT: MessageViewModelProtocol
    func createViewModel(model: ModelT) -> ViewModelT
}

public protocol BaseMessageInteractionHandlerProtocol {
    typealias ViewModelT
    func userDidTapOnFailIcon(viewModel viewModel: ViewModelT)
    func userDidTapOnBubble(viewModel viewModel: ViewModelT)
    func userDidLongPressOnBubble(viewModel viewModel: ViewModelT)
}

public class BaseMessagePresenter<BubbleViewT, ViewModelBuilderT, InteractionHandlerT where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    ViewModelBuilderT.ModelT: MessageModelProtocol,
    ViewModelBuilderT.ViewModelT: MessageViewModelProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT,
    BubbleViewT: UIView, BubbleViewT:MaximumLayoutWidthSpecificable, BubbleViewT: BackgroundSizingQueryable>: BaseChatItemPresenter<BaseMessageCollectionViewCell<BubbleViewT>> {
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

    let messageModel: ModelT
    let sizingCell: BaseMessageCollectionViewCell<BubbleViewT>
    let viewModelBuilder: ViewModelBuilderT
    let interactionHandler: InteractionHandlerT?
    let cellStyle: BaseMessageCollectionViewCellStyleProtocol

    public private(set) final lazy var messageViewModel: ViewModelT = {
        return self.createViewModel()
    }()

    public func createViewModel() -> ViewModelT {
        let viewModel = self.viewModelBuilder.createViewModel(self.messageModel)
        return viewModel
    }

    public final override func configureCell(cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
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

    var decorationAttributes: ChatItemDecorationAttributes!
    public func configureCell(cell: CellT, decorationAttributes: ChatItemDecorationAttributes, animated: Bool, additionalConfiguration: (() -> Void)?) {
        cell.performBatchUpdates({ () -> Void in
            self.messageViewModel.showsTail = decorationAttributes.showsTail
            cell.bubbleView.userInteractionEnabled = true // just in case something went wrong while showing UIMenuController
            cell.baseStyle = self.cellStyle
            cell.messageViewModel = self.messageViewModel
            cell.onBubbleTapped = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.interactionHandler?.userDidTapOnBubble(viewModel: sSelf.messageViewModel)
            }
            cell.onBubbleLongPressed = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.interactionHandler?.userDidLongPressOnBubble(viewModel: sSelf.messageViewModel)
            }
            cell.onFailedButtonTapped = { [weak self] (cell) in
                guard let sSelf = self else { return }
                sSelf.interactionHandler?.userDidTapOnFailIcon(viewModel: sSelf.messageViewModel)
            }
            additionalConfiguration?()
        }, animated: animated, completion: nil)
    }

  public override func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        guard let decorationAttributes = decorationAttributes as? ChatItemDecorationAttributes else {
            assert(false, "Expecting decoration attributes")
            return 0
        }
        self.configureCell(self.sizingCell, decorationAttributes: decorationAttributes, animated: false, additionalConfiguration: nil)
        return self.sizingCell.sizeThatFits(CGSize(width: width, height: CGFloat.max)).height
    }

    public override var canCalculateHeightInBackground: Bool {
        return self.sizingCell.canCalculateSizeInBackground
    }

    public override func shouldShowMenu() -> Bool {
        guard self.canShowMenu() else { return false }
        guard let cell = self.cell else {
            assert(false, "Investigate -> Fix or remove assert")
            return false
        }
        cell.bubbleView.userInteractionEnabled = false // This is a hack for UITextView, shouldn't harm to all bubbles
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willShowMenu:", name: UIMenuControllerWillShowMenuNotification, object: nil)
        return true
    }

    @objc
    func willShowMenu(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillShowMenuNotification, object: nil)
        guard let cell = self.cell, menuController = notification.object as? UIMenuController else {
            assert(false, "Investigate -> Fix or remove assert")
            return
        }
        cell.bubbleView.userInteractionEnabled = true
        menuController.setMenuVisible(false, animated: false)
        menuController.setTargetRect(cell.bubbleView.bounds, inView: cell.bubbleView)
        menuController.setMenuVisible(true, animated: true)
    }

    public func canShowMenu() -> Bool {
        // Override in subclass
        return false
    }
}
