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
import ChattoAdditions

class DemoChatViewController: UIViewController {
    let baseChatViewController: BaseChatViewController
    let dataSource: DemoChatDataSource
    let keyboardUpdatesHandler: KeyboardUpdatesHandlerDelegate
    let messagesSelector = BaseMessagesSelector()

    private lazy var chatPanGestureRecogniserHandler: ChatPanGestureRecogniserHandler = {
        var panGestureHandlerConfig = CellPanGestureHandlerConfig.defaultConfig()
        panGestureHandlerConfig.allowReplyRevealing = true

        return ChatPanGestureRecogniserHandler(
            panGestureHandlerConfig: panGestureHandlerConfig,
            replyActionHandler: DemoReplyActionHandler(presentingViewController: self),
            replyFeedbackGenerator: ReplyFeedbackGenerator()
        )
    }()

    var messageSender: DemoChatMessageSender

    init(dataSource: DemoChatDataSource,
         shouldUseAlternativePresenter: Bool = false,
         shouldUseNewMessageArchitecture: Bool = false) {
        self.dataSource = dataSource
        self.messageSender = dataSource.messageSender

        let adapterConfig = ChatMessageCollectionAdapter.Configuration.default
        let presentersBuilder: [ChatItemType: [ChatItemPresenterBuilderProtocol]]
        if shouldUseNewMessageArchitecture {
            presentersBuilder = Self.makeNewPresenterBuilders()
        } else {
            presentersBuilder = Self.makeOldPresenterBuilders(messageSender: self.messageSender, messageSelector: self.messagesSelector)
        }

        let fallbackItemPresenterFactory: ChatItemPresenterFactoryProtocol
        if shouldUseNewMessageArchitecture {
            fallbackItemPresenterFactory = Self.makeNewFallbackItemPresenterFactory()
        } else {
            fallbackItemPresenterFactory = DummyItemPresenterFactory()
        }

        let chatItemPresenterFactory = ChatItemPresenterFactory(
            presenterBuildersByType: presentersBuilder,
            fallbackItemPresenterFactory: fallbackItemPresenterFactory
        )
        let chatItemsDecorator = DemoChatItemsDecorator(messagesSelector: self.messagesSelector)
        let chatMessageCollectionAdapter = ChatMessageCollectionAdapter(
            chatItemsDecorator: chatItemsDecorator,
            chatItemPresenterFactory: chatItemPresenterFactory,
            chatMessagesViewModel: dataSource,
            configuration: adapterConfig,
            referenceIndexPathRestoreProvider: ReferenceIndexPathRestoreProviderFactory.makeDefault(),
            updateQueue: SerialTaskQueue()
        )
        let layout = ChatCollectionViewLayout()
        layout.layoutModelProvider = chatMessageCollectionAdapter
        let messagesViewController = ChatMessagesViewController(
            config: .default,
            layout: layout,
            messagesAdapter: chatMessageCollectionAdapter,
            style: .default,
            viewModel: dataSource
        )
        chatMessageCollectionAdapter.delegate = messagesViewController
        let chatInputItems = Self.createChatInputItems(
            dataSource: dataSource,
            shouldUseAlternativePresenter: shouldUseAlternativePresenter
        )
        let chatInputContainer = Self.makeChatInputPresenter(
            chatInputItems: chatInputItems,
            shouldUseAlternativePresenter: shouldUseAlternativePresenter
        )
        let keyboardTracker = KeyboardTracker(notificationCenter: .default)
        let keyboardHandler = KeyboardUpdatesHandler(keyboardTracker: keyboardTracker)

        self.keyboardUpdatesHandler = chatInputContainer.keyboardHandlerDelegate

        self.baseChatViewController = BaseChatViewController(
            inputBarPresenter: chatInputContainer.presenter,
            messagesViewController: messagesViewController,
            collectionViewEventsHandlers: [chatInputContainer.collectionHandler].compactMap { $0 },
            keyboardUpdatesHandler: keyboardHandler,
            viewEventsHandlers: [chatInputContainer.viewPresentationHandler].compactMap { $0 }
        )
        super.init(nibName: nil, bundle: nil)

        chatInputItems.forEach { ($0 as? PresenterChatInputItemProtocol)?.presentingController = self }
        messagesViewController.delegate = self.baseChatViewController
        chatInputContainer.presenter.viewController = self.baseChatViewController

        keyboardHandler.keyboardInputAdjustableViewController = self.baseChatViewController

        keyboardHandler.keyboardInfo.observe(self) { [weak keyboardHandlerDelegate = chatInputContainer.keyboardHandlerDelegate] _, keyboardInfo in
            keyboardHandlerDelegate?.didAdjustBottomMargin(to: keyboardInfo.bottomMargin, state: keyboardInfo.state)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupChatViewController()

        self.title = "Chat"
        self.messagesSelector.delegate = self
        self.chatPanGestureRecogniserHandler.chatViewController = self.baseChatViewController
    }

    func refreshContent() {
        self.baseChatViewController.refreshContent()
    }

    public func scrollToItem(withId id: String, position: UICollectionView.ScrollPosition, animated: Bool) {
        self.baseChatViewController.scrollToItem(withId: id, position: position, animated: animated)
    }

    private func setupChatViewController() {
        self.addChild(self.baseChatViewController)
        defer { self.baseChatViewController.didMove(toParent: self) }

        self.view.addSubview(self.baseChatViewController.view)
        self.baseChatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: self.baseChatViewController.view.topAnchor),
            self.view.trailingAnchor.constraint(equalTo: self.baseChatViewController.view.trailingAnchor),
            self.view.bottomAnchor.constraint(equalTo: self.baseChatViewController.view.bottomAnchor),
            self.view.leadingAnchor.constraint(equalTo: self.baseChatViewController.view.leadingAnchor),
        ])
    }

    private static func makeChatInputPresenter(chatInputItems: [ChatInputItemProtocol],
                                               shouldUseAlternativePresenter: Bool) -> ChatInputContainer {
        let chatInputView = ChatInputBar.loadNib()
        chatInputView.maxCharactersCount = 1000

        var appearance = ChatInputBarAppearance()
        appearance.sendButtonAppearance.title = NSLocalizedString("Send", comment: "")
        appearance.textInputAppearance.placeholderText = NSLocalizedString("Type a message", comment: "")

        guard shouldUseAlternativePresenter else {
            let presenter = BasicChatInputBarPresenter(
                chatInputBar: chatInputView,
                chatInputItems: chatInputItems,
                chatInputBarAppearance: appearance
            )
            let keyboardHandler = DefaultKeyboardHandler(presenter: presenter)

            return (presenter, keyboardHandler, nil, nil)
        }

        let presenter = ExpandableChatInputBarPresenter(
                chatInputBar: chatInputView,
                chatInputItems: chatInputItems,
                chatInputBarAppearance: appearance
            )

        return (presenter, presenter, presenter, nil)
    }

    private static func createChatInputItems(dataSource: DemoChatDataSource,
                                             shouldUseAlternativePresenter: Bool) -> [ChatInputItemProtocol] {
        var items = [ChatInputItemProtocol]()
        items.append(self.createTextInputItem(dataSource: dataSource))
        items.append(self.createPhotoInputItem(dataSource: dataSource))
        if shouldUseAlternativePresenter {
            items.append(self.customInputItem(dataSource: dataSource))
        }
        return items
    }

    class func createTextMessageViewModelBuilder() -> DemoTextMessageViewModelBuilder {
        return DemoTextMessageViewModelBuilder()
    }

    private static func makeOldPresenterBuilders(messageSender: DemoChatMessageSender,
                                          messageSelector: BaseMessagesSelector) -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        let textMessagePresenter = TextMessagePresenterBuilder(
            viewModelBuilder: Self.createTextMessageViewModelBuilder(),
            interactionHandler: DemoMessageInteractionHandler(messageSender: messageSender, messagesSelector: messageSelector)
        )
        textMessagePresenter.baseMessageStyle = BaseMessageCollectionViewCellAvatarStyle()

        let photoMessagePresenter = PhotoMessagePresenterBuilder(
            viewModelBuilder: DemoPhotoMessageViewModelBuilder(),
            interactionHandler: DemoMessageInteractionHandler(messageSender: messageSender, messagesSelector: messageSelector)
        )
        photoMessagePresenter.baseCellStyle = BaseMessageCollectionViewCellAvatarStyle()

        let compoundPresenterBuilder = CompoundMessagePresenterBuilder(
            viewModelBuilder: DemoCompoundMessageViewModelBuilder(),
            interactionHandler: DemoMessageInteractionHandler(messageSender: messageSender, messagesSelector: messageSelector),
            accessibilityIdentifier: nil,
            contentFactories: [
                .init(DemoTextMessageContentFactory()),
                .init(DemoImageMessageContentFactory()),
                .init(DemoDateMessageContentFactory())
            ],
            decorationFactories: [
                .init(DemoEmojiDecorationViewFactory())
            ],
            baseCellStyle: BaseMessageCollectionViewCellAvatarStyle()
        )

        let compoundPresenterBuilder2 = CompoundMessagePresenterBuilder(
            viewModelBuilder: DemoCompoundMessageViewModelBuilder(),
            interactionHandler: DemoMessageInteractionHandler(messageSender: messageSender, messagesSelector: messageSelector),
            accessibilityIdentifier: nil,
            contentFactories: [
                .init(DemoTextMessageContentFactory()),
                .init(DemoImageMessageContentFactory()),
                .init(DemoInvisibleSplitterFactory()),
                .init(DemoText2MessageContentFactory())
            ],
            decorationFactories: [
                .init(DemoEmojiDecorationViewFactory())
            ],
            baseCellStyle: BaseMessageCollectionViewCellAvatarStyle()
        )

        return [
            DemoTextMessageModel.chatItemType: [textMessagePresenter],
            DemoPhotoMessageModel.chatItemType: [photoMessagePresenter],
            SendingStatusModel.chatItemType: [SendingStatusPresenterBuilder()],
            TimeSeparatorModel.chatItemType: [TimeSeparatorPresenterBuilder()],
            ChatItemType.compoundItemType: [compoundPresenterBuilder],
            ChatItemType.compoundItemType2: [compoundPresenterBuilder2]
        ]
    }

    private static func makeNewFallbackItemPresenterFactory() -> ChatItemPresenterFactoryProtocol {

        struct DummyItemPresenterFactory: ChatItemPresenterFactoryProtocol {

            typealias PresenterBuilder = ChatItemPresenterBuilderProtocol & ChatItemPresenterBuilderCollectionViewConfigurable

            let presenterBuilder: PresenterBuilder

            func createChatItemPresenter(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
                guard self.presenterBuilder.canHandleChatItem(chatItem) else { fatalError() }
                return self.presenterBuilder.createPresenterWithChatItem(chatItem)
            }

            func configure(withCollectionView collectionView: UICollectionView) {
                self.presenterBuilder.configure(with: collectionView)
            }
        }

        var factory = FactoryAggregate<ChatItemProtocol>()

        let dummy = factory.register(
            viewFactory: DummyContentViewFactory(),
            viewModelFactory: DummyViewModelFactory(),
            layoutProviderFactory: DummyLayoutProviderFactory()
        )

        var binder = Binder()
        binder.registerBinding(for: dummy)

        let assembler = ViewAssembler(root: dummy)
        var layoutAssembler = LayoutAssembler(rootKey: dummy)

        // TODO: Remove #746
        layoutAssembler.populateSizeProviders(for: dummy)

        let presenterBuilder = ChatItemPresenterBuilder(
            binder: binder,
            assembler: assembler,
            layoutAssembler: layoutAssembler,
            factory: factory
        )
        return DummyItemPresenterFactory(presenterBuilder: presenterBuilder)
    }

    private static func makeNewPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        return [
            DemoTextMessageModel.chatItemType: [self.makeNewTextMessagePresenterBuilder()],
            ChatItemType.compoundItemType: [self.makeNewCompoundExamplePresenterBuilder()],
            DemoPhotoMessageModel.chatItemType: [self.makeNewImagePresenterBuilder()]
        ]
    }

    private static func makeNewImagePresenterBuilder() -> ChatItemPresenterBuilderProtocol {

        var factory = FactoryAggregate<DemoPhotoMessageModel>()

        let image = factory.register(
            viewFactory: AsyncImageViewFactory(),
            viewModelFactory: AsyncImageViewModelFactory(),
            layoutProviderFactory: AsyncImageLayoutProviderFactory()
        )

        let bubble = factory.register(
            viewFactory: MessageBubbleViewFactory(),
            viewModelFactory: MessageBubbleViewModelFactory(),
            layoutProviderFactory: MessageBubbleLayoutProviderFactory(configuration: .init(percentageToOccupy: 0.4))
        )

        var binder = Binder()

        binder.registerBinding(for: bubble)

        binder.registerBlockBinding(for: image) { view, viewModel in
            view.viewModel = viewModel
        }

        var assembler = ViewAssembler(root: bubble)
        assembler.register(child: image, parent: bubble)

        var layoutAssembler = LayoutAssembler(rootKey: bubble)
        layoutAssembler.register(child: image, for: bubble)

        // TODO: Remove #746
        layoutAssembler.populateSizeProviders(for: bubble)
        layoutAssembler.populateSizeProviders(for: image)

        return ChatItemPresenterBuilder(
            binder: binder,
            assembler: assembler,
            layoutAssembler: layoutAssembler,
            factory: factory
        )
    }

    private static func makeNewCompoundExamplePresenterBuilder() -> ChatItemPresenterBuilderProtocol {
        var factory = FactoryAggregate<DemoCompoundMessageModel>()

        let bubble = factory.register(
            viewFactory: MessageBubbleViewFactory(),
            viewModelFactory: MessageBubbleViewModelFactory(),
            layoutProviderFactory: MessageBubbleLayoutProviderFactory(configuration: .init(percentageToOccupy: 0.8))
        )

        let compound = factory.register(
            viewFactory: CompoundViewFactory(),
            viewModelFactory: CompoundViewModelFactory(),
            layoutProviderFactory: CompoundLayoutProviderFactory()
        )

        let first = factory.register(
            viewFactory: DummyContentViewFactory(),
            viewModelFactory: StaticDummyViewModelFactory(text: "first"),
            layoutProviderFactory: DummyLayoutProviderFactory()
        )

        let second = factory.register(
            viewFactory: DummyContentViewFactory(),
            viewModelFactory: StaticDummyViewModelFactory(text: "second"),
            layoutProviderFactory: DummyLayoutProviderFactory()
        )

        var binder = Binder()

        binder.registerBinding(for: bubble)
        binder.registerNoopBinding(for: compound)
        binder.registerBinding(for: first)
        binder.registerBinding(for: second)

        var assembler = ViewAssembler(root: bubble)
        assembler.register(children: [.init(first), .init(second)], parent: compound)
        assembler.register(child: compound, parent: bubble)

        var layoutAssembler = LayoutAssembler(rootKey: bubble)
        layoutAssembler.register(child: compound, for: bubble)
        layoutAssembler.register(children: [.init(first), .init(second)], for: compound)

        // TODO: Remove #746
        layoutAssembler.populateSizeProviders(for: first)
        layoutAssembler.populateSizeProviders(for: second)
        layoutAssembler.populateSizeProviders(for: compound)
        layoutAssembler.populateSizeProviders(for: bubble)

        return ChatItemPresenterBuilder(
            binder: binder,
            assembler: assembler,
            layoutAssembler: layoutAssembler,
            factory: factory
        )
    }

    private static func makeNewTextMessagePresenterBuilder() -> ChatItemPresenterBuilderProtocol {
        var factory = FactoryAggregate<DemoTextMessageModel>()

        let bubble = factory.register(
            viewFactory: MessageBubbleViewFactory(),
            viewModelFactory: MessageBubbleViewModelFactory(),
            layoutProviderFactory: MessageBubbleLayoutProviderFactory(configuration: .init(percentageToOccupy: 0.6))
        )
        let dummy = factory.register(
            viewFactory: DummyContentViewFactory(),
            viewModelFactory: DummyViewModelFactory(),
            layoutProviderFactory: DummyLayoutProviderFactory()
        )

        var binder = Binder()
        binder.registerBinding(for: dummy)
        binder.registerBinding(for: bubble)

        var assembler = ViewAssembler(root: bubble)
        assembler.register(child: dummy, parent: bubble)

        var layoutAssembler = LayoutAssembler(rootKey: bubble)
        layoutAssembler.register(child: dummy, for: bubble)

        // TODO: Remove #746
        layoutAssembler.populateSizeProviders(for: dummy)
        layoutAssembler.populateSizeProviders(for: bubble)

        return ChatItemPresenterBuilder(
            binder: binder,
            assembler: assembler,
            layoutAssembler: layoutAssembler,
            factory: factory
        )
    }

    private static func createTextInputItem(dataSource: DemoChatDataSource) -> TextChatInputItem {
        let item = TextChatInputItem()
        item.textInputHandler = { [weak dataSource] text in
            dataSource?.addTextMessage(text)
        }
        return item
    }

    private static func createPhotoInputItem(dataSource: DemoChatDataSource) -> PhotosChatInputItem {
        let item = PhotosChatInputItem()
        item.photoInputHandler = { [weak dataSource] image, _ in
            dataSource?.addPhotoMessage(image)
        }
        return item
    }

    private static func customInputItem(dataSource: DemoChatDataSource) -> ContentAwareInputItem {
        let item = ContentAwareInputItem()
        item.textInputHandler = { [weak dataSource] text in
            dataSource?.addTextMessage(text)
        }
        return item
    }
}

extension DemoChatViewController: MessagesSelectorDelegate {
    func messagesSelector(_ messagesSelector: MessagesSelectorProtocol, didSelectMessage: MessageModelProtocol) {
        self.baseChatViewController.refreshContent()
    }

    func messagesSelector(_ messagesSelector: MessagesSelectorProtocol, didDeselectMessage: MessageModelProtocol) {
        self.baseChatViewController.refreshContent()
    }
}

private protocol PresenterChatInputItemProtocol: AnyObject {
    var presentingController: UIViewController? { get set }
}

extension PhotosChatInputItem: PresenterChatInputItemProtocol {}

typealias ChatInputContainer = (
    presenter: BaseChatInputBarPresenterProtocol,
    keyboardHandlerDelegate: KeyboardUpdatesHandlerDelegate,
    collectionHandler: CollectionViewEventsHandling?,
    viewPresentationHandler: ViewPresentationEventsHandling?
)

private final class DefaultKeyboardHandler: KeyboardUpdatesHandlerDelegate {

    weak var presenter: BaseChatInputBarPresenterProtocol?

    init(presenter: BaseChatInputBarPresenterProtocol) {
        self.presenter = presenter
    }

    func didAdjustBottomMargin(to margin: CGFloat, state: KeyboardState) {
        guard let presenter = self.presenter?.viewController else { return }

        presenter.changeInputContentBottomMarginWithDefaultAnimation(
            to: margin,
            completion: nil
        )
    }
}
