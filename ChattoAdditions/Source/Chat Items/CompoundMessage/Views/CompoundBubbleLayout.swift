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

import UIKit

public struct CompoundBubbleLayout {
    public let size: CGSize
    public let subviewsFrames: [CGRect]
    public let safeAreaInsets: UIEdgeInsets
}

public struct CompoundBubbleLayoutProvider {

    public struct Configuration: Hashable {

        fileprivate let layoutProviders: [MessageManualLayoutProviderProtocol]
        fileprivate let decorationLayoutProviders: [MessageDecorationViewLayoutProviderProtocol]
        fileprivate let tailWidth: CGFloat
        fileprivate let isIncoming: Bool

        public init(layoutProviders: [MessageManualLayoutProviderProtocol],
                    decorationLayoutProviders: [MessageDecorationViewLayoutProviderProtocol],
                    tailWidth: CGFloat,
                    isIncoming: Bool) {
            self.layoutProviders = layoutProviders
            self.decorationLayoutProviders = decorationLayoutProviders
            self.tailWidth = tailWidth
            self.isIncoming = isIncoming
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.layoutProviders.map(\.asHashable))
            hasher.combine(self.decorationLayoutProviders.map(\.asHashable))
            hasher.combine(self.tailWidth)
            hasher.combine(self.isIncoming)
        }

        public static func == (lhs: CompoundBubbleLayoutProvider.Configuration,
                               rhs: CompoundBubbleLayoutProvider.Configuration) -> Bool {
            return lhs.layoutProviders.map(\.asHashable) == rhs.layoutProviders.map(\.asHashable)
                && lhs.decorationLayoutProviders.map(\.asHashable) == rhs.decorationLayoutProviders.map(\.asHashable)
                && lhs.tailWidth == rhs.tailWidth
                && lhs.isIncoming == rhs.isIncoming
        }
    }

    private let configuration: Configuration
    private let cache = Cache<CGFloat, CompoundBubbleLayout>()

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func layout(forMaxWidth width: CGFloat) -> CompoundBubbleLayout {
        if let layout = self.cache[width] {
            return layout
        }
        let layout = self.makeLayout(forMaxWidth: width)
        self.cache[width] = layout
        return layout
    }

    private typealias RectWithLayoutProvider = (frame: CGRect, provider: MessageManualLayoutProviderProtocol)

    private func makeLayout(forMaxWidth width: CGFloat) -> CompoundBubbleLayout {
        var subviewsFramesWithProviders: [RectWithLayoutProvider] = []
        subviewsFramesWithProviders.reserveCapacity(self.configuration.layoutProviders.count)
        let safeAreaInsets = self.safeAreaInsets()

        var resultWidth: CGFloat = 0
        var maxY: CGFloat = 0
        self.configuration.layoutProviders.forEach { layoutProvider in
            let frame: CGRect
            let size = layoutProvider.sizeThatFits(size: CGSize(width: width, height: .greatestFiniteMagnitude), safeAreaInsets: safeAreaInsets)
            let viewWidth = max(size.width, resultWidth)
            resultWidth = min(viewWidth, width)
            frame = CGRect(x: 0, y: maxY, width: viewWidth, height: size.height)
            subviewsFramesWithProviders.append((frame, layoutProvider))
            maxY = frame.maxY
        }

        subviewsFramesWithProviders = subviewsFramesWithProviders.map { frameWithProvider in
            var newFrame = frameWithProvider.frame
            newFrame.size.width = resultWidth
            return (newFrame, frameWithProvider.provider)
        }

        return CompoundBubbleLayout(
            size: CGSize(width: resultWidth, height: maxY).bma_round(),
            subviewsFrames: subviewsFramesWithProviders.map({ $0.frame }),
            safeAreaInsets: safeAreaInsets
        )
    }

    private func safeAreaInsets() -> UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        if self.configuration.isIncoming {
            insets.left = self.configuration.tailWidth
        } else {
            insets.right = self.configuration.tailWidth
        }

        for provider in self.configuration.decorationLayoutProviders {
            insets.combine(with: provider.safeAreaInsets)
        }

        return insets
    }
}

private extension UIEdgeInsets {
    mutating func combine(with other: UIEdgeInsets) {
        self.top = max(self.top, other.top)
        self.left = max(self.left, other.left)
        self.right = max(self.right, other.right)
        self.bottom = max(self.bottom, other.bottom)
    }
}
