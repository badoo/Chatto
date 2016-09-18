/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit

open class TextMessageCollectionViewCellDefaultStyle: TextMessageCollectionViewCellStyleProtocol {
    typealias Class = TextMessageCollectionViewCellDefaultStyle

    public struct BubbleImages {
        let incomingTail: () -> UIImage
        let incomingNoTail: () -> UIImage
        let outgoingTail: () -> UIImage
        let outgoingNoTail: () -> UIImage
        public init(
            incomingTail: @autoclosure @escaping () -> UIImage,
            incomingNoTail: @autoclosure @escaping () -> UIImage,
            outgoingTail: @autoclosure @escaping () -> UIImage,
            outgoingNoTail: @autoclosure @escaping () -> UIImage) {
                self.incomingTail = incomingTail
                self.incomingNoTail = incomingNoTail
                self.outgoingTail = outgoingTail
                self.outgoingNoTail = outgoingNoTail
        }
    }

    public struct TextStyle {
        let font: () -> UIFont
        let incomingColor: () -> UIColor
        let outgoingColor: () -> UIColor
        let incomingInsets: UIEdgeInsets
        let outgoingInsets: UIEdgeInsets
        public init(
            font: @autoclosure @escaping () -> UIFont,
            incomingColor: @autoclosure @escaping () -> UIColor,
            outgoingColor: @autoclosure @escaping () -> UIColor,
            incomingInsets: UIEdgeInsets,
            outgoingInsets: UIEdgeInsets) {
                self.font = font
                self.incomingColor = incomingColor
                self.outgoingColor = outgoingColor
                self.incomingInsets = incomingInsets
                self.outgoingInsets = outgoingInsets
        }
    }


    public let bubbleImages: BubbleImages
    public let textStyle: TextStyle
    public let baseStyle: BaseMessageCollectionViewCellDefaultStyle
    public init (
        bubbleImages: BubbleImages = Class.createDefaultBubbleImages(),
        textStyle: TextStyle = Class.createDefaultTextStyle(),
        baseStyle: BaseMessageCollectionViewCellDefaultStyle = BaseMessageCollectionViewCellDefaultStyle()) {
            self.bubbleImages = bubbleImages
            self.textStyle = textStyle
            self.baseStyle = baseStyle
    }

    lazy private var images: [ImageKey: UIImage] = {
        return [
            .template(isIncoming: true, showsTail: true) : self.bubbleImages.incomingTail(),
            .template(isIncoming: true, showsTail: false) : self.bubbleImages.incomingNoTail(),
            .template(isIncoming: false, showsTail: true) : self.bubbleImages.outgoingTail(),
            .template(isIncoming: false, showsTail: false) : self.bubbleImages.outgoingNoTail()
        ]
    }()

    lazy var font: UIFont = self.textStyle.font()
    lazy var incomingColor: UIColor = self.textStyle.incomingColor()
    lazy var outgoingColor: UIColor = self.textStyle.outgoingColor()

    open func textFont(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIFont {
        return self.font
    }

    open func textColor(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIColor {
        return viewModel.isIncoming ? self.incomingColor : self.outgoingColor
    }

    open func textInsets(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIEdgeInsets {
        return viewModel.isIncoming ? self.textStyle.incomingInsets : self.textStyle.outgoingInsets
    }

    open func bubbleImageBorder(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage? {
        return self.baseStyle.borderImage(viewModel: viewModel)
    }

    open func bubbleImage(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage {
        let key = ImageKey.normal(isIncoming: viewModel.isIncoming, status: viewModel.status, showsTail: viewModel.showsTail, isSelected: isSelected)

        if let image = self.images[key] {
            return image
        } else {
            let templateKey = ImageKey.template(isIncoming: viewModel.isIncoming, showsTail: viewModel.showsTail)
            if let image = self.images[templateKey] {
                let image = self.createImage(templateImage: image, isIncoming: viewModel.isIncoming, status: viewModel.status, isSelected: isSelected)
                self.images[key] = image
                return image
            }
        }

        assert(false, "coulnd't find image for this status. ImageKey: \(key)")
        return UIImage()
    }

    open func createImage(templateImage image: UIImage, isIncoming: Bool, status: MessageViewModelStatus, isSelected: Bool) -> UIImage {
        var color = isIncoming ? self.baseStyle.baseColorIncoming : self.baseStyle.baseColorOutgoing

        switch status {
        case .success:
            break
        case .failed, .sending:
            color = color.bma_blendWithColor(UIColor.white.withAlphaComponent(0.70))
        }

        if isSelected {
            color = color.bma_blendWithColor(UIColor.black.withAlphaComponent(0.10))
        }

        return image.bma_tintWithColor(color)
    }

    private enum ImageKey: Hashable {
        case template(isIncoming: Bool, showsTail: Bool)
        case normal(isIncoming: Bool, status: MessageViewModelStatus, showsTail: Bool, isSelected: Bool)

        var hashValue: Int {
            switch self {
            case let .template(isIncoming: isIncoming, showsTail: showsTail):
                return self.calculateHash(withHashValues: [isIncoming.hashValue, showsTail.hashValue])
            case let .normal(isIncoming: isIncoming, status: status, showsTail: showsTail, isSelected: isSelected):
                return self.calculateHash(withHashValues: [isIncoming.hashValue, status.hashValue, showsTail.hashValue, isSelected.hashValue])
            }
        }

        private func calculateHash(withHashValues hashes: [Int]) -> Int {
            return hashes.reduce(0, { 31 &* $0 &+ $1.hashValue })
        }

        static func == (lhs: TextMessageCollectionViewCellDefaultStyle.ImageKey, rhs: TextMessageCollectionViewCellDefaultStyle.ImageKey) -> Bool {
            switch (lhs, rhs) {
            case let (.template(lhsValues), .template(rhsValues)):
                return lhsValues == rhsValues
            case let (.normal(lhsValues), .normal(rhsValues)):
                return lhsValues == rhsValues
            default:
                return false
            }
        }
    }
}

public extension TextMessageCollectionViewCellDefaultStyle { // Default values

    static public func createDefaultBubbleImages() -> BubbleImages {
        return BubbleImages(
            incomingTail: UIImage(named: "bubble-incoming-tail", in: Bundle(for: Class.self), compatibleWith: nil)!,
            incomingNoTail: UIImage(named: "bubble-incoming", in: Bundle(for: Class.self), compatibleWith: nil)!,
            outgoingTail: UIImage(named: "bubble-outgoing-tail", in: Bundle(for: Class.self), compatibleWith: nil)!,
            outgoingNoTail: UIImage(named: "bubble-outgoing", in: Bundle(for: Class.self), compatibleWith: nil)!
        )
    }

    static public func createDefaultTextStyle() -> TextStyle {
        return TextStyle(
            font: UIFont.systemFont(ofSize: 16),
            incomingColor: UIColor.black,
            outgoingColor: UIColor.white,
            incomingInsets: UIEdgeInsets(top: 10, left: 19, bottom: 10, right: 15),
            outgoingInsets: UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 19)
        )
    }
}
