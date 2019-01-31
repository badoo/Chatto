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

    public typealias ViewWithSize = (UIView, SizeThatFitsProviderProtocol)

    public var contentViewsWithSizes: [ViewWithSize] = [] {
        didSet {
            oldValue.forEach { view, _ in view.removeFromSuperview() }
            self.contentViewsWithSizes.forEach { view, _ in self.addSubview(view) }
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
        return self.layout(subviewsWithSizes: self.contentViewsWithSizes, maxWidth: size.width).size
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let subviewsWithSizes = self.contentViewsWithSizes
        let layout = self.layout(subviewsWithSizes: subviewsWithSizes, maxWidth: self.preferredMaxLayoutWidth)
        for (viewWithSize, frame) in zip(subviewsWithSizes, layout.subviewsFrames) {
            let (view, _) = viewWithSize
            view.frame = frame
        }
        let frame = CGRect(origin: .zero, size: layout.size)
        self.borderImageView.frame = frame
        self.layer.mask?.frame = frame
    }

    // MARK: - Other

    private func layout(subviewsWithSizes: [ViewWithSize], maxWidth: CGFloat) -> CompoundBubbleLayout {
        var isIncoming = false
        var tailWidth: CGFloat = 0
        if let viewModel = self.viewModel, let style = self.style {
            isIncoming = viewModel.isIncoming
            tailWidth = style.tailWidth(forViewModel: viewModel)
        }
        let context = CompoundBubbleLayout.Context(sizeProviders: subviewsWithSizes.map { _, sizeProvider in sizeProvider },
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
    }

    private func setupSubviews() {
        self.addSubview(self.borderImageView)
    }

}

private struct CompoundBubbleLayout {
    let size: CGSize
    let subviewsFrames: [CGRect]

    struct Context {
        let sizeProviders: [SizeThatFitsProviderProtocol]
        let maxWidth: CGFloat
        let tailWidth: CGFloat
        let isIncoming: Bool
    }

    static func layout(forContext context: Context) -> CompoundBubbleLayout {
        var subviewsFrames: [CGRect] = []
        subviewsFrames.reserveCapacity(context.sizeProviders.count)
        var maxY: CGFloat = 0
        var resultWidth: CGFloat = 0
        let xOffset = context.isIncoming ? context.tailWidth : 0
        let sizeToFit = CGSize(width: context.maxWidth - context.tailWidth,
                               height: .greatestFiniteMagnitude)
        for sizeProvider in context.sizeProviders {
            let size = sizeProvider.sizeThatFits(size: sizeToFit)
            let viewWidth = max(size.width, resultWidth)
            resultWidth = min(viewWidth, context.maxWidth)
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
