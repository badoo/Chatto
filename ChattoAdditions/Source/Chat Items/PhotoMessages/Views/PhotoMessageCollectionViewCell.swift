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

public typealias PhotoMessageCollectionViewCellStyleProtocol = PhotoBubbleViewStyleProtocol

public final class PhotoMessageCollectionViewCell: BaseMessageCollectionViewCell<PhotoBubbleView> {

    static func sizingCell() -> PhotoMessageCollectionViewCell {
        let cell = PhotoMessageCollectionViewCell(frame: CGRectZero)
        cell.viewContext = .Sizing
        return cell
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func createBubbleView() -> PhotoBubbleView {
        return PhotoBubbleView()
    }

    override public var viewContext: ViewContext {
        didSet {
            self.bubbleView.viewContext = self.viewContext
        }
    }

    var photoMessageViewModel: PhotoMessageViewModelProtocol! {
        didSet {
            self.messageViewModel = self.photoMessageViewModel
            self.bubbleView.photoMessageViewModel = self.photoMessageViewModel
        }
    }

    public var photoMessageStyle: PhotoMessageCollectionViewCellStyleProtocol! {
        didSet {
            self.bubbleView.photoMessageStyle = self.photoMessageStyle
        }
    }

    public override func performBatchUpdates(updateClosure: () -> Void, animated: Bool, completion: (() -> Void)?) {
        super.performBatchUpdates({ () -> Void in
            self.bubbleView.performBatchUpdates(updateClosure, animated: false, completion: nil)
        }, animated: animated, completion: completion)
    }
}
