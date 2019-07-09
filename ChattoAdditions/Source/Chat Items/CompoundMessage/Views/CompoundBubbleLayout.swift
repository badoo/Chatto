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

public struct CompoundBubbleLayout {
    public let size: CGSize
    public let subviewsFrames: [CGRect]
    public let safeAreaInsets: UIEdgeInsets
}

public struct CompoundBubbleLayoutProvider {

    public struct Dimensions: Hashable {
        public let spacing: CGFloat
        public let contentInsets: UIEdgeInsets

        public init(spacing: CGFloat,
                    contentInsets: UIEdgeInsets) {
            self.spacing = spacing
            self.contentInsets = contentInsets
        }
    }

    public struct Configuration: Hashable {

        fileprivate let layoutProviders: [MessageManualLayoutProviderProtocol]
        fileprivate let tailWidth: CGFloat
        fileprivate let isIncoming: Bool
        fileprivate let dimensions: Dimensions

        public init(layoutProviders: [MessageManualLayoutProviderProtocol],
                    tailWidth: CGFloat,
                    isIncoming: Bool,
                    dimensions: Dimensions) {
            self.layoutProviders = layoutProviders
            self.tailWidth = tailWidth
            self.isIncoming = isIncoming
            self.dimensions = dimensions
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.layoutProviders.map { $0.asHashable })
            hasher.combine(self.tailWidth)
            hasher.combine(self.isIncoming)
            hasher.combine(self.dimensions)
        }

        public static func == (lhs: CompoundBubbleLayoutProvider.Configuration,
                               rhs: CompoundBubbleLayoutProvider.Configuration) -> Bool {
            return lhs.layoutProviders.map { $0.asHashable } == rhs.layoutProviders.map { $0.asHashable }
                && lhs.tailWidth == rhs.tailWidth
                && lhs.isIncoming == rhs.isIncoming
                && lhs.dimensions == rhs.dimensions
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
        let contentInsets = self.configuration.dimensions.contentInsets
        let safeAreaInsets = self.safeAreaInsets()
        let totalInsets = UIEdgeInsets(top: safeAreaInsets.top + contentInsets.top,
                                       left: safeAreaInsets.left + contentInsets.left,
                                       bottom: safeAreaInsets.bottom + contentInsets.bottom,
                                       right: safeAreaInsets.right + contentInsets.right)

        var resultWidth: CGFloat = 0
        let fittingSizeWithInsets = CGSize(width: width - contentInsets.bma_horziontalInset, height: .greatestFiniteMagnitude)
        let shouldAddTopInset = self.configuration.layoutProviders.first?.ignoreContentInsets == false
        let shouldAddBottomInset = self.configuration.layoutProviders.last?.ignoreContentInsets == false

        var maxY: CGFloat = shouldAddTopInset ? totalInsets.top : 0
        for (i, layoutProvider) in self.configuration.layoutProviders.enumerated() {
            let frame: CGRect
            if layoutProvider.ignoreContentInsets {
                let size = layoutProvider.sizeThatFits(size: CGSize(width: width, height: .greatestFiniteMagnitude), safeAreaInsets: safeAreaInsets)
                let viewWidth = max(size.width, resultWidth)
                resultWidth = min(viewWidth, width)
                frame = CGRect(x: 0, y: maxY, width: viewWidth, height: size.height)
            } else {
                let size = layoutProvider.sizeThatFits(size: fittingSizeWithInsets, safeAreaInsets: safeAreaInsets)
                let viewWidth = max(size.width + totalInsets.bma_horziontalInset, resultWidth)
                resultWidth = min(viewWidth, width)
                frame = CGRect(x: totalInsets.left, y: maxY, width: viewWidth, height: size.height)
            }
            subviewsFramesWithProviders.append((frame, layoutProvider))
            maxY = frame.maxY
            if i != self.configuration.layoutProviders.count - 1 {
                maxY += self.configuration.dimensions.spacing
            }
        }

        subviewsFramesWithProviders = subviewsFramesWithProviders.map({ frameWithProvider in
            var newFrame = frameWithProvider.frame
            if frameWithProvider.provider.ignoreContentInsets {
                newFrame.size.width = resultWidth
            } else {
                newFrame.size.width = resultWidth - totalInsets.bma_horziontalInset
            }
            return (newFrame, frameWithProvider.provider)
        })

        if shouldAddBottomInset {
            maxY += totalInsets.bottom
        }

        return CompoundBubbleLayout(
            size: CGSize(width: resultWidth, height: maxY).bma_round(),
            subviewsFrames: subviewsFramesWithProviders.map({ $0.frame }),
            safeAreaInsets: safeAreaInsets
        )
    }

    private func safeAreaInsets() -> UIEdgeInsets {
        var left: CGFloat = 0
        var right: CGFloat = 0
        if self.configuration.isIncoming {
            left = self.configuration.tailWidth
        } else {
            right = self.configuration.tailWidth
        }
        return UIEdgeInsets(top: 0, left: left, bottom: 0, right: right)
    }
}
