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

import Foundation
import XCTest
import Chatto
import Dispatch

@available(iOS 13, *)
final class ObservableAsyncStreamTests: XCTestCase {

    func test_GivenStreamFromObservable_WhenObservableUpdates_ThenValueDeliveredToStream() async throws {
        let observable = Observable(0)
        let stream = observable.values

        async let firstReceivedValue: Int? = stream.first { _ in true }
        observable.value = 1
        let first = await firstReceivedValue
        XCTAssertEqual(first, 1)

        async let secondReceivedValue: Int? = stream.first { _ in true }
        observable.value = 2
        let second = await secondReceivedValue
        XCTAssertEqual(second, 2)
    }

    func test_WhenObservableDeallocated_ThenStreamCompletes() async throws {
        var observable: Observable<Void>? = .init(())
        let stream = observable!.values
        let iterateAllStreamValuesTask = Task {
            for await _ in stream {}
        }
        observable = nil

        try await withTimeout { await iterateAllStreamValuesTask.value }
    }

    // MARK: - Timeout utils

    private struct TimeoutError: Error {}

    private func withTimeout<T>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)
                throw TimeoutError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
