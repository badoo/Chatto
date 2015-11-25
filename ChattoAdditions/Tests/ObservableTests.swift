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

class ObservableTests: XCTestCase {

    func testThatObserverClosureIsExecuted() {
        var subject = Observable<Int>(0)
        var executed = false
        subject.observe(self) { (old, new) -> () in
            executed = true
        }
        subject.value = 1
        XCTAssertTrue(executed)
    }

    func testThatObserverClosuresAreExecuted() {
        var subject = Observable<Int>(0)
        var executed1 = false, executed2 = false
        subject.observe(self) { (old, new) -> () in
            executed1 = true
        }
        subject.observe(self) { (old, new) -> () in
            executed2 = true
        }
        subject.value = 1
        XCTAssertTrue(executed1)
        XCTAssertTrue(executed2)
    }

    func testThatObserverClosureIsNotExecutedIfObserverWasDeallocated() {
        var subject = Observable<Int>(0)
        var observer: NSObject? = NSObject()
        var executed = false
        subject.observe(observer!) { (old, new) -> () in
            executed = true
        }
        observer = nil
        subject.value = 1
        XCTAssertFalse(executed)
    }

    func testNothingHappensIfNoObserversHaveBeenAdded() {
        var subject = Observable<Int>(0)
        subject.value = 1
        XCTAssertEqual(1, subject.value)
    }

}
