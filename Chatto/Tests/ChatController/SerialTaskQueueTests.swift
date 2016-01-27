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

class SerialTaskQueueTests: XCTestCase {

    func testThat_GivenIsFreshlyCreated_WhenNewTaskIsAdded_ThenTaskIsNotExecuted() {
        let queue = SerialTaskQueue()
        var executed = false
        queue.addTask { (completion) -> () in
            executed = true
            completion()
        }
        XCTAssertFalse(executed)
    }

    func testThat_GivenPausedQueueWithOneTask_WhenQueueIsStarted_ThenTaskIsExecuted() {
        let queue = SerialTaskQueue()
        var executed = false
        queue.addTask { (completion) -> () in
            executed = true
            completion()
        }
        queue.start()
        XCTAssertTrue(executed)
    }

    func testThat_GivenQueueWithTwoTasks_WhenFirstTaskFinished_ThenSecondTaskIsExecuted() {
        let queue = SerialTaskQueue()
        var secondTaskExecuted = false
        queue.addTask { (completion) -> () in
            completion()
        }
        queue.addTask { (completion) -> () in
            secondTaskExecuted = true
            completion()
        }

        queue.start()
        XCTAssertTrue(secondTaskExecuted)
    }

    func testThat_GivenQueueWithRunningTask_WhenNewTaskIsAdded_ThenNewTaskIsNotExecute() {
        let queue = SerialTaskQueue()
        var secondTaskExecuted = false
        queue.addTask { (completion) -> () in
            // First task diddn't finish, second task won't be executed
        }
        queue.addTask { (completion) -> () in
            secondTaskExecuted = true
            completion()
        }

        queue.start()
        XCTAssertFalse(secondTaskExecuted)
    }

    func testThat_GivenIdleQueue_WhenTaskIsAdded_ThenTaskIsExecuted() {
        var executed = false
        let queue = SerialTaskQueue()
        queue.start()
        queue.addTask { (completion) -> () in
            executed = true
            completion()
        }
        XCTAssertTrue(executed)
    }

    func testThat_GivenQueueIsStopped_WhenTaskIsAdded_ThenTaskIsNotExecuted() {
        let queue = SerialTaskQueue()
        var secondTaskExecuted = false
        queue.start()
        queue.addTask { (completion) -> () in
            completion()
        }
        queue.stop()
        queue.addTask { (completion) -> () in
            secondTaskExecuted = true
            completion()
        }
        XCTAssertFalse(secondTaskExecuted)
    }
}
