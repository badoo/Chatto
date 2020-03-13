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

public protocol PhotoMessageModelProtocol: DecoratedMessageModelProtocol, ContentEquatableChatItemProtocol {
    var image: UIImage { get }
    var imageSize: CGSize { get }
}

open class PhotoMessageModel<MessageModelT: MessageModelProtocol>: PhotoMessageModelProtocol {
    public var messageModel: MessageModelProtocol {
        return self._messageModel
    }
    public let _messageModel: MessageModelT // Can't make messageModel: MessageModelT: https://gist.github.com/diegosanchezr/5a66c7af862e1117b556
    public let image: UIImage
    public let imageSize: CGSize
    public init(messageModel: MessageModelT, imageSize: CGSize, image: UIImage) {
        self._messageModel = messageModel
        self.imageSize = imageSize
        self.image = image
    }
    public func hasSameContent(as anotherItem: ChatItemProtocol) -> Bool {
        guard let anotherMessageModel = anotherItem as? PhotoMessageModel else { return false }
        return self.image == anotherMessageModel.image
            && self.imageSize == anotherMessageModel.imageSize
    }
}
