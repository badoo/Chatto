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

class PhotosInputViewItemSizeCalculatorTests: XCTestCase {
    private var calculator: PhotosInputViewItemSizeCalculator!
    override func setUp() {
        super.setUp()
        self.calculator = PhotosInputViewItemSizeCalculator()
    }

    func testThat_WhenWidthIsZero_ItemSizeIsZero() {
        let size = self.calculator.itemSizeForWidth(0, atIndex: 0)
        XCTAssertEqual(size, CGSize.zero)
    }

    func testThat_WhenWidthIsLessThenInterItemSpace_ItemSizeIsZero() {
        self.calculator.interitemSpace = 1
        self.calculator.itemsPerRow = 3
        let size = self.calculator.itemSizeForWidth(1, atIndex: 0)
        XCTAssertEqual(size, CGSize.zero)
    }

    func testThat_WhenWidthIsEqualInteritemSpace_ItemSizeIsZero() {
        self.calculator.interitemSpace = 1
        self.calculator.itemsPerRow = 3
        let size = self.calculator.itemSizeForWidth(2, atIndex: 0)
        XCTAssertEqual(size, CGSize.zero)
    }

    func testThat_WhenWidthIsEnoughToHaveIntegerItemSizes_AllItemsHaveSameSize() {
        self.calculator.interitemSpace = 1
        self.calculator.itemsPerRow = 3
        XCTAssertEqual(self.calculator.itemSizeForWidth(5, atIndex: 0), CGSize(width: 1, height: 1))
        XCTAssertEqual(self.calculator.itemSizeForWidth(5, atIndex: 1), CGSize(width: 1, height: 1))
        XCTAssertEqual(self.calculator.itemSizeForWidth(5, atIndex: 2), CGSize(width: 1, height: 1))
    }

    func testThat_WhenWidthIsNotEnoughToHaveIntegerItemSizes_ItemsHaveDifferentSizes() {
        self.calculator.interitemSpace = 1
        self.calculator.itemsPerRow = 3

        XCTAssertEqual(self.calculator.itemSizeForWidth(6, atIndex: 0), CGSize(width: 2, height: 1))
        XCTAssertEqual(self.calculator.itemSizeForWidth(6, atIndex: 1), CGSize(width: 1, height: 1))
        XCTAssertEqual(self.calculator.itemSizeForWidth(6, atIndex: 2), CGSize(width: 1, height: 1))

        XCTAssertEqual(self.calculator.itemSizeForWidth(7, atIndex: 0), CGSize(width: 2, height: 1))
        XCTAssertEqual(self.calculator.itemSizeForWidth(7, atIndex: 1), CGSize(width: 2, height: 1))
        XCTAssertEqual(self.calculator.itemSizeForWidth(7, atIndex: 2), CGSize(width: 1, height: 1))
    }
}
