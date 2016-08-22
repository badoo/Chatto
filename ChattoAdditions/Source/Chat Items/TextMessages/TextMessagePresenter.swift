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

public class TextMessagePresenter<ViewModelBuilderT, InteractionHandlerT where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    ViewModelBuilderT.ViewModelT: TextMessageViewModelProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT>
: BaseMessagePresenter<TextBubbleView, ViewModelBuilderT, InteractionHandlerT> {
    public typealias ModelT = ViewModelBuilderT.ModelT
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT

    public init (
        messageModel: ModelT,
        viewModelBuilder: ViewModelBuilderT,
        interactionHandler: InteractionHandlerT?,
        sizingCell: TextMessageCollectionViewCell,
        baseCellStyle: BaseMessageCollectionViewCellStyleProtocol,
        textCellStyle: TextMessageCollectionViewCellStyleProtocol,
        layoutCache: NSCache) {
            self.layoutCache = layoutCache
            self.textCellStyle = textCellStyle
            super.init(
                messageModel: messageModel,
                viewModelBuilder: viewModelBuilder,
                interactionHandler: interactionHandler,
                sizingCell: sizingCell,
                cellStyle: baseCellStyle
            )
    }

    let layoutCache: NSCache
    let textCellStyle: TextMessageCollectionViewCellStyleProtocol

    public override class func registerCells(collectionView: UICollectionView) {
        collectionView.registerClass(TextMessageCollectionViewCell.self, forCellWithReuseIdentifier: "text-message-incoming")
        collectionView.registerClass(TextMessageCollectionViewCell.self, forCellWithReuseIdentifier: "text-message-outcoming")
    }

    public override func dequeueCell(collectionView collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = self.messageViewModel.isIncoming ? "text-message-incoming" : "text-message-outcoming"
        return collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
    }

    public override func createViewModel() -> ViewModelBuilderT.ViewModelT {
        let viewModel = self.viewModelBuilder.createViewModel(self.messageModel)
        let updateClosure = { [weak self] (old: Any, new: Any) -> () in
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

    public override func configureCell(cell: BaseMessageCollectionViewCell<TextBubbleView>, decorationAttributes: ChatItemDecorationAttributes, animated: Bool, additionalConfiguration: (() -> Void)?) {
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
        if let cell = self.textCell, decorationAttributes = self.decorationAttributes {
            self.configureCell(cell, decorationAttributes: decorationAttributes, animated: self.itemVisibility != .Appearing, additionalConfiguration: nil)
        }
    }

    public override func canShowMenu() -> Bool {
        return true
    }

    public override func canPerformMenuControllerAction(action: Selector) -> Bool {
        #if swift(>=2.3)
            let selector = #selector(UIResponderStandardEditActions.copy(_:))
        #else
            let selector = #selector(NSObject.copy(_:))
        #endif
        return action == selector
    }

    public override func performMenuControllerAction(action: Selector) {
        #if swift(>=2.3)
            let selector = #selector(UIResponderStandardEditActions.copy(_:))
        #else
            let selector = #selector(NSObject.copy(_:))
        #endif
        if action == selector {
            UIPasteboard.generalPasteboard().string = self.messageViewModel.text
        } else {
            assert(false, "Unexpected action")
        }
    }
}
