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

// Be aware this is not thread safe!
// Why class? https://lists.swift.org/pipermail/swift-users/Week-of-Mon-20160711/002580.html
public class Observable<T> {

    public init(_ value: T) {
        self.value = value
    }

    public var value: T {
        didSet {
            self.cleanDeadObservers()
            for observer in self.observers {
                observer.closure(oldValue, self.value)
            }
        }
    }

    public func observe(_ observer: AnyObject, closure: @escaping (_ old: T, _ new: T) -> ()) {
        self.observers.append(Observer(owner: observer, closure: closure))
        self.cleanDeadObservers()
    }

    private func cleanDeadObservers() {
        self.observers = self.observers.filter { $0.owner != nil }
    }

    private lazy var observers = [Observer<T>]()
}

private struct Observer<T> {
    weak var owner: AnyObject?
    let closure: (_ old: T, _ new: T) -> ()
    init (owner: AnyObject, closure: @escaping (_ old: T, _ new: T) -> ()) {
        self.owner = owner
        self.closure = closure
    }
}
