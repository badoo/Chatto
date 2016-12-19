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

class ReadOnlyOrderedDictionaryTests: XCTestCase {

    var orderedDictionary: ReadOnlyOrderedDictionary<FakeChatItem>!
    override func setUp() {
        super.setUp()
        let items = [
            FakeChatItem(uid: "3", type: "type3"),
            FakeChatItem(uid: "1", type: "type1"),
            FakeChatItem(uid: "2", type: "type2")
        ]
        self.orderedDictionary = ReadOnlyOrderedDictionary<FakeChatItem>(items: items)
    }

    func testThat_MapsCorrectly() {
        XCTAssertEqual(self.orderedDictionary.map { $0.uid }, ["3", "1", "2"])
    }

    func testThat_NumberOfItemsIsCorrect() {
        XCTAssertEqual(self.orderedDictionary.count, 3)
    }

    func testThat_WhenSubscriptingByIndex_ThenReturnsCorrectValue() {
        XCTAssertEqual(self.orderedDictionary[1].uid, "1")
    }

    func testThat_WhenSubscriptingByExistingKey_ThenReturnsCorrectValue() {
        XCTAssertEqual(self.orderedDictionary["3"]?.type, "type3")
    }

    func testThat_WhenSubscriptingByNonExistingKey_ThenReturnsNil() {
        XCTAssertTrue(self.orderedDictionary["non-existing"] == nil)
    }
}
