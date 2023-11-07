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

// MARK: - Observable

// Be aware this is not thread safe!
// Why class? https://lists.swift.org/pipermail/swift-users/Week-of-Mon-20160711/002580.html
public class Observable<T> {

    public init(_ value: T) {
        self.value = value
    }

    public var value: T {
        didSet {
            self.lock.lock()
            self.observers.cleanDead()
            let observers = self.observers
            self.lock.unlock()
            observers.forEach { $0.notify(oldValue, self.value) }
        }
    }

    public func observe(_ observer: AnyObject, closure: @escaping (_ old: T, _ new: T) -> Void) {
        self.addObserver(Observer(owner: observer, closure: closure))
    }

    public func removeObserver(_ observer: AnyObject) {
        self.lock.lock()
        defer { self.lock.unlock() }

        self.observers.removeAll { $0.isOwner(observer) }
    }

    // MARK: - Private

    private func addObserver<Observer: ObserverProtocol>(_ observer: Observer) where Observer.T == T {
        self.lock.lock()
        defer { self.lock.unlock() }

        self.observers.append(.init(observer))
        self.observers.cleanDead()
    }

    private let lock = NSLock()
    private var observers: [AnyObserver<T>] = []
}

private extension Array where Element: ObserverProtocol {
    mutating func cleanDead() {
        self.removeAll { $0.terminated }
    }
}

// MARK: - Observer

// MARK: Protocol

private protocol ObserverProtocol<T> {
    associatedtype T
    var terminated: Bool { get }
    func notify(_ old: T, _ new: T)
    func isOwner(_ owner: AnyObject) -> Bool
}

private struct AnyObserver<T>: ObserverProtocol {

    private let _isOwner: (AnyObject) -> Bool
    private let _notify: (T, T) -> Void
    private let _terminated: () -> Bool

    init<U: ObserverProtocol>(_ observer: U) where U.T == T {
        self._isOwner = observer.isOwner
        self._notify = observer.notify
        self._terminated = { observer.terminated }
    }

    var terminated: Bool { self._terminated() }

    func notify(_ old: T, _ new: T) {
        self._notify(old, new)
    }

    func isOwner(_ owner: AnyObject) -> Bool {
        self._isOwner(owner)
    }
}

// MARK: Implementation

private struct Observer<T>: ObserverProtocol {
    weak var owner: AnyObject?
    let closure: (_ old: T, _ new: T) -> Void
    init(owner: AnyObject, closure: @escaping (_ old: T, _ new: T) -> Void) {
        self.owner = owner
        self.closure = closure
    }

    var terminated: Bool { self.owner == nil }

    func notify(_ old: T, _ new: T) {
        self.closure(old, new)
    }

    func isOwner(_ owner: AnyObject) -> Bool {
        self.owner === owner
    }
}

// MARK: - AsyncStream mapping

@available(iOS 13, *)
extension Observable {
    public func asyncStream() -> AsyncStream<T> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.addObserver(AsyncStreamObserver(continuation: continuation))
        }
    }
}

@available(iOS 13, *)
private final class AsyncStreamObserver<T>: ObserverProtocol, @unchecked Sendable {

    private let continuation: AsyncStream<T>.Continuation

    private let lock = NSLock()
    private var _terminated: Bool = false
    private(set) var terminated: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return self._terminated
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            self._terminated = newValue
        }
    }

    deinit {
        self.continuation.finish()
    }

    init(continuation: AsyncStream<T>.Continuation) {
        self.continuation = continuation
        self.continuation.onTermination = { [weak self] _ in
            self?.terminated = true
        }
    }

    func notify(_: T, _ new: T) {
        guard !self.terminated else { return }
        self.continuation.yield(new)
    }

    func isOwner(_: AnyObject) -> Bool { false }
}
