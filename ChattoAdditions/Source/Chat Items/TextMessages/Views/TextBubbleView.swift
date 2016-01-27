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

public protocol TextBubbleViewStyleProtocol {
    func bubbleImage(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage
    func bubbleImageBorder(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage?
    func textFont(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIFont
    func textColor(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIColor
    func textInsets(viewModel viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIEdgeInsets
}

public final class TextBubbleView: UIView, MaximumLayoutWidthSpecificable, BackgroundSizingQueryable {

    public var preferredMaxLayoutWidth: CGFloat = 0
    public var animationDuration: CFTimeInterval = 0.33
    public var viewContext: ViewContext = .Normal {
        didSet {
            if self.viewContext == .Sizing {
                self.textView.dataDetectorTypes = .None
                self.textView.selectable = false
            } else {
                self.textView.dataDetectorTypes = .All
                self.textView.selectable = true
            }
        }
    }

    public var style: TextBubbleViewStyleProtocol! {
        didSet {
            self.updateViews()
        }
    }

    public var textMessageViewModel: TextMessageViewModelProtocol! {
        didSet {
            self.updateViews()
        }
    }

    public var selected: Bool = false {
        didSet {
            self.updateViews()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        self.addSubview(self.bubbleImageView)
        self.addSubview(self.textView)
    }

    private lazy var bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.addSubview(self.borderImageView)
        return imageView
    }()

    private var borderImageView: UIImageView = UIImageView()
    private var textView: UITextView = {
        let textView = ChatMessageTextView()
        textView.backgroundColor = UIColor.clearColor()
        textView.editable = false
        textView.selectable = true
        textView.dataDetectorTypes = .All
        textView.scrollsToTop = false
        textView.scrollEnabled = false
        textView.bounces = false
        textView.bouncesZoom = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.layoutManager.allowsNonContiguousLayout = true
        textView.exclusiveTouch = true
        textView.textContainerInset = UIEdgeInsetsZero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    public private(set) var isUpdating: Bool = false
    public func performBatchUpdates(updateClosure: () -> Void, animated: Bool, completion: (() -> Void)?) {
        self.isUpdating = true
        let updateAndRefreshViews = {
            updateClosure()
            self.isUpdating = false
            self.updateViews()
            if animated {
                self.layoutIfNeeded()
            }
        }
        if animated {
            UIView.animateWithDuration(self.animationDuration, animations: updateAndRefreshViews, completion: { (finished) -> Void in
                completion?()
            })
        } else {
            updateAndRefreshViews()
        }
    }

    private func updateViews() {
        if self.viewContext == .Sizing { return }
        if isUpdating { return }
        guard let style = self.style, viewModel = self.textMessageViewModel else { return }
        let font = style.textFont(viewModel: viewModel, isSelected: self.selected)
        let textColor = style.textColor(viewModel: viewModel, isSelected: self.selected)
        let bubbleImage = self.style.bubbleImage(viewModel: self.textMessageViewModel, isSelected: self.selected)
        let borderImage = self.style.bubbleImageBorder(viewModel: self.textMessageViewModel, isSelected: self.selected)

        if self.textView.font != font { self.textView.font = font}
        if self.textView.text != viewModel.text {self.textView.text = viewModel.text}
        if self.textView.textColor != textColor {
            self.textView.textColor = textColor
            self.textView.linkTextAttributes = [
                NSForegroundColorAttributeName: textColor,
                NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue
            ]
        }
        if self.bubbleImageView.image != bubbleImage { self.bubbleImageView.image = bubbleImage}
        if self.borderImageView.image != borderImage { self.borderImageView.image = borderImage }
    }

    private func bubbleImage() -> UIImage {
        return self.style.bubbleImage(viewModel: self.textMessageViewModel, isSelected: self.selected)
    }

    public override func sizeThatFits(size: CGSize) -> CGSize {
        return self.calculateTextBubbleLayout(preferredMaxLayoutWidth: size.width).size
    }

    // MARK:  Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        let layout = self.calculateTextBubbleLayout(preferredMaxLayoutWidth: self.preferredMaxLayoutWidth)
        self.textView.bma_rect = layout.textFrame
        self.bubbleImageView.bma_rect = layout.bubbleFrame
        self.borderImageView.bma_rect = self.bubbleImageView.bounds
    }

    public var layoutCache: NSCache!
    private func calculateTextBubbleLayout(preferredMaxLayoutWidth preferredMaxLayoutWidth: CGFloat) -> TextBubbleLayoutModel {
        let layoutContext = TextBubbleLayoutModel.LayoutContext(
            text: self.textMessageViewModel.text,
            font: self.style.textFont(viewModel: self.textMessageViewModel, isSelected: self.selected),
            textInsets: self.style.textInsets(viewModel: self.textMessageViewModel, isSelected: self.selected),
            preferredMaxLayoutWidth: preferredMaxLayoutWidth
        )

        if let layoutModel = self.layoutCache.objectForKey(layoutContext.hashValue) as? TextBubbleLayoutModel where layoutModel.layoutContext == layoutContext {
            return layoutModel
        }

        let layoutModel = TextBubbleLayoutModel(layoutContext: layoutContext)
        layoutModel.calculateLayout()

        self.layoutCache.setObject(layoutModel, forKey: layoutContext.hashValue)
        return layoutModel
    }

    public var canCalculateSizeInBackground: Bool {
        return true
    }
}


private final class TextBubbleLayoutModel {
    let layoutContext: LayoutContext
    var textFrame: CGRect = CGRect.zero
    var bubbleFrame: CGRect = CGRect.zero
    var size: CGSize = CGSize.zero

    init(layoutContext: LayoutContext) {
        self.layoutContext = layoutContext
    }

    class LayoutContext: Equatable, Hashable {
        let text: String
        let font: UIFont
        let textInsets: UIEdgeInsets
        let preferredMaxLayoutWidth: CGFloat
        init (text: String, font: UIFont, textInsets: UIEdgeInsets, preferredMaxLayoutWidth: CGFloat) {
            self.font = font
            self.text = text
            self.textInsets = textInsets
            self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        }

        var hashValue: Int {
            get {
                return self.text.hashValue ^ self.textInsets.bma_hashValue ^ self.preferredMaxLayoutWidth.hashValue ^ self.font.hashValue
            }
        }
    }

    func calculateLayout() {
        let textHorizontalInset = self.layoutContext.textInsets.bma_horziontalInset
        let maxTextWidth = self.layoutContext.preferredMaxLayoutWidth - textHorizontalInset
        let textSize = self.textSizeThatFitsWidth(maxTextWidth)
        let bubbleSize = textSize.bma_outsetBy(dx: textHorizontalInset, dy: self.layoutContext.textInsets.bma_verticalInset)
        self.bubbleFrame = CGRect(origin: CGPoint.zero, size: bubbleSize)
        self.textFrame = UIEdgeInsetsInsetRect(self.bubbleFrame, self.layoutContext.textInsets)
        self.size = bubbleSize
    }

    private func textSizeThatFitsWidth(width: CGFloat) -> CGSize {
        return self.layoutContext.text.boundingRectWithSize(
            CGSize(width: width, height: CGFloat.max),
            options: [.UsesLineFragmentOrigin, .UsesFontLeading],
            attributes: [NSFontAttributeName: self.layoutContext.font], context:  nil
        ).size.bma_round()
    }
}

private func == (lhs: TextBubbleLayoutModel.LayoutContext, rhs: TextBubbleLayoutModel.LayoutContext) -> Bool {
    return lhs.text == rhs.text &&
        lhs.textInsets == rhs.textInsets &&
        lhs.font == rhs.font &&
        lhs.preferredMaxLayoutWidth == rhs.preferredMaxLayoutWidth
}


/// UITextView with hacks to avoid selection, loupe, define...
private final class ChatMessageTextView: UITextView {

    override func canBecomeFirstResponder() -> Bool {
        return false
    }

    override func addGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.dynamicType == UILongPressGestureRecognizer.self && gestureRecognizer.delaysTouchesEnded {
            super.addGestureRecognizer(gestureRecognizer)
        }
    }

    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        return false
    }
}
