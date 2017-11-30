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
import ChattoAdditions

class CGSize_AdditionsTests: XCTestCase {
    func testThat_WhenInsetsArePositive_ItInsetsCorrectly() {
        let dx: CGFloat = 1
        let dy: CGFloat = 1
        let initialSize = CGSize(width: 1, height: 1)
        let resultSize = initialSize.bma_insetBy(dx: dx, dy: dy)
        let expectedSize = CGSize.zero
        XCTAssertEqual(resultSize, expectedSize)
    }

    func testThat_WhenInsetsAreNegative_ItInsetsCorrectly() {
        let dx: CGFloat = -1
        let dy: CGFloat = -1
        let initialSize = CGSize(width: 1, height: 1)
        let resultSize = initialSize.bma_insetBy(dx: dx, dy: dy)
        let expectedSize = CGSize(width: 2, height: 2)
        XCTAssertEqual(resultSize, expectedSize)
    }

    func testThat_WhenInsetsAreZero_ItInsetsCorrectly() {
        let initialSize = CGSize(width: 1, height: 1)
        let resultSize = initialSize.bma_insetBy(dx: 0, dy: 0)
        XCTAssertEqual(resultSize, initialSize)
    }

    func testThat_WhenOutsetsArePositive_ItOutsetsCorrectly() {
        let dx: CGFloat = 1
        let dy: CGFloat = 1
        let initialSize = CGSize(width: 1, height: 1)
        let resultSize = initialSize.bma_outsetBy(dx: dx, dy: dy)
        let expectedSize = CGSize(width: 2, height: 2)
        XCTAssertEqual(resultSize, expectedSize)
    }

    func testThat_WhenOutsetsAreNegative_ItOutsetsCorrectly() {
        let dx: CGFloat = -1
        let dy: CGFloat = -1
        let initialSize = CGSize(width: 1, height: 1)
        let resultSize = initialSize.bma_outsetBy(dx: dx, dy: dy)
        let expectedSize = CGSize.zero
        XCTAssertEqual(resultSize, expectedSize)
    }

    func testThat_WhenOutsetsAreZero_ItOutsetsCorrectly() {
        let initialSize = CGSize(width: 1, height: 1)
        let resultSize = initialSize.bma_outsetBy(dx: 0, dy: 0)
        XCTAssertEqual(resultSize, initialSize)
    }

    func testThat_ItRoundWidthAndHeightCorrectly() {
        let x1Scale: CGFloat = 1
        let x2Scale: CGFloat = 2
        let x3Scale: CGFloat = 3

        XCTAssertEqual(CGSize(width: 0.25, height: 0.25).bma_round(scale: x1Scale), CGSize(width: 1, height: 1))
        XCTAssertEqual(CGSize(width: 0.25, height: 0.25).bma_round(scale: x2Scale), CGSize(width: 1/x2Scale, height: 1/x2Scale))
        XCTAssertEqual(CGSize(width: 0.25, height: 0.25).bma_round(scale: x3Scale), CGSize(width: 1/x3Scale, height: 1/x3Scale))
    }

    func testThat_WhenXAlignmentIsLeft_ThenItReturnsCorrectRect() {
        let size = CGSize(width: 1, height: 1)
        let containerRect = CGRect(x: 0, y: 0, width: 3, height: 3)
        let resultRect = size.bma_rect(inContainer: containerRect, xAlignament: .left, yAlignment: .center)
        let expectedRect = CGRect(x: 0, y: 1, width: 1, height: 1)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func testThat_WhenXAlignmentIsCenter_ThenItReturnsCorrectRect() {
        let size = CGSize(width: 1, height: 1)
        let containerRect = CGRect(x: 0, y: 0, width: 3, height: 3)
        let resultRect = size.bma_rect(inContainer: containerRect, xAlignament: .center, yAlignment: .center)
        let expectedRect = CGRect(x: 1, y: 1, width: 1, height: 1)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func testThat_WhenXAlignmentIsRight_ThenItReturnsCorrectRect() {
        let size = CGSize(width: 1, height: 1)
        let containerRect = CGRect(x: 0, y: 0, width: 3, height: 3)
        let resultRect = size.bma_rect(inContainer: containerRect, xAlignament: .right, yAlignment: .center)
        let expectedRect = CGRect(x: 2, y: 1, width: 1, height: 1)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func testThat_WhenYAlignmentIsTop_ThenItReturnsCorrectRect() {
        let size = CGSize(width: 1, height: 1)
        let containerRect = CGRect(x: 0, y: 0, width: 3, height: 3)
        let resultRect = size.bma_rect(inContainer: containerRect, xAlignament: .center, yAlignment: .top)
        let expectedRect = CGRect(x: 1, y: 0, width: 1, height: 1)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func testThat_WhenYAlignmentIsCenter_ThenItReturnsCorrectRect() {
        let size = CGSize(width: 1, height: 1)
        let containerRect = CGRect(x: 0, y: 0, width: 3, height: 3)
        let resultRect = size.bma_rect(inContainer: containerRect, xAlignament: .center, yAlignment: .center)
        let expectedRect = CGRect(x: 1, y: 1, width: 1, height: 1)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func testThat_WhenYAlignmentIsBottom_ThenItReturnsCorrectRect() {
        let size = CGSize(width: 1, height: 1)
        let containerRect = CGRect(x: 0, y: 0, width: 3, height: 3)
        let resultRect = size.bma_rect(inContainer: containerRect, xAlignament: .center, yAlignment: .bottom)
        let expectedRect = CGRect(x: 1, y: 2, width: 1, height: 1)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func testThat_WhenOffsetIsSpecified_ThenItReturnsCorrectRect() {
        let size = CGSize(width: 1, height: 1)
        let dx: CGFloat = 1
        let dy: CGFloat = 1
        let containerRect = CGRect(x: 0, y: 0, width: 3, height: 3)
        let resultRect = size.bma_rect(inContainer: containerRect, xAlignament: .center, yAlignment: .center, dx: dx, dy: dy)
        let expectedRect = CGRect(x: 2, y: 2, width: 1, height: 1)
        XCTAssertEqual(resultRect, expectedRect)
    }
}
