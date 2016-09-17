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

import Foundation

public enum UpdateType {
    case normal
    case firstLoad
    case pagination
    case reload
    case messageCountReduction
}

public protocol ChatDataSourceDelegateProtocol: class {
    func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol)
    func chatDataSourceDidUpdate(_ chatDataSource: ChatDataSourceProtocol, updateType: UpdateType)
}

public protocol ChatDataSourceProtocol: class {
    var hasMoreNext: Bool { get }
    var hasMorePrevious: Bool { get }
    var chatItems: [ChatItemProtocol] { get }
    weak var delegate: ChatDataSourceDelegateProtocol? { get set }

    func loadNext() // Should trigger chatDataSourceDidUpdate with UpdateType.Pagination
    func loadPrevious() // Should trigger chatDataSourceDidUpdate with UpdateType.Pagination
    func adjustNumberOfMessages(preferredMaxCount: Int?, focusPosition: Double, completion:(_ didAdjust: Bool) -> Void) // If you want, implement message count contention for performance, otherwise just call completion(false)
}
