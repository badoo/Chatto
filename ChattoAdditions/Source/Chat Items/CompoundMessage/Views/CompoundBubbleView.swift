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

    private var contentViews: [UIView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            self.contentViews.forEach(self.addSubview)
        }
    }
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
        return CompoundBubbleLayout.layout(forSubviews: self.contentViews, maxWidth: size.width).size
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let subviews = self.contentViews
        let layout = CompoundBubbleLayout.layout(forSubviews: subviews, maxWidth: self.preferredMaxLayoutWidth)
        for (view, frame) in zip(subviews, layout.subviewsFrames) {
            view.frame = frame
        }
        let frame = CGRect(origin: .zero, size: layout.size)
        self.borderImageView.frame = frame
        self.layer.mask?.frame = frame
    }

    // MARK: - Other

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

    static func layout(forSubviews subviews: [UIView], maxWidth: CGFloat) -> CompoundBubbleLayout {
        var subviewsFrames: [CGRect] = []
        subviewsFrames.reserveCapacity(subviews.count)
        var maxY: CGFloat = 0
        var resultWidth: CGFloat = 0

        let sizeToFit = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        for view in subviews {
            let size = view.sizeThatFits(sizeToFit)
            let viewWidth = max(size.width, resultWidth)
            resultWidth = min(viewWidth, maxWidth)
            let frame = CGRect(x: 0, y: maxY, width: viewWidth, height: size.height)
            subviewsFrames.append(frame)
            maxY = frame.maxY
        }
        return CompoundBubbleLayout(
            size: CGSize(width: resultWidth, height: maxY),
            subviewsFrames: subviewsFrames
        )
    }
}
