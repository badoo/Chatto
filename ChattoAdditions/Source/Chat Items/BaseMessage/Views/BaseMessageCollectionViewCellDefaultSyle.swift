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

public class BaseMessageCollectionViewCellDefaultSyle: BaseMessageCollectionViewCellStyleProtocol {

    public init () {}

    lazy var baseColorIncoming = UIColor.bma_color(rgb: 0xE6ECF2)
    lazy var baseColorOutgoing = UIColor.bma_color(rgb: 0x3D68F5)

    lazy var borderIncomingTail: UIImage = {
        return UIImage(named: "bubble-incoming-border-tail", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
    }()

    lazy var borderIncomingNoTail: UIImage = {
        return UIImage(named: "bubble-incoming-border", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
    }()

    lazy var borderOutgoingTail: UIImage = {
        return UIImage(named: "bubble-outgoing-border-tail", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
    }()

    lazy var borderOutgoingNoTail: UIImage = {
        return UIImage(named: "bubble-outgoing-border", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
    }()

    public lazy var failedIcon: UIImage = {
        return UIImage(named: "base-message-failed-icon", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
    }()

    public lazy var failedIconHighlighted: UIImage = {
        return self.failedIcon.bma_blendWithColor(UIColor.blackColor().colorWithAlphaComponent(0.10))
    }()

    private lazy var dateFont = {
        return UIFont.systemFontOfSize(12.0)
    }()

    public func attributedStringForDate(date: String) -> NSAttributedString {
        let attributes = [NSFontAttributeName : self.dateFont]
        return NSAttributedString(string: date, attributes: attributes)
    }

    func borderImage(viewModel viewModel: MessageViewModelProtocol) -> UIImage? {
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
}
