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

class CGPoint_AdditionsTests: XCTestCase {
    func testThat_WhenOffsetIsPositive_ItOffsetsCorrectly() {
        let point = CGPoint(x: 0, y: 0)
        let offset: CGFloat = 1
        let resultPoint = point.bma_offsetBy(dx: offset, dy: offset)
        let expectedPoint = CGPoint(x: 1, y: 1)
        XCTAssertEqual(resultPoint, expectedPoint)
    }

    func testThat_WhenOffsetIsNegative_ItOffsetsCorrectly() {
        let point = CGPoint(x: 0, y: 0)
        let offset: CGFloat = -1
        let resultPoint = point.bma_offsetBy(dx: offset, dy: offset)
        let expectedPoint = CGPoint(x: -1, y: -1)
        XCTAssertEqual(resultPoint, expectedPoint)
    }

    func testThat_WhenOffsetIsZero_ItOffsetsCorrectly() {
        let point = CGPoint(x: 0, y: 0)
        let offset: CGFloat = 0
        let resultPoint = point.bma_offsetBy(dx: offset, dy: offset)
        XCTAssertEqual(resultPoint, point)
    }

    // MARK: - Clamping

    func testThat_GivenPointThatIsOutsideOfRect_WhenItIsClamped_ThenResultIsInsideRect() {
        let point = CGPoint(x: 0, y: 0)
        let rect = CGRect(x: 1, y: 1, width: 10, height: 10)
        let result = point.clamped(to: rect)
        XCTAssertTrue(rect.contains(result))
    }

    func testThat_GivenPointThatIsInsideOfRect_WhenItIsClamped_ThenResultIsEqualToOriginalValue() {
        let point = CGPoint(x: 2, y: 2)
        let rect = CGRect(x: 1, y: 1, width: 10, height: 10)
        let result = point.clamped(to: rect)
        XCTAssertEqual(result, point)
    }
}
