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

public final class CompoundBubbleView: UIView, MaximumLayoutWidthSpecificable, BackgroundSizingQueryable {

    // MARK: - Private properties

    private let borderImageView = UIImageView()

    // MARK: - Instantiation

    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setupSubviews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public properties

    public typealias ViewWithLayout = (UIView, MessageManualLayoutProviderProtocol)

    public var contentViewsWithLayout: [ViewWithLayout] = [] {
        didSet {
            oldValue.forEach { view, _ in view.removeFromSuperview() }
            self.contentViewsWithLayout.forEach { view, _ in self.addSubview(view) }
        }
    }

    public var style: CompoundBubbleViewStyleProtocol? {
        didSet { self.updateViews() }
    }

    public var viewModel: MessageViewModelProtocol? {
        didSet { self.updateViews() }
    }

    // MARK: - MaximumLayoutWidthSpecificable

    public var preferredMaxLayoutWidth: CGFloat = 0

    // MARK: - BackgroundSizingQueryable

    public let canCalculateSizeInBackground = true

    // MARK: - Layout

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.layout(subviewsWithLayout: self.contentViewsWithLayout, maxWidth: size.width).size
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let subviewsWithLayout = self.contentViewsWithLayout
        let layout = self.layout(subviewsWithLayout: subviewsWithLayout, maxWidth: self.preferredMaxLayoutWidth)
        for (viewWithLayout, frame) in zip(subviewsWithLayout, layout.subviewsFrames) {
            let (view, _) = viewWithLayout
            view.frame = frame
        }
        let frame = CGRect(origin: .zero, size: layout.size)
        self.borderImageView.frame = frame
        self.layer.mask?.frame = frame
    }

    // MARK: - Other

    private func layout(subviewsWithLayout: [ViewWithLayout], maxWidth: CGFloat) -> CompoundBubbleLayout {
        var isIncoming = false
        var tailWidth: CGFloat = 0
        if let viewModel = self.viewModel, let style = self.style {
            isIncoming = viewModel.isIncoming
            tailWidth = style.tailWidth(forViewModel: viewModel)
        }
        let context = CompoundBubbleLayout.Context(layoutProviders: subviewsWithLayout.map { _, layout in layout },
                                                   maxWidth: maxWidth,
                                                   tailWidth: tailWidth,
                                                   isIncoming: isIncoming)
        return CompoundBubbleLayout.layout(forContext: context)
    }

    private func updateViews() {
        guard let viewModel = self.viewModel, let style = self.style else { return }
        self.borderImageView.image = style.borderImage(forViewModel: viewModel)
        let maskImage = style.maskingImage(forViewModel: viewModel)
        self.layer.mask = UIImageView(image: maskImage).layer
        self.backgroundColor = style.backgroundColor(forViewModel: viewModel)
    }

    private func setupSubviews() {
        self.addSubview(self.borderImageView)
    }

}

private struct CompoundBubbleLayout {
    let size: CGSize
    let subviewsFrames: [CGRect]

    struct Context {
        let layoutProviders: [MessageManualLayoutProviderProtocol]
        let maxWidth: CGFloat
        let tailWidth: CGFloat
        let isIncoming: Bool
    }

    static func layout(forContext context: Context) -> CompoundBubbleLayout {
        var subviewsFrames: [CGRect] = []
        subviewsFrames.reserveCapacity(context.layoutProviders.count)
        var maxY: CGFloat = 0
        var resultWidth: CGFloat = 0
        for layoutProvider in context.layoutProviders {
            let tailWidth = layoutProvider.layoutInsideTail ? 0 : context.tailWidth
            let sizeToFit = CGSize(width: context.maxWidth - tailWidth,
                                   height: .greatestFiniteMagnitude)
            let xOffset = context.isIncoming ? tailWidth : 0
            let size = layoutProvider.sizeThatFits(size: sizeToFit)
            let viewWidth = max(size.width, resultWidth)
            resultWidth = min(viewWidth + tailWidth, context.maxWidth)
            let frame = CGRect(x: xOffset, y: maxY, width: viewWidth, height: size.height)
            subviewsFrames.append(frame)
            maxY = frame.maxY
        }
        return CompoundBubbleLayout(
            size: CGSize(width: resultWidth, height: maxY),
            subviewsFrames: subviewsFrames
        )
    }
}
