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

open class BaseMessageCollectionViewCellDefaultStyle: BaseMessageCollectionViewCellStyleProtocol {

    typealias Class = BaseMessageCollectionViewCellDefaultStyle

    public struct Colors {
        let incoming: () -> UIColor
        let outgoing: () -> UIColor
        public init(
            incoming: @autoclosure @escaping () -> UIColor,
            outgoing: @autoclosure @escaping () -> UIColor) {
                self.incoming = incoming
                self.outgoing = outgoing
        }
    }

    public struct BubbleBorderImages {
        public let borderIncomingTail: () -> UIImage
        public let borderIncomingNoTail: () -> UIImage
        public let borderOutgoingTail: () -> UIImage
        public let borderOutgoingNoTail: () -> UIImage
        public init(
            borderIncomingTail: @autoclosure @escaping () -> UIImage,
            borderIncomingNoTail: @autoclosure @escaping () -> UIImage,
            borderOutgoingTail: @autoclosure @escaping () -> UIImage,
            borderOutgoingNoTail: @autoclosure @escaping () -> UIImage) {
                self.borderIncomingTail = borderIncomingTail
                self.borderIncomingNoTail = borderIncomingNoTail
                self.borderOutgoingTail = borderOutgoingTail
                self.borderOutgoingNoTail = borderOutgoingNoTail
        }
    }

    public struct FailedIconImages {
        let normal: () -> UIImage
        let highlighted: () -> UIImage
        public init(
            normal: @autoclosure @escaping () -> UIImage,
            highlighted: @autoclosure @escaping () -> UIImage) {
                self.normal = normal
                self.highlighted = highlighted
        }
    }

    public struct DateTextStyle {
        let font: () -> UIFont
        let color: () -> UIColor
        public init(
            font: @autoclosure @escaping () -> UIFont,
            color: @autoclosure @escaping () -> UIColor) {
                self.font = font
                self.color = color
        }
    }

    public struct AvatarStyle {
        let size: CGSize
        let alignment: VerticalAlignment
        public init(size: CGSize = .zero, alignment: VerticalAlignment = .bottom) {
            self.size = size
            self.alignment = alignment
        }
    }

    let colors: Colors
    let bubbleBorderImages: BubbleBorderImages?
    let failedIconImages: FailedIconImages
    let layoutConstants: BaseMessageCollectionViewCellLayoutConstants
    let dateTextStyle: DateTextStyle
    let avatarStyle: AvatarStyle
    public init (
        colors: Colors = Class.createDefaultColors(),
        bubbleBorderImages: BubbleBorderImages? = Class.createDefaultBubbleBorderImages(),
        failedIconImages: FailedIconImages = Class.createDefaultFailedIconImages(),
        layoutConstants: BaseMessageCollectionViewCellLayoutConstants = Class.createDefaultLayoutConstants(),
        dateTextStyle: DateTextStyle = Class.createDefaultDateTextStyle(),
        avatarStyle: AvatarStyle = AvatarStyle()) {
            self.colors = colors
            self.bubbleBorderImages = bubbleBorderImages
            self.failedIconImages = failedIconImages
            self.layoutConstants = layoutConstants
            self.dateTextStyle = dateTextStyle
            self.avatarStyle = avatarStyle
    }

    public lazy var baseColorIncoming: UIColor = self.colors.incoming()
    public lazy var baseColorOutgoing: UIColor = self.colors.outgoing()

    public lazy var borderIncomingTail: UIImage? = self.bubbleBorderImages?.borderIncomingTail()
    public lazy var borderIncomingNoTail: UIImage? = self.bubbleBorderImages?.borderIncomingNoTail()
    public lazy var borderOutgoingTail: UIImage? = self.bubbleBorderImages?.borderOutgoingTail()
    public lazy var borderOutgoingNoTail: UIImage? = self.bubbleBorderImages?.borderOutgoingNoTail()

    public lazy var failedIcon: UIImage = self.failedIconImages.normal()
    public lazy var failedIconHighlighted: UIImage = self.failedIconImages.highlighted()
    private lazy var dateFont: UIFont = self.dateTextStyle.font()
    private lazy var dateFontColor: UIColor = self.dateTextStyle.color()

    private lazy var dateStringAttributes: [String : AnyObject] = {
        return [
            NSFontAttributeName : self.dateFont,
            NSForegroundColorAttributeName: self.dateFontColor
        ]
    }()

    open func attributedStringForDate(_ date: String) -> NSAttributedString {
        return NSAttributedString(string: date, attributes: self.dateStringAttributes)
    }

    open func borderImage(viewModel: MessageViewModelProtocol) -> UIImage? {
        switch (viewModel.isIncoming, viewModel.showsTail) {
        case (true, true):
            return self.borderIncomingTail
        case (true, false):
            return self.borderIncomingNoTail
        case (false, true):
            return self.borderOutgoingTail
        case (false, false):
            return self.borderOutgoingNoTail
        }
    }

    open func avatarSize(viewModel: MessageViewModelProtocol) -> CGSize {
        return self.avatarStyle.size
    }

    open func avatarVerticalAlignment(viewModel: MessageViewModelProtocol) -> VerticalAlignment {
        return self.avatarStyle.alignment
    }

    open func layoutConstants(viewModel: MessageViewModelProtocol) -> BaseMessageCollectionViewCellLayoutConstants {
        return self.layoutConstants
    }
}

public extension BaseMessageCollectionViewCellDefaultStyle { // Default values
    static public func createDefaultColors() -> Colors {
        return Colors(incoming: UIColor.bma_color(rgb: 0xE6ECF2), outgoing: UIColor.bma_color(rgb: 0x3D68F5))
    }

    static public func createDefaultBubbleBorderImages() -> BubbleBorderImages {
        return BubbleBorderImages(
            borderIncomingTail: UIImage(named: "bubble-incoming-border-tail", in: Bundle(for: Class.self), compatibleWith: nil)!,
            borderIncomingNoTail: UIImage(named: "bubble-incoming-border", in: Bundle(for: Class.self), compatibleWith: nil)!,
            borderOutgoingTail: UIImage(named: "bubble-outgoing-border-tail", in: Bundle(for: Class.self), compatibleWith: nil)!,
            borderOutgoingNoTail: UIImage(named: "bubble-outgoing-border", in: Bundle(for: Class.self), compatibleWith: nil)!
        )
    }

    static public func createDefaultFailedIconImages() -> FailedIconImages {
        let normal = {
            return UIImage(named: "base-message-failed-icon", in: Bundle(for: Class.self), compatibleWith: nil)!
        }
        return FailedIconImages(
            normal: normal(),
            highlighted: normal().bma_blendWithColor(UIColor.black.withAlphaComponent(0.10))
        )
    }

    static public func createDefaultDateTextStyle() -> DateTextStyle {
        return DateTextStyle(font: UIFont.systemFont(ofSize: 12), color: UIColor.bma_color(rgb: 0x9aa3ab))
    }

    static public func createDefaultLayoutConstants() -> BaseMessageCollectionViewCellLayoutConstants {
        return BaseMessageCollectionViewCellLayoutConstants(horizontalMargin: 11,
                                                            horizontalInterspacing: 4,
                                                            horizontalTimestampMargin: 11,
                                                            maxContainerWidthPercentageForBubbleView: 0.68)
    }
}
