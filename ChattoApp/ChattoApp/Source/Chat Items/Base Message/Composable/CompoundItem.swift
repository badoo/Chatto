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
import Chatto
import ChattoAdditions

final class CompoundMessageView: UIView, ManualLayoutViewProtocol {

    private var layout: CompoundLayout?

    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var componentViews: [UIView]? {
        didSet {
            oldValue?.forEach { $0.removeFromSuperview() }
            guard let views = self.componentViews else { return }
            self.setupComponentViews(views)
            self.updateLayout()
        }
    }

    func subscribe(for viewModel: Void) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateLayout()
    }

    // MARK: - ManualLayoutViewProtocol

    func apply(layout: CompoundLayout) {
        self.layout = layout
        self.updateLayout()
    }

    // MARK: - Private

    private func updateLayout() {
        guard let layout = self.layout else { return }
        guard let contentViews = self.componentViews else { return }
        zip(contentViews, layout.content).forEach { $0.frame = $1 }
    }

    private func setupComponentViews(_ views: [UIView]) {
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(view)
        }
    }
}

extension CompoundMessageView: MultipleContainerViewProtocol {
    func add(children: [UIView]) {
        self.componentViews = children
    }
}

struct CompoundViewFactory: ViewFactoryProtocol {
    func makeView() -> CompoundMessageView {
        CompoundMessageView()
    }
}

struct CompoundViewModelFactory<ChatItem>: ViewModelFactoryProtocol {
    func makeViewModel(for chatItem: ChatItem) {}
}

struct CompoundLayout: LayoutModel, SizeContainer {
    let content: [CGRect]
    let size: CGSize
}

struct CompoundLayoutProvider: LayoutProviderProtocol, MultipleContainerLayoutProviderProtocol {

    var childrenLayoutProviders: [Child]?

    func layout(for context: LayoutContext) throws -> CompoundLayout {
        guard let children = self.childrenLayoutProviders else {
            throw LayoutProviderDependencyError.noChildren
        }
        let childrenSizes = try children.map { try $0.layout(for: context).size }

        var content: [CGRect] = []
        var contentHeight: CGFloat = 0
        var maxContentWidth: CGFloat = 0

        for size in childrenSizes {
            var origin = CGPoint.zero
            origin.y = contentHeight
            let frame = CGRect(
                origin: origin,
                size: size
            )
            contentHeight += size.height
            maxContentWidth = max(maxContentWidth, size.width)
            content.append(frame)
        }

        precondition(context.maxWidth >= maxContentWidth)

        let size = CGSize(
            width: min(maxContentWidth, context.maxWidth),
            height: contentHeight
        )

        return CompoundLayout(
            content: content,
            size: size
        )
    }
}

struct CompoundLayoutProviderFactory: LayoutProviderFactoryProtocol {
    func makeLayoutProvider(for viewModel: Void) -> CompoundLayoutProvider {
        CompoundLayoutProvider()
    }
}
