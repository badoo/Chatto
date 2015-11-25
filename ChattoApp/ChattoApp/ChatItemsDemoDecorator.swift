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

final class ChatItemsDemoDecorator: ChatItemsDecoratorProtocol {
    struct Constants {
        static let shortSeparation: CGFloat = 3
        static let normalSeparation: CGFloat = 10
        static let timeIntervalThresholdToIncreaseSeparation: NSTimeInterval = 120
    }

    func decorateItems(chatItems: [ChatItemProtocol]) -> [DecoratedChatItem] {
        var decoratedChatItems = [DecoratedChatItem]()

        for (index, chatItem) in chatItems.enumerate() {
            let next: ChatItemProtocol? = (index + 1 < chatItems.count) ? chatItems[index + 1] : nil

            let bottomMargin = self.separationAfterItem(chatItem, next: next)
            var showsTail = false
            var additionalItems =  [DecoratedChatItem]()

            if let currentMessage = chatItem as? MessageModelProtocol {
                if let nextMessage = next as? MessageModelProtocol {
                    showsTail = currentMessage.senderId != nextMessage.senderId
                } else {
                    showsTail = true
                }

                if self.showsStatusForMessage(currentMessage) {
                    additionalItems.append(
                        DecoratedChatItem(
                            chatItem: SendingStatusModel(uid: "\(currentMessage.uid)-decoration-status", status: currentMessage.status),
                            decorationAttributes: nil)
                    )
                }
            }

            decoratedChatItems.append(DecoratedChatItem(
                chatItem: chatItem,
                decorationAttributes: ChatItemDecorationAttributes(bottomMargin: bottomMargin, showsTail: showsTail))
            )
            decoratedChatItems.appendContentsOf(additionalItems)
        }

        return decoratedChatItems
    }

    func separationAfterItem(current: ChatItemProtocol?, next: ChatItemProtocol?) -> CGFloat {
        guard let nexItem = next else { return 0 }
        guard let currentMessage = current as? MessageModelProtocol else { return Constants.normalSeparation }
        guard let nextMessage = nexItem as? MessageModelProtocol else { return Constants.normalSeparation }

        if self.showsStatusForMessage(currentMessage) {
            return 0
        } else if currentMessage.senderId != nextMessage.senderId {
            return Constants.normalSeparation
        } else if nextMessage.date.timeIntervalSinceDate(currentMessage.date) > Constants.timeIntervalThresholdToIncreaseSeparation {
            return Constants.normalSeparation
        } else {
            return Constants.shortSeparation
        }
    }

    func showsStatusForMessage(message: MessageModelProtocol) -> Bool {
        return message.status == .Failed || message.status == .Sending
    }
}
