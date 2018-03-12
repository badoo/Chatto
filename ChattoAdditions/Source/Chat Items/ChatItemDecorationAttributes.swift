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

public struct BaseMessageDecorationAttributes {
    public var canShowFailedIcon: Bool
    public let isShowingTail: Bool
    public let isShowingAvatar: Bool
    public let isShowingSelectionIndicator: Bool
    public let isSelected: Bool

    public init(canShowFailedIcon: Bool = true,
                isShowingTail: Bool = false,
                isShowingAvatar: Bool = false,
                isShowingSelectionIndicator: Bool = false,
                isSelected: Bool = false) {
        self.canShowFailedIcon = canShowFailedIcon
        self.isShowingTail = isShowingTail
        self.isShowingAvatar = isShowingAvatar
        self.isShowingSelectionIndicator = isShowingSelectionIndicator
        self.isSelected = isSelected
    }
}

public struct ChatItemDecorationAttributes: ChatItemDecorationAttributesProtocol {
    public let bottomMargin: CGFloat
    public let messageDecorationAttributes: BaseMessageDecorationAttributes

    public init(bottomMargin: CGFloat,
                messageDecorationAttributes: BaseMessageDecorationAttributes) {
        self.bottomMargin = bottomMargin
        self.messageDecorationAttributes = messageDecorationAttributes
    }

    @available(*, deprecated)
    public init(bottomMargin: CGFloat,
                canShowTail: Bool,
                canShowAvatar: Bool,
                canShowFailedIcon: Bool,
                isShowingSelectionIndicator: Bool = false,
                isSelected: Bool = false) {
        let messageDecorationAttributes = BaseMessageDecorationAttributes(
            canShowFailedIcon: canShowFailedIcon,
            isShowingTail: canShowTail,
            isShowingAvatar: canShowAvatar,
            isShowingSelectionIndicator: isShowingSelectionIndicator,
            isSelected: isSelected
        )
        self.init(bottomMargin: bottomMargin, messageDecorationAttributes: messageDecorationAttributes)
    }
}
