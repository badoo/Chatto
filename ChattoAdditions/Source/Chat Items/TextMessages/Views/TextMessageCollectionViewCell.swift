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

public typealias TextMessageCollectionViewCellStyleProtocol = TextBubbleViewStyleProtocol

public final class TextMessageCollectionViewCell: BaseMessageCollectionViewCell<TextBubbleView> {

    public static func sizingCell() -> TextMessageCollectionViewCell {
        let cell = TextMessageCollectionViewCell(frame: CGRectZero)
        cell.viewContext = .Sizing
        return cell
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    // MARK: Subclassing (view creation)

    override func createBubbleView() -> TextBubbleView {
        return TextBubbleView()
    }

    public override func performBatchUpdates(updateClosure: () -> Void, animated: Bool, completion: (() -> Void)?) {
        super.performBatchUpdates({ () -> Void in
            self.bubbleView.performBatchUpdates(updateClosure, animated: false, completion: nil)
        }, animated: animated, completion: completion)
    }

    // MARK: Property forwarding

    override public var viewContext: ViewContext {
        didSet {
            self.bubbleView.viewContext = self.viewContext
        }
    }

    public var textMessageViewModel: TextMessageViewModelProtocol! {
        didSet {
            self.messageViewModel = self.textMessageViewModel
            self.bubbleView.textMessageViewModel = self.textMessageViewModel
        }
    }

    public var textMessageStyle: TextMessageCollectionViewCellStyleProtocol! {
        didSet {
            self.bubbleView.style = self.textMessageStyle
        }
    }

    override public var selected: Bool {
        didSet {
            self.bubbleView.selected = self.selected
        }
    }

    public var layoutCache: NSCache! {
        didSet {
            self.bubbleView.layoutCache = self.layoutCache
        }
    }
}
