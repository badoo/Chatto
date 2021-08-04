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
import Chatto

public struct LayoutInfo {

    public let size: CGSize
    public let contentInsets: UIEdgeInsets

    public init(size: CGSize, contentInsets: UIEdgeInsets) {
        self.size = size
        self.contentInsets = contentInsets
    }
}

public protocol MessageManualLayoutProviderProtocol: HashableRepresentible {
    func layoutThatFits(size: CGSize, safeAreaInsets: UIEdgeInsets) -> LayoutInfo
}

// MARK: - Text

public struct TextMessageLayout {
    public let frame: CGRect
    public let size: CGSize
    public let contentInsets: UIEdgeInsets

    public init(frame: CGRect, size: CGSize, contentInsets: UIEdgeInsets) {
        self.frame = frame
        self.size = size
        self.contentInsets = contentInsets
    }
}

public protocol TextMessageLayoutProviderProtocol: MessageManualLayoutProviderProtocol {
    func layout(for size: CGSize, safeAreaInsets: UIEdgeInsets) -> TextMessageLayout
}

extension TextMessageLayoutProviderProtocol {
    public func layoutThatFits(size: CGSize, safeAreaInsets: UIEdgeInsets) -> LayoutInfo {
        let layout = self.layout(for: size, safeAreaInsets: safeAreaInsets)
        return LayoutInfo(size: layout.size, contentInsets: layout.contentInsets)
    }
}

public struct TextMessageLayoutProvider: Hashable, TextMessageLayoutProviderProtocol {

    private let text: String
    private let font: UIFont
    private let textInsets: UIEdgeInsets
    private let textInsetsFromSafeArea: UIEdgeInsets?
    private let numberOfLines: Int

    public init(text: String,
                font: UIFont,
                textInsets: UIEdgeInsets,
                textInsetsFromSafeArea: UIEdgeInsets? = nil,
                numberOfLines: Int = 0) {
        self.text = text
        self.font = font
        self.textInsets = textInsets
        self.textInsetsFromSafeArea = textInsetsFromSafeArea
        self.numberOfLines = numberOfLines
    }

    public func layout(for size: CGSize, safeAreaInsets: UIEdgeInsets) -> TextMessageLayout {
        let textInsets = self.textInsets(for: safeAreaInsets)
        let combinedInsets = safeAreaInsets + textInsets
        var sizeWithInset = size
        sizeWithInset.substract(insets: combinedInsets)

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
        let textSize = layoutManager.usedRect(for: textContainer).size.bma_round()
        var resultSize = textSize
        resultSize.add(insets: combinedInsets)

        return TextMessageLayout(
            frame: CGRect(
                origin: combinedInsets.origin,
                size: textSize
            ),
            size: resultSize,
            contentInsets: self.textInsets
        )
    }

    private func textInsets(for safeAreaInsets: UIEdgeInsets) -> UIEdgeInsets {
        guard let insetsFromSafeArea = self.textInsetsFromSafeArea else { return self.textInsets }
        var textInsets = self.textInsets
        if safeAreaInsets.top > 0 { textInsets.top = insetsFromSafeArea.top }
        if safeAreaInsets.left > 0 { textInsets.left = insetsFromSafeArea.left }
        if safeAreaInsets.right > 0 { textInsets.right = insetsFromSafeArea.right }
        if safeAreaInsets.bottom > 0 { textInsets.bottom = insetsFromSafeArea.bottom }
        return textInsets
    }
}

// MARK: - Image

public struct ImageMessageLayoutProvider: Hashable, MessageManualLayoutProviderProtocol {

    private let imageSize: CGSize

    public init(imageSize: CGSize) {
        self.imageSize = imageSize
    }

    public func layoutThatFits(size: CGSize, safeAreaInsets: UIEdgeInsets) -> LayoutInfo {
        let ratio = self.imageSize.width / self.imageSize.height
        let size = CGSize(width: size.width, height: size.width / ratio).bma_round()
        return LayoutInfo(size: size, contentInsets: .zero)
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

private extension UIEdgeInsets {

    var origin: CGPoint { CGPoint(x: self.left, y: self.top) }

    static func + (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: lhs.top + rhs.top,
            left: lhs.left + rhs.left,
            bottom: lhs.bottom + rhs.bottom,
            right: lhs.right + rhs.right
        )
    }
}
