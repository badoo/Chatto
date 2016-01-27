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

class DemoChatViewController: ChatViewController {

    var messageSender: FakeMessageSender!
    var dataSource: FakeDataSource! {
        didSet {
            self.chatDataSource = self.dataSource
        }
    }

    lazy private var baseMessageHandler: BaseMessageHandler = {
        return BaseMessageHandler(messageSender: self.messageSender)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "bubble-incoming-tail-border", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)?.bma_tintWithColor(UIColor.blueColor())
        super.chatItemsDecorator = ChatItemsDemoDecorator()
        let addIncomingMessageButton = UIBarButtonItem(image: image, style: .Plain, target: self, action: "addRandomIncomingMessage")
        self.navigationItem.rightBarButtonItem = addIncomingMessageButton
    }

    @objc
    private func addRandomIncomingMessage() {
        self.dataSource.addRandomIncomingMessage()
    }

    var chatInputPresenter: ChatInputBarPresenter!
    override func createChatInputView() -> UIView {
        let chatInputView = ChatInputBar.loadNib()
        self.configureChatInputBar(chatInputView)
        self.chatInputPresenter = ChatInputBarPresenter(chatInputView: chatInputView, chatInputItems: self.createChatInputItems())
        return chatInputView
    }

    func configureChatInputBar(chatInputBar: ChatInputBar) {
        var appearance = ChatInputBarAppearance()
        appearance.sendButtonTitle = NSLocalizedString("Send", comment: "")
        appearance.textPlaceholder = NSLocalizedString("Type a message", comment: "")
        chatInputBar.setAppearance(appearance)
    }

    override func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        return [
            TextMessageModel.chatItemType: [
                TextMessagePresenterBuilder(
                    viewModelBuilder: TextMessageViewModelDefaultBuilder(),
                    interactionHandler: TextMessageHandler(baseHandler: self.baseMessageHandler)
                )
            ],
            PhotoMessageModel.chatItemType: [
                PhotoMessagePresenterBuilder(
                    viewModelBuilder: FakePhotoMessageViewModelBuilder(),
                    interactionHandler: PhotoMessageHandler(baseHandler: self.baseMessageHandler)
                )
            ],
            SendingStatusModel.chatItemType: [SendingStatusPresenterBuilder()]
        ]
    }

    func createChatInputItems() -> [ChatInputItemProtocol] {
        var items = [ChatInputItemProtocol]()
        items.append(self.createTextInputItem())
        items.append(self.createPhotoInputItem())
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
        item.photoInputHandler = { [weak self] image in
            self?.dataSource.addPhotoMessage(image)
        }
        return item
    }
}
