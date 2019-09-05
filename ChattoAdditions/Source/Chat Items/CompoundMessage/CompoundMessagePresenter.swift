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
    : BaseMessagePresenter<CompoundBubbleView, ViewModelBuilderT, InteractionHandlerT>, MessageContentPresenterDelegate where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    ViewModelBuilderT.ModelT: Equatable & ContentEquatableChatItemProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT {

    public typealias ModelT = ViewModelBuilderT.ModelT
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT

    public let compoundCellStyle: CompoundBubbleViewStyleProtocol

    private let compoundCellDimensions: CompoundBubbleLayoutProvider.Dimensions
    private let cache: Cache<CompoundBubbleLayoutProvider.Configuration, CompoundBubbleLayoutProvider>
    private let accessibilityIdentifier: String?

    private let initialContentFactories: [AnyMessageContentFactory<ModelT>]
    private var contentFactories: [AnyMessageContentFactory<ModelT>]!
    private var contentPresenters: [MessageContentPresenterProtocol]!
    private var menuPresenter: ChatItemMenuPresenterProtocol?

    public init(
        messageModel: ModelT,
        viewModelBuilder: ViewModelBuilderT,
        interactionHandler: InteractionHandlerT?,
        contentFactories: [AnyMessageContentFactory<ModelT>],
        sizingCell: CompoundMessageCollectionViewCell,
        baseCellStyle: BaseMessageCollectionViewCellStyleProtocol,
        compoundCellStyle: CompoundBubbleViewStyleProtocol,
        compoundCellDimensions: CompoundBubbleLayoutProvider.Dimensions,
        cache: Cache<CompoundBubbleLayoutProvider.Configuration, CompoundBubbleLayoutProvider>,
        accessibilityIdentifier: String?
    ) {
        self.compoundCellStyle = compoundCellStyle
        self.compoundCellDimensions = compoundCellDimensions
        self.initialContentFactories = contentFactories
        self.cache = cache
        self.accessibilityIdentifier = accessibilityIdentifier
        super.init(
            messageModel: messageModel,
            viewModelBuilder: viewModelBuilder,
            interactionHandler: interactionHandler,
            sizingCell: sizingCell,
            cellStyle: baseCellStyle
        )
        self.updateContent()
    }

    open override var canCalculateHeightInBackground: Bool {
        return true
    }

    open override class func registerCells(_ collectionView: UICollectionView) {
        // Cell registration is happening lazily, right before the moment when a cell is dequeued.
    }

    open override var isItemUpdateSupported: Bool {
        return true
    }

    open override func update(with chatItem: ChatItemProtocol) {
        let oldMessageModel = self.messageModel
        super.update(with: chatItem)

        let isContentChanged = !oldMessageModel.hasSameContent(as: chatItem)
        guard !isContentChanged else {
            let allContentPresentersSupportUpdate = self.contentPresenters.reduce(true) {
                $0 && $1.supportsMessageUpdating
            }
            if !self.contentPresenters.isEmpty && allContentPresentersSupportUpdate {
                self.updateExistingContentPresenters(with: chatItem)
            } else {
                self.updateContent()
            }
            return
        }

        let isMessageUidChanged = oldMessageModel.uid != chatItem.uid
        guard !isMessageUidChanged else {
            self.updateExistingContentPresenters(with: chatItem)
            return
        }
    }

    open func updateContent() {
        self.contentFactories = self.initialContentFactories.filter { $0.canCreateMessageContent(forModel: self.messageModel) }

        self.contentPresenters = self.contentFactories.compactMap {
            var presenter = $0.createContentPresenter(forModel: self.messageModel)
            presenter.delegate = self
            return presenter
        }

        self.menuPresenter = self.contentFactories.lazy.compactMap { $0.createMenuPresenter(forModel: self.messageModel) }.first
    }

    open func updateExistingContentPresenters(with newMessage: Any) {
        self.contentPresenters.forEach {
            $0.updateMessage(newMessage)
        }
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

            if bubbleView.decoratedContentViews == nil {
                bubbleView.accessibilityIdentifier = sSelf.accessibilityIdentifier
                bubbleView.decoratedContentViews = zip(sSelf.contentFactories, sSelf.contentPresenters).map { factory, presenter in
                    return CompoundBubbleView.DecoratedView(view: factory.createContentView(), showBorder: presenter.showBorder)
                }
            }

            bubbleView.viewModel = sSelf.messageViewModel
            bubbleView.layoutProvider = sSelf.layoutProvider
            bubbleView.style = sSelf.compoundCellStyle

            /*
             There is a current algorithm of binding (and unbinding, as well) compoundCell's views to their presenters:
             1. Already bound presenters are unbound from views: each presenter is responsible for cleaning up its view.
             2. All the view references are destroyed to break a connection between compoundCell's views and their previous presenters. These presenters will lose the opportunity to affect compoundCell's views.
             3. CompoundCell's views bound with a current compound message presenters.
             */

            sSelf.contentPresenters.forEach { $0.unbindFromView() }
            compoundCell.viewReferences = zip(sSelf.contentPresenters, bubbleView.decoratedContentViews!.map({ $0.view })).map { presenter, view in
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

    // TODO: Let's think how to improve it.
    // We have to create a new configuration on each access to a layout provider
    // because configuration may change at any time. Still, we want to keep
    // reference to the last configuration to have ability to clean cache
    // from obsolete and unused objects.
    private var lastUsedConfiguration: CompoundBubbleLayoutProvider.Configuration?
    private var layoutProvider: CompoundBubbleLayoutProvider {
        let configuration: CompoundBubbleLayoutProvider.Configuration = {
            let contentLayoutProviders = self.contentFactories.map { $0.createLayoutProvider(forModel: self.messageModel) }
            let viewModel = self.messageViewModel
            let tailWidth = self.compoundCellStyle.tailWidth(forViewModel: viewModel)
            return CompoundBubbleLayoutProvider.Configuration(
                layoutProviders: contentLayoutProviders,
                tailWidth: tailWidth,
                isIncoming: viewModel.isIncoming,
                dimensions: self.compoundCellDimensions
            )
        }()
        defer {
            if self.lastUsedConfiguration != configuration {
                self.cleanLayoutCache(for: self.lastUsedConfiguration)
                self.lastUsedConfiguration = configuration
            }
        }
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

    // MARK: - MessageContentPresenterDelegate

    public func presenterDidInvalidateLayout(_ presenter: MessageContentPresenterProtocol) {
        self.cleanLayoutCache(for: self.lastUsedConfiguration)
    }

    private func cleanLayoutCache(for configuration: CompoundBubbleLayoutProvider.Configuration?) {
        guard let configuration = configuration else { return }
        self.cache[configuration] = nil
    }
}
