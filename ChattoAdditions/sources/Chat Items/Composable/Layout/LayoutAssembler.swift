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

public struct LayoutAssembler {

    // MARK: - Type declarations

    public typealias Key = AnyBindingKey
    private typealias LayoutCache = [AnyBindingKey: AnyCachedLayoutProvider]

    public enum Error: Swift.Error {
        case notFound(Key)
        case internalInconsistency
        case layoutWasNotCalculated(Key)
    }

    // MARK: - Private properties

    private let hierarchy: MessageViewHierarchy
    private var makeSizeProviders: [AnyBindingKey: (Any) throws -> AnySizeProvider] = [:]
    private var makeCachingProviders: [AnyBindingKey: (Any) throws -> AnyCachedLayoutProvider] = [:]
    private var layoutApplicators: [AnyBindingKey: (Any, Any) throws -> Void] = [:]

    // MARK: - Instantiation

    public init(hierarchy: MessageViewHierarchy) {
        self.hierarchy = hierarchy
    }

    // MARK: - Public API

    // TODO: Remove #746
    public mutating func populateSizeProviders<Key: BindingKeyProtocol>(for key: Key)
        where Key.LayoutProvider.Layout: SizeContainer, Key.View: ManualLayoutViewProtocol, Key.View.Layout == Key.LayoutProvider.Layout {
        let erasedKey = AnyBindingKey(key)
        self.makeSizeProviders[erasedKey] = { anyLayoutProvider in
            guard let layoutProvider = anyLayoutProvider as? CachingLayoutProvider<Key.LayoutProvider.Layout> else {
                throw Error.internalInconsistency
            }
            return AnySizeProvider(layoutProvider)
        }
        self.makeCachingProviders[erasedKey] = { anyLayoutProvider in
            guard let layoutProvider = anyLayoutProvider as? Key.LayoutProvider else {
                throw Error.internalInconsistency
            }
            return CachingLayoutProvider(layoutProvider)
        }
        self.layoutApplicators[erasedKey] = { anyView, anyLayout in
            guard let view = anyView as? Key.View, let layout = anyLayout as? Key.LayoutProvider.Layout else {
                throw Error.internalInconsistency
            }
            view.apply(layout: layout)
        }
    }

    public func assembleRootSizeProvider(layoutProviders: [Key: Any]) throws -> AnySizeProvider {
        let key = self.hierarchy.root
        var layoutCache: LayoutCache = [:]
        return try self.assemble(for: key, with: layoutProviders, layoutCache: &layoutCache)
    }

    // TODO: #747
    public func applyLayout(with context: LayoutContext, views: [Key: Any], layoutProviders: [Key: Any]) throws {
        var layoutCache: LayoutCache = [:]
        // TODO: Check keys
        let rootLayoutProvider = try self.assemble(for: self.hierarchy.root, with: layoutProviders, layoutCache: &layoutCache)

        // perform layout to cache results
        _ = try rootLayoutProvider.layout(for: context)

        for (key, view) in views {
            guard let applicator = self.layoutApplicators[key] else {
                throw Error.notFound(key)
            }

            guard let cachedLayout = layoutCache[key]?.lastPerformedLayoutResult else {
                throw Error.layoutWasNotCalculated(key)
            }

            try applicator(view, cachedLayout)
        }
    }

    // MARK: - Private

    private func assemble(for key: Key, with providers: [Key: Any], layoutCache: inout LayoutCache) throws -> AnySizeProvider {
        guard let layoutProvider = providers[key] else {
            throw Error.notFound(key)
        }

        guard let makeSizeProvider = makeSizeProviders[key] else {
            throw Error.notFound(key)
        }

        guard let makeCachingProvider = makeCachingProviders[key] else {
            throw Error.notFound(key)
        }

        let resultLayoutProvider: Any

        switch try self.hierarchy.children(of: key) {
        case .no:
            resultLayoutProvider = layoutProvider
        case .single(let childKey):
            let child = try self.assemble(for: childKey, with: providers, layoutCache: &layoutCache)

            guard var container = layoutProvider as? SingleContainerLayoutProviderProtocol else {
                throw Error.internalInconsistency
            }

            container.childLayoutProvider = child
            resultLayoutProvider = container
        case .multiple(let childrenKeys):
            let children: [AnySizeProvider] = try childrenKeys.map {
                try self.assemble(for: $0, with: providers, layoutCache: &layoutCache)
            }

            guard var container = layoutProvider as? MultipleContainerLayoutProviderProtocol else {
                throw Error.internalInconsistency
            }

            container.childrenLayoutProviders = children
            resultLayoutProvider = container
        }

        let cachingContainer = try makeCachingProvider(resultLayoutProvider)
        layoutCache[key] = cachingContainer
        let sizeProvider = try makeSizeProvider(cachingContainer)
        return sizeProvider
    }
}

public protocol AnyCachedLayoutProvider {
    var lastPerformedLayoutResult: Any? { get }
}

private final class CachingLayoutProvider<Layout: LayoutModel>: LayoutProviderProtocol {

    private let _layout: (LayoutContext) throws -> Layout

    private(set) var lastLayout: Layout?

    init<Base: LayoutProviderProtocol>(_ base: Base) where Base.Layout == Layout {
        self._layout = { try base.layout(for: $0) }
    }

    func layout(for context: LayoutContext) throws -> Layout {
        let layout = try self._layout(context)
        self.lastLayout = layout
        return layout
    }
}

extension CachingLayoutProvider: AnyCachedLayoutProvider {
    var lastPerformedLayoutResult: Any? { self.lastLayout }
}

