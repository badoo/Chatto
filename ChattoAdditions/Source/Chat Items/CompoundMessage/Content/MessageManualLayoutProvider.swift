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

public protocol MessageManualLayoutProviderProtocol {
    /// false by default
    var layoutInsideTail: Bool { get }
    func sizeThatFits(size: CGSize) -> CGSize
}

extension MessageManualLayoutProviderProtocol {
    public var layoutInsideTail: Bool { return false }
}

// MARK: - Text

public struct TextMessageLayoutProvider: MessageManualLayoutProviderProtocol {

    private let text: String
    private let font: UIFont
    private let textInsets: UIEdgeInsets

    public init(text: String, font: UIFont, textInsets: UIEdgeInsets) {
        self.text = text
        self.font = font
        self.textInsets = textInsets
    }

    public func sizeThatFits(size: CGSize) -> CGSize {
        let textContainer = NSTextContainer(size: size)
        textContainer.lineFragmentPadding = 0

        // See https://github.com/badoo/Chatto/issues/129
        let textStorage = NSTextStorage(string: self.text, attributes: [
            NSAttributedString.Key.font: self.font,
            NSAttributedString.Key(rawValue: "NSOriginalFont"): self.font
        ])

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        var size = layoutManager.usedRect(for: textContainer).size
        size.apply(insets: self.textInsets)
        return size.bma_round()
    }
}

// MARK: - Image

public struct ImageMessageLayoutProvider: MessageManualLayoutProviderProtocol {

    private let imageSize: CGSize

    public init(imageSize: CGSize) {
        self.imageSize = imageSize
    }

    public let layoutInsideTail = true

    public func sizeThatFits(size: CGSize) -> CGSize {
        let ratio = self.imageSize.width / self.imageSize.height
        return CGSize(width: size.width, height: size.width / ratio).bma_round()
    }
}

// MARK: - Private extensions

private extension CGSize {
    mutating func apply(insets: UIEdgeInsets) {
        self.width += insets.left + insets.right
        self.height += insets.top + insets.bottom
    }
}
