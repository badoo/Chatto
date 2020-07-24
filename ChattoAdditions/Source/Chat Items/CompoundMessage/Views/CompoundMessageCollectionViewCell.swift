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

@available(iOS 11, *)
open class CompoundMessageCollectionViewCell: BaseMessageCollectionViewCell<CompoundBubbleView> {

    open override func createBubbleView() -> CompoundBubbleView! {
        return CompoundBubbleView()
    }

    public final var viewReferences: [ViewReference]?

    // MARK: - Decoration Views

    public typealias DecorationViewWithLayout = (UIView, MessageDecorationViewLayoutProviderProtocol)

    public var decorationViews: [DecorationViewWithLayout]? {
        didSet {
            for (view, _) in oldValue ?? [] {
                view.removeFromSuperview()
            }
            for (view, _) in self.decorationViews ?? [] {
                self.contentView.addSubview(view)
            }
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let bubbleView = self.bubbleView,
              let decorationViews = decorationViews else { return }
        for (view, layoutProvider) in decorationViews {
            var frame = layoutProvider.makeLayout(from: bubbleView.bounds).frame
            frame.origin = bubbleView.convert(frame.origin, to: self.contentView)
            CATransaction.performWithDisabledActions {
                view.frame = frame
            }
        }
    }
}
