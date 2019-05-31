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

    public struct Configuration: Hashable {

        fileprivate let layoutProviders: [MessageManualLayoutProviderProtocol]
        fileprivate let tailWidth: CGFloat
        fileprivate let isIncoming: Bool

        public init(layoutProviders: [MessageManualLayoutProviderProtocol],
                    tailWidth: CGFloat,
                    isIncoming: Bool) {
            self.layoutProviders = layoutProviders
            self.tailWidth = tailWidth
            self.isIncoming = isIncoming
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.layoutProviders.map { $0.asHashable })
            hasher.combine(self.tailWidth)
            hasher.combine(self.isIncoming)
        }

        public static func == (lhs: CompoundBubbleLayoutProvider.Configuration,
                               rhs: CompoundBubbleLayoutProvider.Configuration) -> Bool {
            return lhs.layoutProviders.map { $0.asHashable } == rhs.layoutProviders.map { $0.asHashable }
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

    private func makeLayout(forMaxWidth width: CGFloat) -> CompoundBubbleLayout {
        var subviewsFrames: [CGRect] = []
        subviewsFrames.reserveCapacity(self.configuration.layoutProviders.count)
        var maxY: CGFloat = 0
        var resultWidth: CGFloat = 0
        let sizeToFit = CGSize(width: width,
                               height: .greatestFiniteMagnitude)
        let safeAreaInsets = self.safeAreaInsets()
        for layoutProvider in self.configuration.layoutProviders {
            let size = layoutProvider.sizeThatFits(size: sizeToFit, safeAreaInsets: safeAreaInsets)
            let viewWidth = max(size.width, resultWidth)
            resultWidth = min(viewWidth, width)
            let frame = CGRect(x: 0, y: maxY, width: viewWidth, height: size.height)
            subviewsFrames.append(frame)
            maxY = frame.maxY
        }
        return CompoundBubbleLayout(
            size: CGSize(width: resultWidth, height: maxY).bma_round(),
            subviewsFrames: subviewsFrames,
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
