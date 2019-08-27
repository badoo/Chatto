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

@testable import ChattoAdditions
import XCTest

final class DefaultMessageContentPresenterTests: XCTestCase {

    func test_WhenPresenterIsUpdatedWithTheSameMessageWithAnotherId_ThenOnMessageUpdateClosureIsCalled_AndItIsCalledWithUpdatedMessage() {
        let message = TestHelpers.makeMessage(withId: "123")
        let sameMessageWithAnotherId = message.makeSameMessage(butAnotherId: "456")
        var isOnMessageUpdateCallsCount = 0
        var newMessageOnUpdate: MessageModel!
        let presenter = TestHelpers.makeDefaultMessageContentPresenter(with: message, onMessageUpdate: { newMessage in
            isOnMessageUpdateCallsCount += 1
            newMessageOnUpdate = newMessage
        })

        presenter.updateMessage(sameMessageWithAnotherId)

        XCTAssertEqual(1, isOnMessageUpdateCallsCount)
        XCTAssertEqual(sameMessageWithAnotherId.uid, newMessageOnUpdate!.uid)
    }
}
