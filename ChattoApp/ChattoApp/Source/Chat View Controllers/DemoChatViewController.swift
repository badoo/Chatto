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

class DemoChatViewController: BaseChatViewController {
    let dataSource: DemoChatDataSource
    let messagesSelector = BaseMessagesSelector()

    var messageSender: DemoChatMessageSender!
    var shouldUseAlternativePresenter: Bool = false

    init(dataSource: DemoChatDataSource) {
        self.dataSource = dataSource
        self.messageSender = dataSource.messageSender

        let adapterConfig = ChatMessageCollectionAdapter.Configuration.default
        let presentersBuilder = Self.createPresenterBuilders(messageSender: self.messageSender, messageSelector: self.messagesSelector)
        let chatItemPresenterFactory = ChatItemPresenterFactory(
            presenterBuildersByType: presentersBuilder
        )
        let chatItemsDecorator = DemoChatItemsDecorator(messagesSelector: self.messagesSelector)
        let chatMessageCollectionAdapter = ChatMessageCollectionAdapter(
            chatItemsDecorator: chatItemsDecorator,
            chatItemPresenterFactory: chatItemPresenterFactory,
            chatMessagesViewModel: dataSource,
            configuration: adapterConfig,
            updateQueue: SerialTaskQueue()
        )
        let layout = ChatCollectionViewLayout()
        layout.delegate = chatMessageCollectionAdapter
        let messagesViewController = ChatMessagesViewController(
            config: .default,
            layout: layout,
            messagesAdapter: chatMessageCollectionAdapter,
            presenterFactory: chatItemPresenterFactory,
            style: .default,
            viewModel: dataSource
        )

        super.init(messagesViewController: messagesViewController)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.cellPanGestureHandlerConfig.allowReplyRevealing = true

        self.title = "Chat"
        self.messagesSelector.delegate = self
        self.replyActionHandler = DemoReplyActionHandler(presentingViewController: self)
    }

    var chatInputPresenter: AnyObject!
    override func createChatInputView() -> UIView {
        let chatInputView = ChatInputBar.loadNib()
        var appearance = ChatInputBarAppearance()
        appearance.sendButtonAppearance.title = NSLocalizedString("Send", comment: "")
        appearance.textInputAppearance.placeholderText = NSLocalizedString("Type a message", comment: "")
        if self.shouldUseAlternativePresenter {
            let chatInputPresenter = ExpandableChatInputBarPresenter(
                inputPositionController: self,
                chatInputBar: chatInputView,
                chatInputItems: self.createChatInputItems(),
                chatInputBarAppearance: appearance)
            self.chatInputPresenter = chatInputPresenter
            self.keyboardEventsHandler = chatInputPresenter
            self.scrollViewEventsHandler = chatInputPresenter
        } else {
            self.chatInputPresenter = BasicChatInputBarPresenter(chatInputBar: chatInputView, chatInputItems: self.createChatInputItems(), chatInputBarAppearance: appearance)
        }
        chatInputView.maxCharactersCount = 1000
        return chatInputView
    }

    static private func createPresenterBuilders(messageSender: DemoChatMessageSender,
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

    class func createTextMessageViewModelBuilder() -> DemoTextMessageViewModelBuilder {
        return DemoTextMessageViewModelBuilder()
    }

    func createChatInputItems() -> [ChatInputItemProtocol] {
        var items = [ChatInputItemProtocol]()
        items.append(self.createTextInputItem())
        items.append(self.createPhotoInputItem())
        if self.shouldUseAlternativePresenter {
            items.append(self.customInputItem())
        }
        return items
    }

    private func createTextInputItem() -> TextChatInputItem {
        let item = TextChatInputItem()
        item.textInputHandler = { [weak self] text in
            self?.dataSource.addTextMessage(text)
        }
        return item
    }

    private func createPhotoInputItem() -> PhotosChatInputItem {
        let item = PhotosChatInputItem(presentingController: self)
        item.photoInputHandler = { [weak self] image, _ in
            self?.dataSource.addPhotoMessage(image)
        }
        return item
    }

    private func customInputItem() -> ContentAwareInputItem {
        let item = ContentAwareInputItem()
        item.textInputHandler = { [weak self] text in
            self?.dataSource.addTextMessage(text)
        }
        return item
    }
}

extension DemoChatViewController: MessagesSelectorDelegate {
    func messagesSelector(_ messagesSelector: MessagesSelectorProtocol, didSelectMessage: MessageModelProtocol) {
        self.refreshContent()
    }

    func messagesSelector(_ messagesSelector: MessagesSelectorProtocol, didDeselectMessage: MessageModelProtocol) {
        self.refreshContent()
    }
}
