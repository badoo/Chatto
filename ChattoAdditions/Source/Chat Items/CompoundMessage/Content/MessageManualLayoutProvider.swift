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

public protocol MessageManualLayoutProviderProtocol: HashableRepresentible {
    var ignoreContentInsets: Bool { get }
    func sizeThatFits(size: CGSize, safeAreaInsets: UIEdgeInsets) -> CGSize
}

// MARK: - Text

public struct TextMessageLayoutProvider: Hashable, MessageManualLayoutProviderProtocol {

    private let text: String
    private let font: UIFont
    private let textInsets: UIEdgeInsets
    private let numberOfLines: Int

    public init(text: String, font: UIFont, textInsets: UIEdgeInsets, numberOfLines: Int = 0, ignoreContentInsets: Bool = false) {
        self.text = text
        self.font = font
        self.textInsets = textInsets
        self.numberOfLines = numberOfLines
        self.ignoreContentInsets = ignoreContentInsets
    }

    public let ignoreContentInsets: Bool

    public func sizeThatFits(size: CGSize, safeAreaInsets: UIEdgeInsets) -> CGSize {
        var sizeWithInset = size
        sizeWithInset.substract(insets: safeAreaInsets)
        sizeWithInset.substract(insets: self.textInsets)
        let textContainer = NSTextContainer(size: sizeWithInset)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = self.numberOfLines

        // See https://github.com/badoo/Chatto/issues/129
        let textStorage = NSTextStorage(string: self.text, attributes: [
            NSAttributedString.Key.font: self.font,
            NSAttributedString.Key(rawValue: "NSOriginalFont"): self.font
        ])

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        var resultSize = layoutManager.usedRect(for: textContainer).size.bma_round()
        resultSize.add(insets: safeAreaInsets)
        resultSize.add(insets: self.textInsets)
        return resultSize
    }
}

// MARK: - Image

public struct ImageMessageLayoutProvider: Hashable, MessageManualLayoutProviderProtocol {

    private let imageSize: CGSize

    public init(imageSize: CGSize, ignoreContentInsets: Bool = false) {
        self.imageSize = imageSize
        self.ignoreContentInsets = ignoreContentInsets
    }

    public let ignoreContentInsets: Bool

    public func sizeThatFits(size: CGSize, safeAreaInsets: UIEdgeInsets) -> CGSize {
        let ratio = self.imageSize.width / self.imageSize.height
        return CGSize(width: size.width, height: size.width / ratio).bma_round()
    }
}

// MARK: - Private extensions

private extension CGSize {
    mutating func add(insets: UIEdgeInsets) {
        self.width += insets.left + insets.right
        self.height += insets.top + insets.bottom
    }
    mutating func substract(insets: UIEdgeInsets) {
        self.width -= insets.left + insets.right
        self.height -= insets.top + insets.bottom
    }
}
