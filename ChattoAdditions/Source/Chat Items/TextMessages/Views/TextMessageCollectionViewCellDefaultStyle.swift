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

public class TextMessageCollectionViewCellDefaultStyle: TextMessageCollectionViewCellStyleProtocol {

    public init () {}

    lazy var baseStyle = BaseMessageCollectionViewCellDefaultSyle()
    lazy var images: [String: UIImage] = {
        return [
            "incoming_tail" : UIImage(named: "bubble-incoming-tail", inBundle: NSBundle(forClass: TextMessageCollectionViewCellDefaultStyle.self), compatibleWithTraitCollection: nil)!,
            "incoming_notail" : UIImage(named: "bubble-incoming", inBundle: NSBundle(forClass: TextMessageCollectionViewCellDefaultStyle.self), compatibleWithTraitCollection: nil)!,
            "outgoing_tail" : UIImage(named: "bubble-outgoing-tail", inBundle: NSBundle(forClass: TextMessageCollectionViewCellDefaultStyle.self), compatibleWithTraitCollection: nil)!,
            "outgoing_notail" : UIImage(named: "bubble-outgoing", inBundle: NSBundle(forClass: TextMessageCollectionViewCellDefaultStyle.self), compatibleWithTraitCollection: nil)!,
        ]
    }()

    lazy var font = {
        return UIFont.systemFontOfSize(16)
    }()

    public func textFont(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIFont {
        return self.font
    }

    public func textColor(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIColor {
        return viewModel.isIncoming ? UIColor.blackColor() : UIColor.whiteColor()
    }

    public func textInsets(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIEdgeInsets {
        return viewModel.isIncoming ? UIEdgeInsets(top: 10, left: 19, bottom: 10, right: 15) : UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 19)
    }

    public func bubbleImageBorder(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage? {
        return self.baseStyle.borderImage(viewModel: viewModel)
    }

    public func bubbleImage(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage {
        let key = self.imageKey(isIncoming: viewModel.isIncoming, status: viewModel.status, showsTail: viewModel.showsTail, isSelected: isSelected)

        if let image = self.images[key] {
            return image
        } else {
            let templateKey = self.templateKey(isIncoming: viewModel.isIncoming, showsTail: viewModel.showsTail)
            if let image = self.images[templateKey] {
                let image = self.createImage(templateImage: image, isIncoming: viewModel.isIncoming, status: viewModel.status, isSelected: isSelected)
                self.images[key] = image
                return image
            }
        }

        assert(false, "coulnd't find image for this status. ImageKey: \(key)")
        return UIImage()
    }

    private func createImage(templateImage image: UIImage, isIncoming: Bool, status: MessageViewModelStatus, isSelected: Bool) -> UIImage {
        var color = isIncoming ? self.baseStyle.baseColorIncoming : self.baseStyle.baseColorOutgoing

        switch status {
        case .Success:
            break
        case .Failed, .Sending:
            color = color.bma_blendWithColor(UIColor.whiteColor().colorWithAlphaComponent(0.70))
        }

        if isSelected {
            color = color.bma_blendWithColor(UIColor.blackColor().colorWithAlphaComponent(0.10))
        }

        return image.bma_tintWithColor(color)
    }

    private func imageKey(isIncoming isIncoming: Bool, status: MessageViewModelStatus, showsTail: Bool, isSelected: Bool) -> String {
        let directionKey = isIncoming ? "incoming" : "outgoing"
        let tailKey = showsTail ? "tail" : "notail"
        let statusKey = self.statusKey(status)
        let highlightedKey = isSelected ? "highlighted" : "normal"
        let key = "\(directionKey)_\(tailKey)_\(statusKey)_\(highlightedKey)"
        return key
    }

    private func templateKey(isIncoming isIncoming: Bool, showsTail: Bool) -> String {
        let directionKey = isIncoming ? "incoming" : "outgoing"
        let tailKey = showsTail ? "tail" : "notail"
        return "\(directionKey)_\(tailKey)"
    }

    private func statusKey(status: MessageViewModelStatus) -> NSString {
        switch status {
        case .Success:
            return "ok"
        case .Sending:
            return "sending"
        case .Failed:
            return "failed"
        }
    }
}
