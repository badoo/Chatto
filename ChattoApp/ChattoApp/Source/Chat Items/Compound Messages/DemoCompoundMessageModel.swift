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
import ChattoAdditions

final class DemoCompoundMessageModel: Equatable, DecoratedMessageModelProtocol, DemoMessageModelProtocol {

    // MARK: - Instantiation

    init(text: String, image: UIImage?, emoji: String?, messageModel: MessageModelProtocol) {
        self.text = text
        self.image = image
        self.emoji = emoji
        self.messageModel = messageModel
        self.status = messageModel.status
    }

    // MARK: - Public properties

    let text: String
    let image: UIImage?
    let emoji: String?

    // MARK: - DecoratedMessageModelProtocol

    let messageModel: MessageModelProtocol

    // MARK: - DemoMessageModelProtocol

    var status: MessageStatus

    // MARK: - Equatable

    static func == (lhs: DemoCompoundMessageModel, rhs: DemoCompoundMessageModel) -> Bool {
        return lhs.messageModel.uid == rhs.messageModel.uid
            && lhs.status == rhs.status
            && lhs.hasSameContent(as: rhs)
    }

    // MARK: - ChatItemProtocol

    func hasSameContent(as anotherItem: ChatItemProtocol) -> Bool {
        guard let anotherModel = anotherItem as? DemoCompoundMessageModel else { return false }
        return self.text == anotherModel.text
            && self.image == anotherModel.image
            && self.emoji == anotherModel.emoji
    }
}
