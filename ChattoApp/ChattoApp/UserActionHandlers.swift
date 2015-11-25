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
import Chatto
import ChattoAdditions

class TextMessageHandler: BaseMessageInteractionHandlerProtocol {
    private let baseHandler: BaseMessageHandler
    init (baseHandler: BaseMessageHandler) {
        self.baseHandler = baseHandler
    }
    func userDidTapOnFailIcon(viewModel viewModel: TextMessageViewModel) {
        self.baseHandler.userDidTapOnFailIcon(viewModel: viewModel)
    }

    func userDidTapOnBubble(viewModel viewModel: TextMessageViewModel) {
        self.baseHandler.userDidTapOnBubble(viewModel: viewModel)
    }

    func userDidLongPressOnBubble(viewModel viewModel: TextMessageViewModel) {
        self.baseHandler.userDidLongPressOnBubble(viewModel: viewModel)
    }
}

class PhotoMessageHandler: BaseMessageInteractionHandlerProtocol {
    private let baseHandler: BaseMessageHandler
    init (baseHandler: BaseMessageHandler) {
        self.baseHandler = baseHandler
    }

    func userDidTapOnFailIcon(viewModel viewModel: PhotoMessageViewModel) {
        self.baseHandler.userDidTapOnFailIcon(viewModel: viewModel)
    }

    func userDidTapOnBubble(viewModel viewModel: PhotoMessageViewModel) {
        self.baseHandler.userDidTapOnBubble(viewModel: viewModel)
    }

    func userDidLongPressOnBubble(viewModel viewModel: PhotoMessageViewModel) {
        self.baseHandler.userDidLongPressOnBubble(viewModel: viewModel)
    }
}

class BaseMessageHandler {

    private let messageSender: FakeMessageSender
    init (messageSender: FakeMessageSender) {
        self.messageSender = messageSender
    }
    func userDidTapOnFailIcon(viewModel viewModel: MessageViewModelProtocol) {
        NSLog("userDidTapOnFailIcon")
        self.messageSender.sendMessage(viewModel.messageModel)
    }

    func userDidTapOnBubble(viewModel viewModel: MessageViewModelProtocol) {
        NSLog("userDidTapOnBubble")

    }

    func userDidLongPressOnBubble(viewModel viewModel: MessageViewModelProtocol) {
        NSLog("userDidLongPressOnBubble")
    }
}
