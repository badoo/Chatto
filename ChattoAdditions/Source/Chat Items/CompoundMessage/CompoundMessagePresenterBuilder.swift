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

import Chatto

@available(iOS 11, *)
public final class CompoundMessagePresenterBuilder<ViewModelBuilderT, InteractionHandlerT>: ChatItemPresenterBuilderProtocol where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    ViewModelBuilderT.ModelT: Equatable & ContentEquatableChatItemProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.MessageType == ViewModelBuilderT.ModelT,
    InteractionHandlerT.ViewModelType == ViewModelBuilderT.ViewModelT {
    public typealias ModelT = ViewModelBuilderT.ModelT
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT

    public init(
        viewModelBuilder: ViewModelBuilderT,
        interactionHandler: InteractionHandlerT?,
        accessibilityIdentifier: String?,
        contentFactories: [AnyMessageContentFactory<ModelT>],
        decorationFactories: [AnyMessageDecorationViewFactory<ModelT>] = [],
        compoundCellStyle: CompoundBubbleViewStyleProtocol = DefaultCompoundBubbleViewStyle(),
        baseCellStyle: BaseMessageCollectionViewCellStyleProtocol = BaseMessageCollectionViewCellDefaultStyle()) {
        self.viewModelBuilder = viewModelBuilder
        self.interactionHandler = interactionHandler
        self.contentFactories = contentFactories
        self.decorationFactories = decorationFactories
        self.accessibilityIdentifier = accessibilityIdentifier
        self.compoundCellStyle = compoundCellStyle
        self.baseCellStyle = baseCellStyle
    }

    public let viewModelBuilder: ViewModelBuilderT
    public let interactionHandler: InteractionHandlerT?
    private let contentFactories: [AnyMessageContentFactory<ModelT>]
    private let decorationFactories: [AnyMessageDecorationViewFactory<ModelT>]
    public let sizingCell: CompoundMessageCollectionViewCell = CompoundMessageCollectionViewCell()
    private let compoundCellStyle: CompoundBubbleViewStyleProtocol
    private let baseCellStyle: BaseMessageCollectionViewCellStyleProtocol
    private let cache = Cache<CompoundBubbleLayoutProvider.Configuration, CompoundBubbleLayoutProvider>()
    private let accessibilityIdentifier: String?

    public func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return self.viewModelBuilder.canCreateViewModel(fromModel: chatItem)
    }

    public func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(self.canHandleChatItem(chatItem))
        return CompoundMessagePresenter<ViewModelBuilderT, InteractionHandlerT>(
            messageModel: chatItem as! ModelT,
            viewModelBuilder: self.viewModelBuilder,
            interactionHandler: self.interactionHandler,
            contentFactories: self.contentFactories,
            sizingCell: self.sizingCell,
            baseCellStyle: self.baseCellStyle,
            compoundCellStyle: self.compoundCellStyle,
            cache: self.cache,
            accessibilityIdentifier: self.accessibilityIdentifier,
            decorationFactories: self.decorationFactories
        )
    }

    public var presenterType: ChatItemPresenterProtocol.Type {
        return CompoundMessagePresenter<ViewModelBuilderT, InteractionHandlerT>.self
    }
}
