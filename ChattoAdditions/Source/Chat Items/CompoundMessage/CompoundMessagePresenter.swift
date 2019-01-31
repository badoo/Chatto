//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

@available(iOS 11, *)
public final class CompoundMessagePresenter<ViewModelBuilderT, InteractionHandlerT>
    : BaseMessagePresenter<CompoundBubbleView, ViewModelBuilderT, InteractionHandlerT> where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT {

    public typealias ModelT = ViewModelBuilderT.ModelT
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT

    public let compoundCellStyle: CompoundBubbleViewStyleProtocol
    private let contentFactories: [AnyMessageContentFactory<ModelT>]

    public init(
        messageModel: ModelT,
        viewModelBuilder: ViewModelBuilderT,
        interactionHandler: InteractionHandlerT?,
        contentFactories: [AnyMessageContentFactory<ModelT>],
        sizingCell: CompoundMessageCollectionViewCell,
        baseCellStyle: BaseMessageCollectionViewCellStyleProtocol,
        compoundCellStyle: CompoundBubbleViewStyleProtocol) {
        self.compoundCellStyle = compoundCellStyle
        self.contentFactories = contentFactories
        super.init(
            messageModel: messageModel,
            viewModelBuilder: viewModelBuilder,
            interactionHandler: interactionHandler,
            sizingCell: sizingCell,
            cellStyle: baseCellStyle
        )
    }

    public override class func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(CompoundMessageCollectionViewCell.self,
                                forCellWithReuseIdentifier: .compoundCellReuseId)
    }

    public override func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: .compoundCellReuseId,
                                                  for: indexPath)
    }

    public override func configureCell(_ cell: BaseMessageCollectionViewCell<CompoundBubbleView>,
                                       decorationAttributes: ChatItemDecorationAttributes,
                                       animated: Bool,
                                       additionalConfiguration: (() -> Void)?) {
        guard let compoundCell = cell as? CompoundMessageCollectionViewCell else {
            assertionFailure("\(cell) is not PhotoMessageCollectionViewCell")
            return
        }

        super.configureCell(cell, decorationAttributes: decorationAttributes, animated: animated) {
            compoundCell.bubbleView.viewModel = self.messageViewModel
            compoundCell.bubbleView.style = self.compoundCellStyle
            compoundCell.bubbleView.contentViewsWithLayout = self.contentFactories
                .filter { $0.canCreateMessage(forModel: self.messageModel) }
                .map {
                    let module = $0.createMessageModule(forModel: self.messageModel)
                    return (module.view, module.layoutProvider)
                }
        }
    }
}

private extension String {
    static let compoundCellReuseId = "compound-message"
}
