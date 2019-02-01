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
}

public struct CompoundBubbleLayoutProvider {

    private let layoutProviders: [MessageManualLayoutProviderProtocol]
    private let safeAreaInsets: UIEdgeInsets

    public init(layoutProviders: [MessageManualLayoutProviderProtocol], safeAreaInsets: UIEdgeInsets) {
        self.layoutProviders = layoutProviders
        self.safeAreaInsets = safeAreaInsets
    }

    public func makeLayout(forMaxWidth width: CGFloat) -> CompoundBubbleLayout {
        var subviewsFrames: [CGRect] = []
        subviewsFrames.reserveCapacity(self.layoutProviders.count)
        var maxY: CGFloat = 0
        var resultWidth: CGFloat = 0
        let sizeToFit = CGSize(width: width,
                               height: .greatestFiniteMagnitude)
        for layoutProvider in self.layoutProviders {
            let size = layoutProvider.sizeThatFits(size: sizeToFit, safeAreaInsets: self.safeAreaInsets)
            let viewWidth = max(size.width, resultWidth)
            resultWidth = min(viewWidth, width)
            let frame = CGRect(x: 0, y: maxY, width: viewWidth, height: size.height)
            subviewsFrames.append(frame)
            maxY = frame.maxY
        }
        return CompoundBubbleLayout(
            size: CGSize(width: resultWidth, height: maxY),
            subviewsFrames: subviewsFrames
        )
    }
}
