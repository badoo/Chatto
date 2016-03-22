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

public class PhotoMessageCollectionViewCellDefaultStyle: PhotoMessageCollectionViewCellStyleProtocol {
    typealias Class = PhotoMessageCollectionViewCellDefaultStyle

    public struct BubbleMasks {
        let incomingTail: () -> UIImage
        let incomingNoTail: () -> UIImage
        let outgoingTail: () -> UIImage
        let outgoingNoTail: () -> UIImage
        let tailWidth: CGFloat
        public init(
            @autoclosure(escaping) incomingTail: () -> UIImage,
            @autoclosure(escaping) incomingNoTail: () -> UIImage,
            @autoclosure(escaping) outgoingTail: () -> UIImage,
            @autoclosure(escaping) outgoingNoTail: () -> UIImage,
            tailWidth: CGFloat) {
                self.incomingTail = incomingTail
                self.incomingNoTail = incomingNoTail
                self.outgoingTail = outgoingTail
                self.outgoingNoTail = outgoingNoTail
                self.tailWidth = tailWidth
        }
    }

    public struct Sizes {
        public let aspectRatioIntervalForSquaredSize: ClosedInterval<CGFloat>
        public let photoSizeLandscape: CGSize
        public let photoSizePortratit: CGSize
        public let photoSizeSquare: CGSize
    }

    public struct Colors {
        public let placeholderIconTintIncoming: UIColor
        public let placeholderIconTintOutgoing: UIColor
        public let progressIndicatorColorIncoming: UIColor
        public let progressIndicatorColorOutgoing: UIColor
        public let overlayColor: UIColor
    }

    let bubbleMasks: BubbleMasks
    let sizes: Sizes
    let colors: Colors
    let baseStyle: BaseMessageCollectionViewCellDefaultStyle
    public init(
        bubbleMasks: BubbleMasks = Class.createDefaultBubbleMasks(),
        sizes: Sizes = Class.createDefaultSizes(),
        colors: Colors = Class.createDefaultColors(),
        baseStyle: BaseMessageCollectionViewCellDefaultStyle = BaseMessageCollectionViewCellDefaultStyle()) {
            self.bubbleMasks = bubbleMasks
            self.sizes = sizes
            self.colors = colors
            self.baseStyle = baseStyle
    }

    lazy private var maskImageIncomingTail: UIImage = self.bubbleMasks.incomingTail()
    lazy private var maskImageIncomingNoTail: UIImage = self.bubbleMasks.incomingNoTail()
    lazy private var maskImageOutgoingTail: UIImage = self.bubbleMasks.outgoingTail()
    lazy private var maskImageOutgoingNoTail: UIImage = self.bubbleMasks.outgoingNoTail()

    lazy private var placeholderBackgroundIncoming: UIImage = {
        return UIImage.bma_imageWithColor(self.baseStyle.baseColorIncoming, size: CGSize(width: 1, height: 1))
    }()

    lazy private var placeholderBackgroundOutgoing: UIImage = {
        return UIImage.bma_imageWithColor(self.baseStyle.baseColorOutgoing, size: CGSize(width: 1, height: 1))
    }()

    lazy private var placeholderIcon: UIImage = {
        return UIImage(named: "photo-bubble-placeholder-icon", inBundle: NSBundle(forClass: Class.self), compatibleWithTraitCollection: nil)!
    }()

    public func maskingImage(viewModel viewModel: PhotoMessageViewModelProtocol) -> UIImage {
        switch (viewModel.isIncoming, viewModel.showsTail) {
        case (true, true):
            return self.maskImageIncomingTail
        case (true, false):
            return self.maskImageIncomingNoTail
        case (false, true):
            return self.maskImageOutgoingTail
        case (false, false):
            return self.maskImageOutgoingNoTail
        }
    }

    public func borderImage(viewModel viewModel: PhotoMessageViewModelProtocol) -> UIImage? {
        return self.baseStyle.borderImage(viewModel: viewModel)
    }

    public func placeholderBackgroundImage(viewModel viewModel: PhotoMessageViewModelProtocol) -> UIImage {
        return viewModel.isIncoming ? self.placeholderBackgroundIncoming : self.placeholderBackgroundOutgoing
    }

    public func placeholderIconImage(viewModel viewModel: PhotoMessageViewModelProtocol) -> (icon: UIImage?, tintColor: UIColor?) {
        if viewModel.image.value == nil && viewModel.transferStatus.value == .Failed {
            let tintColor = viewModel.isIncoming ? self.colors.placeholderIconTintIncoming : self.colors.placeholderIconTintOutgoing
            return (self.placeholderIcon, tintColor)
        }
        return (nil, nil)
    }

    public func tailWidth(viewModel viewModel: PhotoMessageViewModelProtocol) -> CGFloat {
        return self.bubbleMasks.tailWidth
    }

    public func bubbleSize(viewModel viewModel: PhotoMessageViewModelProtocol) -> CGSize {
        let aspectRatio = viewModel.imageSize.height > 0 ? viewModel.imageSize.width / viewModel.imageSize.height : 0

        if aspectRatio == 0 || self.sizes.aspectRatioIntervalForSquaredSize.contains(aspectRatio) {
            return self.sizes.photoSizeSquare
        } else if aspectRatio < self.sizes.aspectRatioIntervalForSquaredSize.start {
            return self.sizes.photoSizePortratit
        } else {
            return self.sizes.photoSizeLandscape
        }
    }

    public func progressIndicatorColor(viewModel viewModel: PhotoMessageViewModelProtocol) -> UIColor {
        return viewModel.isIncoming ? self.colors.progressIndicatorColorIncoming : self.colors.progressIndicatorColorOutgoing
    }

    public func overlayColor(viewModel viewModel: PhotoMessageViewModelProtocol) -> UIColor? {
        let showsOverlay = viewModel.image.value != nil && (viewModel.transferStatus.value == .Transfering || viewModel.status != MessageViewModelStatus.Success)
        return showsOverlay ? self.colors.overlayColor : nil
    }

}

public extension PhotoMessageCollectionViewCellDefaultStyle { // Default values

    static public func createDefaultBubbleMasks() -> BubbleMasks {
        return BubbleMasks(
            incomingTail: UIImage(named: "bubble-incoming-tail", inBundle: NSBundle(forClass: Class.self), compatibleWithTraitCollection: nil)!,
            incomingNoTail: UIImage(named: "bubble-incoming", inBundle: NSBundle(forClass: Class.self), compatibleWithTraitCollection: nil)!,
            outgoingTail: UIImage(named: "bubble-outgoing-tail", inBundle: NSBundle(forClass: Class.self), compatibleWithTraitCollection: nil)!,
            outgoingNoTail: UIImage(named: "bubble-outgoing", inBundle: NSBundle(forClass: Class.self), compatibleWithTraitCollection: nil)!,
            tailWidth: 6
        )
    }

    static public func createDefaultSizes() -> Sizes {
        return Sizes(
            aspectRatioIntervalForSquaredSize: 0.90...1.10,
            photoSizeLandscape: CGSize(width: 210, height: 136),
            photoSizePortratit: CGSize(width: 136, height: 210),
            photoSizeSquare: CGSize(width: 210, height: 210)
        )
    }

    static public func createDefaultColors() -> Colors {
        return Colors(
            placeholderIconTintIncoming: UIColor.bma_color(rgb: 0xced6dc),
            placeholderIconTintOutgoing: UIColor.bma_color(rgb: 0x508dfc),
            progressIndicatorColorIncoming: UIColor.bma_color(rgb: 0x98a3ab),
            progressIndicatorColorOutgoing: UIColor.whiteColor(),
            overlayColor: UIColor.blackColor().colorWithAlphaComponent(0.70)
        )
    }
}
