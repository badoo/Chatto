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

public class PhotoMessagePresenter<ViewModelBuilderT, InteractionHandlerT where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    ViewModelBuilderT.ModelT: PhotoMessageModelProtocol,
    ViewModelBuilderT.ViewModelT: PhotoMessageViewModelProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT>
: BaseMessagePresenter<PhotoBubbleView, ViewModelBuilderT, InteractionHandlerT> {
    public typealias ModelT = ViewModelBuilderT.ModelT
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT

    public init (
        messageModel: ModelT,
        viewModelBuilder: ViewModelBuilderT,
        interactionHandler: InteractionHandlerT?,
        sizingCell: PhotoMessageCollectionViewCell,
        baseCellStyle: BaseMessageCollectionViewCellStyleProtocol,
        photoCellStyle: PhotoMessageCollectionViewCellStyleProtocol) {
            self.photoCellStyle = photoCellStyle
            super.init(
                messageModel: messageModel,
                viewModelBuilder: viewModelBuilder,
                interactionHandler: interactionHandler,
                sizingCell: sizingCell,
                cellStyle: baseCellStyle
            )
    }

    let photoCellStyle: PhotoMessageCollectionViewCellStyleProtocol

    public override class func registerCells(collectionView: UICollectionView) {
        collectionView.registerClass(PhotoMessageCollectionViewCell.self, forCellWithReuseIdentifier: "photo-message")
    }

    public override func dequeueCell(collectionView collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier("photo-message", forIndexPath: indexPath)
    }

    public override func createViewModel() -> ViewModelBuilderT.ViewModelT {
        let viewModel = self.viewModelBuilder.createViewModel(self.messageModel)
        let updateClosure = { [weak self] (old: Any, new: Any) -> () in
            self?.updateCurrentCell()
        }
        viewModel.image.observe(self, closure: updateClosure)
        viewModel.transferDirection.observe(self, closure: updateClosure)
        viewModel.transferProgress.observe(self, closure: updateClosure)
        viewModel.transferStatus.observe(self, closure: updateClosure)
        return viewModel
    }

    var photoCell: PhotoMessageCollectionViewCell? {
        if let cell = self.cell {
            if let photoCell = cell as? PhotoMessageCollectionViewCell {
                return photoCell
            } else {
                assert(false, "Invalid cell was given to presenter!")
            }
        }
        return nil
    }

    public override func configureCell(cell: BaseMessageCollectionViewCell<PhotoBubbleView>, decorationAttributes: ChatItemDecorationAttributes,  animated: Bool, additionalConfiguration: (() -> Void)?) {
        guard let cell = cell as? PhotoMessageCollectionViewCell else {
            assert(false, "Invalid cell received")
            return
        }

        super.configureCell(cell, decorationAttributes: decorationAttributes, animated: animated) { () -> Void in
            cell.photoMessageViewModel = self.messageViewModel
            cell.photoMessageStyle = self.photoCellStyle
            additionalConfiguration?()
        }
    }

    public override func cellWillBeShown() {
        self.messageViewModel.willBeShown()
    }


    public override func cellWasHidden() {
        self.messageViewModel.wasHidden()
    }

    public func updateCurrentCell() {
        if let cell = self.photoCell, decorationAttributes = self.decorationAttributes {
            self.configureCell(cell, decorationAttributes: decorationAttributes, animated: self.itemVisibility != .Appearing, additionalConfiguration: nil)
        }
    }
}
