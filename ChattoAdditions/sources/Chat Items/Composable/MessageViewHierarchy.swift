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


public struct MessageViewHierarchy {

    // MARK: - Type Declarations

    public enum Children {
        case no
        case single(AnyBindingKey)
        case multiple([AnyBindingKey])
    }

    enum AddError: Error {
        case alreadyRegistered
    }

    // MARK: - Private properties

    private var registeredChildren: [AnyBindingKey: Children] = [:]

    // MARK: - Instantiation

    public init(root: AnyBindingKey) {
        self.root = root
    }

    // MARK: - Public API

    // MARK: Registration

    public mutating func add<ParentKey: BindingKeyProtocol>(child: AnyBindingKey, to parent: ParentKey) throws where ParentKey.View: SingleContainerViewProtocol {
        try self.register(children: .single(child), to: parent)
    }

    public mutating func add<ParentKey: BindingKeyProtocol>(children: [AnyBindingKey], to parent: ParentKey) throws where ParentKey.View: MultipleContainerViewProtocol {
        try self.register(children: .multiple(children), to: parent)
    }

    // MARK: Fetching

    public let root: AnyBindingKey

    public func children(of parent: AnyBindingKey) throws -> Children {
        self.registeredChildren[parent] ?? .no
    }

    public func allRegistrations() -> [AnyBindingKey: Children] { self.registeredChildren }

    // MARK: - Private methods

    private mutating func register<ParentKey: BindingKeyProtocol>(children: Children, to parent: ParentKey) throws {
        let erasedParent = AnyBindingKey(parent)
        guard self.registeredChildren[erasedParent] == nil else { throw AddError.alreadyRegistered }
        self.registeredChildren[erasedParent] = children
    }
}

// Convenience
extension MessageViewHierarchy {

    public mutating func add<ChildKey: BindingKeyProtocol, ParentKey: BindingKeyProtocol>(child: ChildKey, to parent: ParentKey) throws where ParentKey.View: SingleContainerViewProtocol {
        try self.add(child: .init(child), to: parent)
    }

    public init<Key: BindingKeyProtocol>(root: Key) {
        self.init(root: .init(root))
    }
}

