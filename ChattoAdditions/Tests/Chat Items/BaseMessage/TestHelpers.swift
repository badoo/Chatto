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

import ChattoAdditions
import Foundation

struct TestHelpers {

    static func makeMessage(withId messageId: String, date: Date = Date()) -> MessageModel {
        return MessageModel(uid: messageId, senderId: "123", type: "text", isIncoming: true, date: date, status: .success)
    }

    static func makeDefaultMessageContentPresenter(with message: MessageModel, onMessageUpdate: ((_ newMessage: MessageModel) -> Void)?) -> DefaultMessageContentPresenter<MessageModel, UIView> {
        return DefaultMessageContentPresenter<MessageModel, UIView>(
            message: message,
            showBorder: true,
            onBinding: nil,
            onUnbinding: nil,
            onContentWillBeShown: nil,
            onContentWasHidden: nil,
            onContentWasTapped_deprecated: nil,
            onMessageUpdate: onMessageUpdate
        )
    }

    static func makeFakeViewModelBuilder() -> FakeViewModelBuilder {
        let builder = FakeViewModelBuilder()
        builder.stubbedCreateViewModelResult = MessageViewModel(
            dateFormatter: DateFormatter(),
            messageModel: self.makeMessage(withId: "default_message"),
            avatarImage: nil,
            decorationAttributes: BaseMessageDecorationAttributes()
        )
        return builder
    }

    @available(iOS 11, *)
    static func makeTestableCompoundMessagePresenter(with message: MessageModel,
                                                     viewModelBuilder: FakeViewModelBuilder? = nil) -> TestableCompoundMessagePresenter {
        return TestableCompoundMessagePresenter(
            messageModel: message,
            viewModelBuilder: viewModelBuilder ?? self.makeFakeViewModelBuilder()
        )
    }
}
