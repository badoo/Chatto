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

    public var contentViews: [UIView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            self.contentViews.forEach { self.insertSubview($0, belowSubview: self.borderImageView) }
        }
    }

    public var style: CompoundBubbleViewStyleProtocol? {
        didSet { self.updateViews() }
    }

    public var viewModel: MessageViewModelProtocol? {
        didSet { self.updateViews() }
    }

    public var layoutProvider: CompoundBubbleLayoutProvider?

    // MARK: - MaximumLayoutWidthSpecificable

    public var preferredMaxLayoutWidth: CGFloat = 0

    // MARK: - BackgroundSizingQueryable

    public let canCalculateSizeInBackground = false

    // MARK: - Layout

    public override var safeAreaInsets: UIEdgeInsets {
        guard let layoutProvider = self.layoutProvider else { return .zero }
        return layoutProvider.makeLayout(forMaxWidth: self.preferredMaxLayoutWidth).safeAreaInsets
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let layoutProvider = self.layoutProvider else { return .zero }
        return layoutProvider.makeLayout(forMaxWidth: size.width).size
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let layoutProvider = self.layoutProvider else { return }
        let layout = layoutProvider.makeLayout(forMaxWidth: self.preferredMaxLayoutWidth)
        zip(self.contentViews, layout.subviewsFrames).forEach { $0.frame = $1 }
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
        self.backgroundColor = style.backgroundColor(forViewModel: viewModel)
    }

    private func setupSubviews() {
        self.addSubview(self.borderImageView)
    }
}
