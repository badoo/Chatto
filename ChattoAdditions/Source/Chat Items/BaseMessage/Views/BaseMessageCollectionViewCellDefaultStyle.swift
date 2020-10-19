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

    public struct SelectionIndicatorStyle {
        let margins: UIEdgeInsets
        let selectedIcon: () -> UIImage
        let deselectedIcon: () -> UIImage
        public init(margins: UIEdgeInsets,
                    selectedIcon: @autoclosure @escaping () -> UIImage,
                    deselectedIcon: @autoclosure @escaping () -> UIImage) {
            self.margins = margins
            self.selectedIcon = selectedIcon
            self.deselectedIcon = deselectedIcon
        }
    }

    let colors: Colors
    let bubbleBorderImages: BubbleBorderImages?
    let failedIconImages: FailedIconImages
    let layoutConstants: BaseMessageCollectionViewCellLayoutConstants
    let dateTextStyle: DateTextStyle
    let incomingAvatarStyle: AvatarStyle
    let outgoingAvatarStyle: AvatarStyle
    let selectionIndicatorStyle: SelectionIndicatorStyle

    public init(
        colors: Colors = BaseMessageCollectionViewCellDefaultStyle.createDefaultColors(),
        bubbleBorderImages: BubbleBorderImages? = BaseMessageCollectionViewCellDefaultStyle.createDefaultBubbleBorderImages(),
        failedIconImages: FailedIconImages = BaseMessageCollectionViewCellDefaultStyle.createDefaultFailedIconImages(),
        layoutConstants: BaseMessageCollectionViewCellLayoutConstants = BaseMessageCollectionViewCellDefaultStyle.createDefaultLayoutConstants(),
        dateTextStyle: DateTextStyle = BaseMessageCollectionViewCellDefaultStyle.createDefaultDateTextStyle(),
        incomingAvatarStyle: AvatarStyle = AvatarStyle(),
        outgoingAvatarStyle: AvatarStyle = AvatarStyle(),
        selectionIndicatorStyle: SelectionIndicatorStyle = BaseMessageCollectionViewCellDefaultStyle.createDefaultSelectionIndicatorStyle(),
        replyIndicatorStyle: ReplyIndicatorStyle? = nil
    ) {
        self.colors = colors
        self.bubbleBorderImages = bubbleBorderImages
        self.failedIconImages = failedIconImages
        self.layoutConstants = layoutConstants
        self.dateTextStyle = dateTextStyle
        self.incomingAvatarStyle = incomingAvatarStyle
        self.outgoingAvatarStyle = outgoingAvatarStyle
        self.selectionIndicatorStyle = selectionIndicatorStyle
        self.replyIndicatorStyle = replyIndicatorStyle

        self.dateStringAttributes = [
            NSAttributedString.Key.font: self.dateTextStyle.font(),
            NSAttributedString.Key.foregroundColor: self.dateTextStyle.color()
        ]
    }

    public lazy var baseColorIncoming: UIColor = self.colors.incoming()
    public lazy var baseColorOutgoing: UIColor = self.colors.outgoing()

    public lazy var borderIncomingTail: UIImage? = self.bubbleBorderImages?.borderIncomingTail()
    public lazy var borderIncomingNoTail: UIImage? = self.bubbleBorderImages?.borderIncomingNoTail()
    public lazy var borderOutgoingTail: UIImage? = self.bubbleBorderImages?.borderOutgoingTail()
    public lazy var borderOutgoingNoTail: UIImage? = self.bubbleBorderImages?.borderOutgoingNoTail()

    public lazy var failedIcon: UIImage = self.failedIconImages.normal()
    public lazy var failedIconHighlighted: UIImage = self.failedIconImages.highlighted()
    public let replyIndicatorStyle: ReplyIndicatorStyle?

    private let dateStringAttributes: [NSAttributedString.Key: AnyObject]

    open func attributedStringForDate(_ date: String) -> NSAttributedString {
        return NSAttributedString(string: date, attributes: self.dateStringAttributes)
    }

    open func borderImage(viewModel: MessageViewModelProtocol) -> UIImage? {
        switch (viewModel.isIncoming, viewModel.decorationAttributes.isShowingTail) {
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
        return self.avatarStyle(for: viewModel).size
    }

    open func avatarVerticalAlignment(viewModel: MessageViewModelProtocol) -> VerticalAlignment {
        return self.avatarStyle(for: viewModel).alignment
    }

    public var selectionIndicatorMargins: UIEdgeInsets {
        return self.selectionIndicatorStyle.margins
    }

    public func selectionIndicatorIcon(for viewModel: MessageViewModelProtocol) -> UIImage {
        return viewModel.decorationAttributes.isSelected ? self.selectionIndicatorStyle.selectedIcon() : self.selectionIndicatorStyle.deselectedIcon()
    }

    open func layoutConstants(viewModel: MessageViewModelProtocol) -> BaseMessageCollectionViewCellLayoutConstants {
        return self.layoutConstants
    }

    private func avatarStyle(for viewModel: MessageViewModelProtocol) -> AvatarStyle {
        return viewModel.isIncoming ? self.incomingAvatarStyle : self.outgoingAvatarStyle
    }
}

public extension BaseMessageCollectionViewCellDefaultStyle { // Default values

    private static let defaultIncomingColor = UIColor.bma_color(rgb: 0xE6ECF2)
    private static let defaultOutgoingColor = UIColor.bma_color(rgb: 0x3D68F5)

    static func createDefaultColors() -> Colors {
        return Colors(incoming: self.defaultIncomingColor, outgoing: self.defaultOutgoingColor)
    }

    static func createDefaultBubbleBorderImages() -> BubbleBorderImages {
        return BubbleBorderImages(
            borderIncomingTail: UIImage(named: "bubble-incoming-border-tail", in: Bundle.resources, compatibleWith: nil)!,
            borderIncomingNoTail: UIImage(named: "bubble-incoming-border", in: Bundle.resources, compatibleWith: nil)!,
            borderOutgoingTail: UIImage(named: "bubble-outgoing-border-tail", in: Bundle.resources, compatibleWith: nil)!,
            borderOutgoingNoTail: UIImage(named: "bubble-outgoing-border", in: Bundle.resources, compatibleWith: nil)!
        )
    }

    static func createDefaultFailedIconImages() -> FailedIconImages {
        let normal = {
            return UIImage(named: "base-message-failed-icon", in: Bundle.resources, compatibleWith: nil)!
        }
        return FailedIconImages(
            normal: normal(),
            highlighted: normal().bma_blendWithColor(UIColor.black.withAlphaComponent(0.10))
        )
    }

    static func createDefaultDateTextStyle() -> DateTextStyle {
        return DateTextStyle(font: UIFont.systemFont(ofSize: 12), color: UIColor.bma_color(rgb: 0x9aa3ab))
    }

    static func createDefaultLayoutConstants() -> BaseMessageCollectionViewCellLayoutConstants {
        return BaseMessageCollectionViewCellLayoutConstants(horizontalMargin: 11,
                                                            horizontalInterspacing: 4,
                                                            horizontalTimestampMargin: 11,
                                                            maxContainerWidthPercentageForBubbleView: 0.68)
    }

    private static let selectionIndicatorIconSelected = UIImage(named: "base-message-checked-icon", in: Bundle.resources, compatibleWith: nil)!.bma_tintWithColor(BaseMessageCollectionViewCellDefaultStyle.defaultOutgoingColor)
    private static let selectionIndicatorIconDeselected = UIImage(named: "base-message-unchecked-icon", in: Bundle.resources, compatibleWith: nil)!.bma_tintWithColor(UIColor.bma_color(rgb: 0xC6C6C6))

    static func createDefaultSelectionIndicatorStyle() -> SelectionIndicatorStyle {
        return SelectionIndicatorStyle(
            margins: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10),
            selectedIcon: self.selectionIndicatorIconSelected,
            deselectedIcon: self.selectionIndicatorIconDeselected
        )
    }
}
