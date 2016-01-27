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
import Chatto

public protocol BaseMessageCollectionViewCellStyleProtocol {
    var failedIcon: UIImage { get }
    var failedIconHighlighted: UIImage { get }
    func attributedStringForDate(date: String) -> NSAttributedString
}

public struct BaseMessageCollectionViewCellLayoutConstants {
    let horizontalMargin: CGFloat = 11
    let horizontalInterspacing: CGFloat = 4
    let maxContainerWidthPercentageForBubbleView: CGFloat = 0.68
}


/**
    Base class for message cells

    Provides:

        - Reveleable timestamp layout logic
        - Failed view
        - Incoming/outcoming layout

    Subclasses responsability
        - Implement createBubbleView
        - Have a BubbleViewType that responds properly to sizeThatFits:
*/

public class BaseMessageCollectionViewCell<BubbleViewType where BubbleViewType:UIView, BubbleViewType:MaximumLayoutWidthSpecificable, BubbleViewType: BackgroundSizingQueryable>: UICollectionViewCell, BackgroundSizingQueryable, AccessoryViewRevealable, UIGestureRecognizerDelegate {

    public var animationDuration: CFTimeInterval = 0.33
    public var viewContext: ViewContext = .Normal

    public private(set) var isUpdating: Bool = false
    public func performBatchUpdates(updateClosure: () -> Void, animated: Bool, completion: (() ->())?) {
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

    var messageViewModel: MessageViewModelProtocol! {
        didSet {
            updateViews()
        }
    }

    var failedIcon: UIImage!
    var failedIconHighlighted: UIImage!
    public var baseStyle: BaseMessageCollectionViewCellStyleProtocol! {
        didSet {
            self.failedIcon = self.baseStyle.failedIcon
            self.failedIconHighlighted = self.baseStyle.failedIconHighlighted
            self.updateViews()
        }
    }

    override public var selected: Bool {
        didSet {
            if oldValue != self.selected {
                self.updateViews()
            }
        }
    }

    var layoutConstants = BaseMessageCollectionViewCellLayoutConstants() {
        didSet {
            self.setNeedsLayout()
        }
    }

    public var canCalculateSizeInBackground: Bool {
        return self.bubbleView.canCalculateSizeInBackground
    }

    public private(set) var bubbleView: BubbleViewType!
    func createBubbleView() -> BubbleViewType! {
        assert(false, "Override in subclass")
        return nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    public private(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "bubbleTapped:")
        return tapGestureRecognizer
    }()

    public private (set) lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let longpressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "bubbleLongPressed:")
        longpressGestureRecognizer.delegate = self
        return longpressGestureRecognizer
    }()

    private func commonInit() {
        self.bubbleView = self.createBubbleView()
        self.bubbleView.addGestureRecognizer(self.tapGestureRecognizer)
        self.bubbleView.addGestureRecognizer(self.longPressGestureRecognizer)
        self.contentView.addSubview(self.bubbleView)
        self.contentView.addSubview(self.failedButton)
        self.contentView.exclusiveTouch = true
        self.exclusiveTouch = true
    }

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return self.bubbleView.bounds.contains(touch.locationInView(self.bubbleView))
    }

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === self.longPressGestureRecognizer
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        self.removeAccessoryView()
    }

    private lazy var failedButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.addTarget(self, action: "failedButtonTapped", forControlEvents: .TouchUpInside)
        return button
    }()

    // MARK: View model binding

    final private func updateViews() {
        if self.viewContext == .Sizing { return }
        if self.isUpdating { return }
        guard let viewModel = self.messageViewModel, style = self.baseStyle else { return }
        if viewModel.showsFailedIcon {
            self.failedButton.setImage(self.failedIcon, forState: .Normal)
            self.failedButton.setImage(self.failedIconHighlighted, forState: .Highlighted)
            self.failedButton.alpha = 1
        } else {
            self.failedButton.alpha = 0
        }
        self.accessoryTimestamp?.attributedText = style.attributedStringForDate(viewModel.date)
        self.setNeedsLayout()
    }

    // MARK: layout
    public override func layoutSubviews() {
        super.layoutSubviews()

        let layoutModel = self.calculateLayout(availableWidth: self.contentView.bounds.width)
        self.failedButton.bma_rect = layoutModel.failedViewFrame
        self.bubbleView.bma_rect = layoutModel.bubbleViewFrame
        self.bubbleView.preferredMaxLayoutWidth = layoutModel.preferredMaxWidthForBubble
        self.bubbleView.layoutIfNeeded()

        // TODO: refactor accessorView?

        if let accessoryView = self.accessoryTimestamp {
            accessoryView.bounds = CGRect(origin: CGPoint.zero, size: accessoryView.intrinsicContentSize())
            let accessoryViewWidth = CGRectGetWidth(accessoryView.bounds)
            let accessoryViewMargin: CGFloat = 10
            let leftDisplacement = max(0, min(self.timestampMaxVisibleOffset, accessoryViewWidth + accessoryViewMargin))
            var contentViewframe = self.contentView.frame
            if self.messageViewModel.isIncoming {
                contentViewframe.origin = CGPoint.zero
            } else {
                contentViewframe.origin.x = -leftDisplacement
            }
            self.contentView.frame = contentViewframe
            accessoryView.center = CGPoint(x: CGRectGetWidth(self.bounds) - leftDisplacement + accessoryViewWidth / 2, y: self.contentView.center.y)
        }
    }

    public override func sizeThatFits(size: CGSize) -> CGSize {
        return self.calculateLayout(availableWidth: size.width).size
    }

    private func calculateLayout(availableWidth availableWidth: CGFloat) -> BaseMessageLayoutModel {
        let parameters = BaseMessageLayoutModelParameters(
            containerWidth: availableWidth,
            horizontalMargin: self.layoutConstants.horizontalMargin,
            horizontalInterspacing: self.layoutConstants.horizontalInterspacing,
            failedButtonSize: self.failedIcon.size,
            maxContainerWidthPercentageForBubbleView: self.layoutConstants.maxContainerWidthPercentageForBubbleView,
            bubbleView: self.bubbleView,
            isIncoming: self.messageViewModel.isIncoming,
            isFailed: self.messageViewModel.showsFailedIcon
        )
        var layoutModel = BaseMessageLayoutModel()
        layoutModel.calculateLayout(parameters: parameters)
        return layoutModel
    }


    // MARK: timestamp revealing
    var timestampMaxVisibleOffset: CGFloat = 0 {
        didSet {
            self.setNeedsLayout()
        }
    }
    var accessoryTimestamp: UILabel?
    public func revealAccessoryView(maximumOffset offset: CGFloat, animated: Bool) {
        if self.accessoryTimestamp == nil {
            if offset > 0 {
                let accessoryTimestamp = UILabel()
                accessoryTimestamp.attributedText = self.baseStyle?.attributedStringForDate(self.messageViewModel.date)
                self.addSubview(accessoryTimestamp)
                self.accessoryTimestamp = accessoryTimestamp
                self.layoutIfNeeded()
            }

            if animated {
                UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in
                    self.timestampMaxVisibleOffset = offset
                    self.layoutIfNeeded()
                })
            } else {
                self.timestampMaxVisibleOffset = offset
            }
        } else {
            if animated {
                UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in
                    self.timestampMaxVisibleOffset = offset
                    self.layoutIfNeeded()
                    }, completion: { (finished) -> Void in
                        if offset == 0 {
                            self.removeAccessoryView()
                        }
                })

            } else {
                self.timestampMaxVisibleOffset = offset
            }
        }
    }

    func removeAccessoryView() {
        self.accessoryTimestamp?.removeFromSuperview()
        self.accessoryTimestamp = nil
    }


    // MARK: User interaction
    public var onFailedButtonTapped: ((cell: BaseMessageCollectionViewCell) -> Void)?
    @objc
    func failedButtonTapped() {
        self.onFailedButtonTapped?(cell: self)
    }

    public var onBubbleTapped: ((cell: BaseMessageCollectionViewCell) -> Void)?
    @objc
    func bubbleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        self.onBubbleTapped?(cell: self)
    }

    public var onBubbleLongPressed: ((cell: BaseMessageCollectionViewCell) -> Void)?
    @objc
    private func bubbleLongPressed(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == .Began {
            self.bubbleLongPressed()
        }
    }

    func bubbleLongPressed() {
        self.onBubbleLongPressed?(cell: self)
    }
}

struct BaseMessageLayoutModel {
    private (set) var size = CGSize.zero
    private (set) var failedViewFrame = CGRect.zero
    private (set) var bubbleViewFrame = CGRect.zero
    private (set) var preferredMaxWidthForBubble: CGFloat = 0

    mutating func calculateLayout(parameters parameters: BaseMessageLayoutModelParameters) {
        let containerWidth = parameters.containerWidth
        let isIncoming = parameters.isIncoming
        let isFailed = parameters.isFailed
        let failedButtonSize = parameters.failedButtonSize
        let bubbleView = parameters.bubbleView
        let horizontalMargin = parameters.horizontalMargin
        let horizontalInterspacing = parameters.horizontalInterspacing

        let preferredWidthForBubble = containerWidth * parameters.maxContainerWidthPercentageForBubbleView
        let bubbleSize = bubbleView.sizeThatFits(CGSize(width: preferredWidthForBubble, height: CGFloat.max))
        let containerRect = CGRect(origin: CGPoint.zero, size: CGSize(width: containerWidth, height: bubbleSize.height))


        self.bubbleViewFrame = bubbleSize.bma_rect(inContainer: containerRect, xAlignament: .Center, yAlignment: .Center, dx: 0, dy: 0)
        self.failedViewFrame = failedButtonSize.bma_rect(inContainer: containerRect, xAlignament: .Center, yAlignment: .Center, dx: 0, dy: 0)

        // Adjust horizontal positions

        var currentX: CGFloat = 0
        if isIncoming {
            currentX = horizontalMargin
            if isFailed {
                self.failedViewFrame.origin.x = currentX
                currentX += failedButtonSize.width
                currentX += horizontalInterspacing
            } else {
                self.failedViewFrame.origin.x = -failedButtonSize.width
            }
            self.bubbleViewFrame.origin.x = currentX
        } else {
            currentX = containerRect.maxX - horizontalMargin
            if isFailed {
                currentX -= failedButtonSize.width
                self.failedViewFrame.origin.x = currentX
                currentX -= horizontalInterspacing
            } else {
                self.failedViewFrame.origin.x = containerRect.width - -failedButtonSize.width
            }
            currentX -= bubbleSize.width
            self.bubbleViewFrame.origin.x = currentX
        }

        self.size = containerRect.size
        self.preferredMaxWidthForBubble = preferredWidthForBubble
    }
}

struct BaseMessageLayoutModelParameters {
    let containerWidth: CGFloat
    let horizontalMargin: CGFloat
    let horizontalInterspacing: CGFloat
    let failedButtonSize: CGSize
    let maxContainerWidthPercentageForBubbleView: CGFloat // in [0, 1]
    let bubbleView: UIView
    let isIncoming: Bool
    let isFailed: Bool
}
