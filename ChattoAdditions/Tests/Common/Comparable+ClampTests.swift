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

import XCTest
@testable import ChattoAdditions

class Comparable_ClampTests: XCTestCase {
    func testThat_WhenValueIsBelowLowerBound_ThenResultIsEqualToLowerBound() {
        let range = 5...10
        let x = 3
        XCTAssertEqual(x.clamped(to: range), range.lowerBound)
    }

    func testThat_WhenValueIsEqualToLowerBound_ThenResultIsEqualToLowerBound() {
        let range = 5...10
        let x = range.lowerBound
        XCTAssertEqual(x.clamped(to: range), range.lowerBound)
    }

    func testThat_WhenValueIsInGivenRange_ThenResultIsOriginalValue() {
        let range = 5...10
        let x = 7
        XCTAssertEqual(x.clamped(to: range), x)
    }

    func testThat_WhenValueIsEqualToUpperBound_ThenResultIsEqualToUpperBound() {
        let range = 5...10
        let x = range.upperBound
        XCTAssertEqual(x.clamped(to: range), range.upperBound)
    }

    func testThat_WhenValueIsAboveUpperBound_ThenResultIsEqualToUpperBound() {
        let range = 5...10
        let x = 11
        XCTAssertEqual(x.clamped(to: range), range.upperBound)
    }
}
