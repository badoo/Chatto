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
@testable import ChattoApp

class SlidingDataSourceTests: XCTestCase {

    func testThat_WhenCountGreaterThanPageSize_ThenInitializesCorrectly() {
        var uid = 0
        let expectedArray = (0..<50).reverse().map { (id) -> String in
            return "\(id)"
        }
        let dataSource = SlidingDataSource(count: 10000, pageSize: 50) { () -> String in
            defer { uid += 1 }
            return "\(uid)"
        }

        XCTAssertEqual(expectedArray, dataSource.itemsInWindow)
        XCTAssertTrue(dataSource.hasPrevious())
        XCTAssertFalse(dataSource.hasMore())
    }

    func testThat_WhenCountLessThanPageSize_ThenInitializesCorrectly() {
        var uid = 0
        let expectedArray = (0..<10).reverse().map { (id) -> String in
            return "\(id)"
        }
        let dataSource = SlidingDataSource(count: 10, pageSize: 50) { () -> String in
            defer { uid += 1 }
            return "\(uid)"
        }

        XCTAssertEqual(expectedArray, dataSource.itemsInWindow)
        XCTAssertFalse(dataSource.hasPrevious())
        XCTAssertFalse(dataSource.hasMore())
    }

    func testThat_WhenCountIsZero_ThenInitializesCorrectly() {
        var uid = 0
        let dataSource = SlidingDataSource(count: 0, pageSize: 50) { () -> String in
            defer { uid += 1 }
            return "\(uid)"
        }
        XCTAssertEqual([], dataSource.itemsInWindow)
        XCTAssertFalse(dataSource.hasPrevious())
        XCTAssertFalse(dataSource.hasMore())
    }


    func testThat_LoadPreviousAddsElementsOnTheTop() {
        var uid = 0
        let expectedArray = (0..<100).reverse().map { (id) -> String in
            return "\(id)"
        }
        let dataSource = SlidingDataSource(count: 10000, pageSize: 50) { (id) -> String in
            defer { uid += 1 }
            return "\(uid)"
        }

        dataSource.loadPrevious()

        XCTAssertEqual(expectedArray, dataSource.itemsInWindow)
        XCTAssertTrue(dataSource.hasPrevious())
        XCTAssertFalse(dataSource.hasMore())
    }

    func testThat_LoadNextAddsElementsOnTheBottom() {
        var uid = 0
        let expectedArray = (300..<550).reverse().map { (id) -> String in
            return "\(id)"
        }

        let dataSource = SlidingDataSource(count: 10000, pageSize: 50) { (id) -> String in
            defer { uid += 1 }
            return "\(uid)"
        }

        for _ in 0..<10 {
            dataSource.loadPrevious()
            dataSource.adjustWindow(focusPosition: 0, maxWindowSize: 200)
        }
        dataSource.loadNext()

        XCTAssertEqual(expectedArray, dataSource.itemsInWindow)
    }

    func testThat_AdjustSizeReducesSizeAroundFocusPosition() {
        var uid = 0
        let expectedArray = (140..<150).reverse().map { (id) -> String in
            return "\(id)"
        }

        let dataSource = SlidingDataSource(count: 10000, pageSize: 50) { (id) -> String in
            defer { uid += 1 }
            return "\(uid)"
        }
        dataSource.loadPrevious()
        dataSource.loadPrevious()
        dataSource.adjustWindow(focusPosition: 0, maxWindowSize: 10)

        XCTAssertEqual(expectedArray, dataSource.itemsInWindow)
    }

    func testThat_Bug1DoesNotReproduce() { // Yes, proper name would be unreadable
        // Insert item when window does not containt bottom most message
        // Scroll to the bottom adjusting window size
        // Load previous --> crash
        var uid = 0
        var expectedArray = (0..<249).reverse().map { (id) -> String in
            return "\(id)"
        }
        expectedArray.append("test")

        let dataSource = SlidingDataSource(count: 10000, pageSize: 50) { (id) -> String in
            defer { uid += 1 }
            return "\(uid)"
        }

        for _ in 0..<10 {
            dataSource.loadPrevious()
            dataSource.adjustWindow(focusPosition: 0, maxWindowSize: 200)
        }
        dataSource.insertItem("test", position: .Bottom)


        while dataSource.hasMore() {
            dataSource.loadNext()
            dataSource.adjustWindow(focusPosition: 1, maxWindowSize: 200)
        }

        dataSource.loadPrevious()

        XCTAssertEqual(expectedArray, dataSource.itemsInWindow)
    }

    func testThat_LastLoadPreviousContainsFirstMessage() {
        var uid = 0
        let expectedArray = (0..<52).reverse().map { (id) -> String in
            return "\(id)"
        }
        let dataSource = SlidingDataSource(count: 52, pageSize: 50) { (id) -> String in
            defer { uid += 1 }
            return "\(uid)"
        }

        dataSource.loadPrevious()

        XCTAssertEqual(expectedArray, dataSource.itemsInWindow)
    }
}
