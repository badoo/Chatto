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
public final class CompoundBubbleView: UIView, MaximumLayoutWidthSpecificable, BackgroundSizingQueryable {

    // MARK: - Type declarations

    public struct DecoratedView {
        let view: UIView
        let showBorder: Bool
        public init(view: UIView, showBorder: Bool) {
            self.view = view
            self.showBorder = showBorder
        }
    }

    // MARK: - Private properties

    private let borderImageView = UIImageView()
    private let borderMaskLayer = CALayer()

    // MARK: - Instantiation

    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addSubview(self.borderImageView)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    public var decoratedContentViews: [DecoratedView]? {
        didSet {
            oldValue?.forEach { $0.view.removeFromSuperview() }
            self.borderMaskLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.decoratedContentViews?.forEach { decoratedView in
                self.insertSubview(decoratedView.view, belowSubview: self.borderImageView)
                guard decoratedView.showBorder else { return }
                let sublayer = CALayer()
                sublayer.backgroundColor = UIColor.black.cgColor
                self.borderMaskLayer.addSublayer(sublayer)
            }
        }
    }

    public var style: CompoundBubbleViewStyleProtocol? {
        didSet { self.updateViews() }
    }

    public var viewModel: MessageViewModelProtocol? {
        didSet { self.updateViews() }
    }

    public var layoutProvider: CompoundBubbleLayoutProvider? {
        didSet { self.setNeedsLayout() }
    }

    // MARK: - MaximumLayoutWidthSpecificable

    public var preferredMaxLayoutWidth: CGFloat = 0

    // MARK: - BackgroundSizingQueryable

    public var canCalculateSizeInBackground: Bool {
        assertionFailure("Should not be called. It's here only because we use base cell")
        return false
    }

    // MARK: - Layout

    public override var safeAreaInsets: UIEdgeInsets {
        guard let layoutProvider = self.layoutProvider else { return .zero }
        return layoutProvider.layout(forMaxWidth: self.preferredMaxLayoutWidth).safeAreaInsets
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let layoutProvider = self.layoutProvider else { return .zero }
        return layoutProvider.layout(forMaxWidth: size.width).size
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let layoutProvider = self.layoutProvider else { return }
        let layout = layoutProvider.layout(forMaxWidth: self.preferredMaxLayoutWidth)
        let decoratedViewsWithFrames = zip(self.decoratedContentViews ?? [], layout.subviewsFrames)
        decoratedViewsWithFrames.forEach { $0.view.frame = $1 }
        let frame = CGRect(origin: .zero, size: layout.size)
        self.borderImageView.frame = frame
        // Disables implicit layer animation
        CATransaction.performWithDisabledActions {
            self.layer.mask?.frame = frame
        }

        guard let sublayers = self.borderMaskLayer.sublayers else { return }
        let framesOfBorderedViews = decoratedViewsWithFrames.compactMap { $0.showBorder ? $1 : nil }
        for (layer, var frame) in zip(sublayers, framesOfBorderedViews) {
            frame.size.width = layout.size.width
            layer.frame = frame
        }
    }

    // MARK: - Other

    private func updateViews() {
        guard let viewModel = self.viewModel, let style = self.style else { return }

        if style.hideBubbleForSingleContent && self.decoratedContentViews?.count == 1 {
            self.removeBubble()
        } else {
            self.updateBubble(style: style, viewModel: viewModel)
        }
    }

    private func updateBubble(style: CompoundBubbleViewStyleProtocol, viewModel: MessageViewModelProtocol) {
        self.borderImageView.image = style.borderImage(forViewModel: viewModel)

        if let maskImage = style.maskingImage(forViewModel: viewModel) {
            self.borderImageView.layer.mask = self.borderMaskLayer
            self.layer.mask = UIImageView(image: maskImage).layer
        } else {
            self.borderImageView.layer.mask = nil
            self.layer.mask = nil
        }

        self.backgroundColor = style.backgroundColor(forViewModel: viewModel)
    }

    private func removeBubble() {
        self.borderImageView.image = nil
        self.borderImageView.layer.mask = nil
        self.layer.mask = nil
        self.backgroundColor = nil
    }
}
