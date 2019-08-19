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
import Chatto

open class TextMessagePresenter<ViewModelBuilderT, InteractionHandlerT>
: BaseMessagePresenter<TextBubbleView, ViewModelBuilderT, InteractionHandlerT> where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    ViewModelBuilderT.ViewModelT: TextMessageViewModelProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT {
    public typealias ModelT = ViewModelBuilderT.ModelT
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT

    public init (messageModel: ModelT,
                 viewModelBuilder: ViewModelBuilderT,
                 interactionHandler: InteractionHandlerT?,
                 sizingCell: TextMessageCollectionViewCell,
                 baseCellStyle: BaseMessageCollectionViewCellStyleProtocol,
                 textCellStyle: TextMessageCollectionViewCellStyleProtocol,
                 layoutCache: NSCache<AnyObject, AnyObject>,
                 menuPresenter: TextMessageMenuItemPresenterProtocol?) {
        self.layoutCache = layoutCache
        self.textCellStyle = textCellStyle
        self.menuPresenter = menuPresenter
        super.init(
            messageModel: messageModel,
            viewModelBuilder: viewModelBuilder,
            interactionHandler: interactionHandler,
            sizingCell: sizingCell,
            cellStyle: baseCellStyle
        )
    }

    private let menuPresenter: TextMessageMenuItemPresenterProtocol?
    let layoutCache: NSCache<AnyObject, AnyObject>
    let textCellStyle: TextMessageCollectionViewCellStyleProtocol

    public final override class func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(TextMessageCollectionViewCell.self, forCellWithReuseIdentifier: "text-message-incoming")
        collectionView.register(TextMessageCollectionViewCell.self, forCellWithReuseIdentifier: "text-message-outcoming")
    }

    open override var isItemUpdateSupported: Bool {
        return true
    }

    public final override func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = self.messageViewModel.isIncoming ? "text-message-incoming" : "text-message-outcoming"
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }

    open override func createViewModel() -> ViewModelBuilderT.ViewModelT {
        let viewModel = self.viewModelBuilder.createViewModel(self.messageModel)
        let updateClosure = { [weak self] (old: Any, new: Any) -> Void in
            self?.updateCurrentCell()
        }
        viewModel.avatarImage.observe(self, closure: updateClosure)
        return viewModel
    }

    public var textCell: TextMessageCollectionViewCell? {
        if let cell = self.cell {
            if let textCell = cell as? TextMessageCollectionViewCell {
                return textCell
            } else {
                assert(false, "Invalid cell was given to presenter!")
            }
        }
        return nil
    }

    open override func configureCell(_ cell: BaseMessageCollectionViewCell<TextBubbleView>, decorationAttributes: ChatItemDecorationAttributes, animated: Bool, additionalConfiguration: (() -> Void)?) {
        guard let cell = cell as? TextMessageCollectionViewCell else {
            assert(false, "Invalid cell received")
            return
        }

        super.configureCell(cell, decorationAttributes: decorationAttributes, animated: animated) { () -> Void in
            cell.layoutCache = self.layoutCache
            cell.textMessageViewModel = self.messageViewModel
            cell.textMessageStyle = self.textCellStyle
            additionalConfiguration?()
        }
    }

    public func updateCurrentCell() {
        if let cell = self.textCell, let decorationAttributes = self.decorationAttributes {
            self.configureCell(cell, decorationAttributes: decorationAttributes, animated: self.itemVisibility != .appearing, additionalConfiguration: nil)
        }
    }

    open override func canShowMenu() -> Bool {
        return self.menuPresenter?.shouldShowMenu(for: self.messageViewModel.text, item: self.messageModel) ?? false
    }

    open override func canPerformMenuControllerAction(_ action: Selector) -> Bool {
        return self.menuPresenter?.canPerformMenuControllerAction(action, for: self.messageViewModel.text, item: self.messageModel) ?? false
    }

    open override func performMenuControllerAction(_ action: Selector) {
        self.menuPresenter?.performMenuControllerAction(action, for: self.messageViewModel.text, item: self.messageModel)
    }
}
