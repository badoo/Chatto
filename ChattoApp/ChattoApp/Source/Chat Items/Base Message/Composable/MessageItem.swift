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

struct MessageBubbleViewModel: Equatable {
    let isIncoming: Bool
    var hasTail: Bool = true
}

final class MessageBubbleView: UIView, ChatItemContentView, ManualLayoutViewProtocol {

    private var viewModel: MessageBubbleViewModel? {
        didSet {
            guard self.viewModel != oldValue else { return }
            guard self.viewModel != nil else { fatalError() }
            self.updateBackgroundColor()
        }
    }

    private let bubbleView: UIView = .init()
    private var layout: MessageBubbleLayout?

    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateLayout()
    }

    var contentView: UIView? {
        didSet {
            guard let contentView = self.contentView, oldValue == nil else { fatalError() }
            self.setup(contentView: contentView)
            self.updateLayout()
        }
    }

    func subscribe(for viewModel: MessageBubbleViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - ManualLayoutViewProtocol

    func apply(layout: MessageBubbleLayout) {
        self.layout = layout
        self.updateLayout()
    }

    // MARK: - Private

    private func updateLayout() {
        guard let layout = self.layout else { return }
        self.contentView?.frame = layout.content
        self.bubbleView.frame = layout.bubble
    }

    private func setup(contentView: UIView) {
        let subviews = [
            self.bubbleView,
            contentView
        ]

        for view in subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        self.addSubview(self.bubbleView)
        self.bubbleView.addSubview(contentView)
    }

    // As proof of concept, we show if bubble would have tail as difference in backgroundColor
    private func updateBackgroundColor() {
        guard let viewModel = self.viewModel else { return }

        if viewModel.hasTail {
            self.bubbleView.backgroundColor = .lightGray
        } else {
            self.bubbleView.backgroundColor = .gray
        }
    }
}

struct MessageBubbleLayout: LayoutModel, SizeContainer {
    let content: CGRect
    let bubble: CGRect
    let size: CGSize
}

extension MessageBubbleView: SingleContainerViewProtocol {
    func add(child view: UIView) {
        self.contentView = view
    }
}

final class MessageBubbleViewFactory: ViewFactoryProtocol {

    init() {
    }

    func makeView() -> MessageBubbleView {
        MessageBubbleView()
    }
}

final class MessageBubbleViewModelFactory<ChatItem: MessageModelProtocol>: ViewModelFactoryProtocol {
    func makeViewModel(for chatItem: ChatItem) -> MessageBubbleViewModel {
        MessageBubbleViewModel(isIncoming: chatItem.isIncoming)
    }
}

struct MessageBubbleLayoutProvider: LayoutProviderProtocol, SingleContainerLayoutProviderProtocol {

    struct Configuration {
        let percentageToOccupy: CGFloat
    }

    private let configuration: Configuration
    private let viewModel: MessageBubbleViewModel

    init(configuration: Configuration, viewModel: MessageBubbleViewModel) {
        self.configuration = configuration
        self.viewModel = viewModel
    }

    var childLayoutProvider: Child?

    func layout(for context: LayoutContext) throws -> MessageBubbleLayout {
        guard let contentLayoutProvider = self.childLayoutProvider else { throw LayoutProviderDependencyError.noChild }
        let maxWidth = context.maxWidth
        var childContext = context
        childContext.maxWidth *= self.configuration.percentageToOccupy
        let contentSize = try contentLayoutProvider.layout(for: childContext).size

        var content = CGRect(
            origin: .zero,
            size: contentSize
        )

        if self.viewModel.isIncoming {
            content.origin.x = 0
        } else {
            content.origin.x = maxWidth - content.size.width
        }

        var size = contentSize
        size.width = min(maxWidth, size.width)

        let bubble = CGRect(
            origin: .zero,
            size: size
        )

        return MessageBubbleLayout(
            content: content,
            bubble: bubble,
            size: size
        )
    }
}

struct MessageBubbleLayoutProviderFactory: LayoutProviderFactoryProtocol {

    private let configuration: MessageBubbleLayoutProvider.Configuration

    init(configuration: MessageBubbleLayoutProvider.Configuration) {
        self.configuration = configuration
    }

    func makeLayoutProvider(for viewModel: MessageBubbleViewModel) -> MessageBubbleLayoutProvider {
        MessageBubbleLayoutProvider(configuration: self.configuration, viewModel: viewModel)
    }
}

