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
open class CompoundMessagePresenter<ViewModelBuilderT, InteractionHandlerT>
    : BaseMessagePresenter<CompoundBubbleView, ViewModelBuilderT, InteractionHandlerT> where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    ViewModelBuilderT.ModelT: Equatable,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT {

    public typealias ModelT = ViewModelBuilderT.ModelT
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT

    public let compoundCellStyle: CompoundBubbleViewStyleProtocol
    private let contentFactories: [AnyMessageContentFactory<ModelT>]

    private let cache: Cache<CompoundBubbleLayoutProvider.Configuration, CompoundBubbleLayoutProvider>
    private let accessibilityIdentifier: String?
    private let menuPresenter: ChatItemMenuPresenterProtocol?

    private lazy var layoutProvider: CompoundBubbleLayoutProvider = self.makeLayoutProvider()
    private lazy var contentPresenters: [MessageContentPresenterProtocol] = self.contentFactories.map { $0.createContentPresenter(forModel: self.messageModel) }
    private var viewReferences: [ViewReference] = []

    public init(
        messageModel: ModelT,
        viewModelBuilder: ViewModelBuilderT,
        interactionHandler: InteractionHandlerT?,
        contentFactories: [AnyMessageContentFactory<ModelT>],
        sizingCell: CompoundMessageCollectionViewCell,
        baseCellStyle: BaseMessageCollectionViewCellStyleProtocol,
        compoundCellStyle: CompoundBubbleViewStyleProtocol,
        cache: Cache<CompoundBubbleLayoutProvider.Configuration, CompoundBubbleLayoutProvider>,
        accessibilityIdentifier: String?
    ) {
        self.compoundCellStyle = compoundCellStyle
        self.contentFactories = contentFactories.filter { $0.canCreateMessageContent(forModel: messageModel) }
        self.cache = cache
        self.accessibilityIdentifier = accessibilityIdentifier
        self.menuPresenter = self.contentFactories.lazy.compactMap { $0.createMenuPresenter(forModel: messageModel) }.first
        super.init(
            messageModel: messageModel,
            viewModelBuilder: viewModelBuilder,
            interactionHandler: interactionHandler,
            sizingCell: sizingCell,
            cellStyle: baseCellStyle
        )
    }

    open override var canCalculateHeightInBackground: Bool {
        return true
    }

    open override class func registerCells(_ collectionView: UICollectionView) {
        // Cell registration is happening lazily, right before the moment when a cell is dequeued.
    }

    open override func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cellReuseIdentifier = self.compoundCellReuseId
        collectionView.register(CompoundMessageCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        return collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
    }

    open override func heightForCell(maximumWidth width: CGFloat,
                                     decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        let layoutConstants = self.cellStyle.layoutConstants(viewModel: self.messageViewModel)
        let maxWidth = (width * layoutConstants.maxContainerWidthPercentageForBubbleView)
        return self.layoutProvider.layout(forMaxWidth: maxWidth).size.height
    }

    open override func configureCell(_ cell: BaseMessageCollectionViewCell<CompoundBubbleView>,
                                     decorationAttributes: ChatItemDecorationAttributes,
                                     animated: Bool,
                                     additionalConfiguration: (() -> Void)?) {
        guard let compoundCell = cell as? CompoundMessageCollectionViewCell else {
            assertionFailure("\(cell) is not CompoundMessageCollectionViewCell")
            return
        }

        super.configureCell(compoundCell, decorationAttributes: decorationAttributes, animated: animated) { [weak self] in
            defer { additionalConfiguration?() }
            guard let sSelf = self else { return }

            let bubbleView = compoundCell.bubbleView!
            bubbleView.viewModel = sSelf.messageViewModel
            bubbleView.layoutProvider = sSelf.layoutProvider
            bubbleView.style = sSelf.compoundCellStyle            

            if bubbleView.decoratedContentViews == nil {
                bubbleView.accessibilityIdentifier = sSelf.accessibilityIdentifier
                bubbleView.decoratedContentViews = zip(sSelf.contentFactories, sSelf.contentPresenters).map { factory, presenter in
                    return CompoundBubbleView.DecoratedView(view: factory.createContentView(), showBorder: presenter.showBorder)
                }
            }

            /*
             There is a current algorithm of binding (and unbinding, as well) compoundCell's views to their presenters:
             1. Already bound presenters are unbound from views: each presenter is responsible for cleaning up its view.
             2. All the view references are destroyed to break a connection between compoundCell's views and their previous presenters. These presenters will lose the opportunity to affect compoundCell's views.
             3. CompoundCell's views bound with a current compound message presenters.
             */

            sSelf.contentPresenters.forEach { $0.unbindFromView() }

            sSelf.viewReferences = zip(sSelf.contentPresenters, bubbleView.decoratedContentViews!.map({ $0.view })).map { presenter, view in
                let viewReference = ViewReference(to: view)
                presenter.bindToView(with: viewReference)
                return viewReference
            }
        }
    }

    open override func cellWillBeShown() {
        super.cellWillBeShown()
        self.contentPresenters.forEach { $0.contentWillBeShown() }
    }

    open override func cellWasHidden() {
        super.cellWasHidden()
        self.contentPresenters.forEach { $0.contentWasHidden() }
    }

    open override func onCellBubbleTapped() {
        super.onCellBubbleTapped()
        self.contentPresenters.forEach { $0.contentWasTapped_deprecated() }
    }

    private func makeLayoutProvider() -> CompoundBubbleLayoutProvider {
        let configuration: CompoundBubbleLayoutProvider.Configuration = {
            let contentLayoutProviders = self.contentFactories.map { $0.createLayoutProvider(forModel: self.messageModel) }
            let viewModel = self.messageViewModel
            let tailWidth = self.compoundCellStyle.tailWidth(forViewModel: viewModel)
            return CompoundBubbleLayoutProvider.Configuration(
                layoutProviders: contentLayoutProviders,
                tailWidth: tailWidth,
                isIncoming: viewModel.isIncoming
            )
        }()
        guard let provider = self.cache[configuration] else {
            let provider = CompoundBubbleLayoutProvider(configuration: configuration)
            self.cache[configuration] = provider
            return provider
        }
        return provider
    }

    private lazy var compoundCellReuseId = "compound-message-[\(self.contentFactories.map { $0.identifier }.joined(separator: "-"))]"

    // MARK: - ChatItemMenuPresenterProtocol

    open override func canShowMenu() -> Bool {
        return self.menuPresenter?.shouldShowMenu() ?? false
    }

    open override func canPerformMenuControllerAction(_ action: Selector) -> Bool {
        return self.menuPresenter?.canPerformMenuControllerAction(action) ?? false
    }

    open override func performMenuControllerAction(_ action: Selector) {
        self.menuPresenter?.performMenuControllerAction(action)
    }
}
