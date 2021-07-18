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

public protocol LayoutProviderProtocol {
    associatedtype Layout: LayoutModel
    func layout(for context: LayoutContext) throws -> Layout
}

// TODO: Remove #745
public struct AnyLayoutProvider<Layout: LayoutModel>: LayoutProviderProtocol {
    private let _layout: (LayoutContext) throws -> Layout

    public init<Base: LayoutProviderProtocol>(_ base: Base) where Base.Layout == Layout {
        self._layout = { try base.layout(for: $0) }
    }

    public func layout(for context: LayoutContext) throws -> Layout {
        try self._layout(context)
    }
}

public struct AnySizeContainer: SizeContainer {
    private var _size:  () -> CGSize

    public init<Base: SizeContainer>(_ base: Base) {
        self._size = { base.size }
    }

    public var size: CGSize { self._size() }
}

extension AnySizeContainer: LayoutModel {}

extension AnyLayoutProvider where Layout == AnySizeContainer {
    public init<Base: LayoutProviderProtocol>(_ base: Base) where Base.Layout: SizeContainer {
        self._layout = { .init(try base.layout(for: $0)) }
    }
}

public typealias AnySizeProvider = AnyLayoutProvider<AnySizeContainer>
