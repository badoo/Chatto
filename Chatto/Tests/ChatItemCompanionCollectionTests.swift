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

import XCTest
@testable import Chatto

class ChatItemCompanionCollectionTests: XCTestCase {

    var companionCollection: ChatItemCompanionCollection!

    override func setUp() {
        super.setUp()
        let fakeChatItemPresenter = FakePresenter()
        let items = [
            ChatItemCompanion(uid: "3", chatItem: FakeChatItem(uid: "3", type: "type3"), presenter: fakeChatItemPresenter, decorationAttributes: nil),
            ChatItemCompanion(uid: "1", chatItem: FakeChatItem(uid: "1", type: "type1"), presenter: fakeChatItemPresenter, decorationAttributes: nil),
            ChatItemCompanion(uid: "2", chatItem: FakeChatItem(uid: "#2", type: "type2"), presenter: fakeChatItemPresenter, decorationAttributes: nil)
        ]
        self.companionCollection = ChatItemCompanionCollection(items: items)
    }

    func testThat_MapsCorrectly() {
        XCTAssertEqual(self.companionCollection.map { $0.uid }, ["3", "1", "2"])
    }

    func testThat_NumberOfItemsIsCorrect() {
        XCTAssertEqual(self.companionCollection.count, 3)
    }

    func testThat_WhenSubscriptingByIndex_ThenReturnsCorrectValue() {
        XCTAssertEqual(self.companionCollection[1].uid, "1")
    }

    func testThat_WhenSubscriptingByExistingKey_ThenReturnsCorrectValue() {
        XCTAssertEqual(self.companionCollection["3"]!.chatItem.type, "type3")
    }

    func testThat_WhenSubscriptingByNonExistingKey_ThenReturnsNil() {
        XCTAssertTrue(self.companionCollection["non-existing"] == nil)
    }

    func testThat_WhenSubscriptingByItemId_ThenReturnsTheSameItemAsSubscriptingByCompanionId() {
        XCTAssertEqual(self.companionCollection["2"]!.uid, "2")
        XCTAssertEqual(self.companionCollection["#2"]!.uid, "2")
    }
}
