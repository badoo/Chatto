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
@testable import ChattoAdditions

class TextChatInputItemTests: XCTestCase {
    private var inputItem: TextChatInputItem!
    override func setUp() {
        super.setUp()
        self.inputItem = TextChatInputItem()
    }

    func testThat_SendButtonEnabledForTextInputItem() {
        XCTAssertTrue(self.inputItem.showsSendButton)
    }

    func testThat_InputViewIsEmpty() {
        XCTAssertNil(self.inputItem.inputView)
    }

    func testThat_GivenItemHasTextInputHandler_WhenInputIsString_ItemHandlesInput() {
        var handled = false
        self.inputItem.textInputHandler = { text in
            handled = true
        }
        self.inputItem.handleInput("text" as AnyObject)
        XCTAssertTrue(handled)
    }

    func testThat_GivenItemHasTextInputHandler_WhenInputIsNotString_ItemDoesntHandleInput() {
        var handled = false
        self.inputItem.textInputHandler = { text in
            handled = true
        }
        self.inputItem.handleInput(5 as AnyObject)
        XCTAssertFalse(handled)
    }
}
