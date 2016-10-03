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

public enum MessageStatus {
    case failed
    case sending
    case success
}

public protocol MessageModelProtocol: ChatItemProtocol {
    var senderId: String { get }
    var isIncoming: Bool { get }
    var date: Date { get }
    var status: MessageStatus { get }
}

public protocol DecoratedMessageModelProtocol: MessageModelProtocol {
    var messageModel: MessageModelProtocol { get }
}

public extension DecoratedMessageModelProtocol {
    var uid: String {
        return self.messageModel.uid
    }

    var senderId: String {
        return self.messageModel.senderId
    }

    var type: String {
        return self.messageModel.type
    }

    var isIncoming: Bool {
        return self.messageModel.isIncoming
    }

    var date: Date {
        return self.messageModel.date
    }

    var status: MessageStatus {
        return self.messageModel.status
    }
}

open class MessageModel: MessageModelProtocol {
    open var uid: String
    open var senderId: String
    open var type: String
    open var isIncoming: Bool
    open var date: Date
    open var status: MessageStatus

    public init(uid: String, senderId: String, type: String, isIncoming: Bool, date: Date, status: MessageStatus) {
        self.uid = uid
        self.senderId = senderId
        self.type = type
        self.isIncoming = isIncoming
        self.date = date
        self.status = status
    }
}
