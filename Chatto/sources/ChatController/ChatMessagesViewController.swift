//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import UIKit

public final class ChatMessagesViewController: UICollectionViewController {

    private let presenterFactory: ChatItemPresenterFactoryProtocol
    private let style: Style

    init(presenterFactory: ChatItemPresenterFactoryProtocol,
         style: Style) {
        self.presenterFactory = presenterFactory
        self.style = style

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.configurePresenterFactory()
        self.configureStyle()
    }

    private func configureStyle() {
        self.collectionView.allowsSelection = false
        self.collectionView.alwaysBounceVertical = self.style.alwaysBounceVertical
        self.collectionView.backgroundColor = self.style.backgroundColor
        self.collectionView.contentInset = self.style.contentInsets
        self.collectionView.keyboardDismissMode = self.style.keyboardDismissMode
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.showsVerticalScrollIndicator = self.style.shouldShowVerticalScrollView
        self.collectionView.scrollIndicatorInsets = self.style.scrollIndicatorInsets
    }

    private func configurePresenterFactory() {
        self.presenterFactory.configure(withCollectionView: self.collectionView)
    }
}

public extension ChatMessagesViewController {
    struct Style {
        var alwaysBounceVertical: Bool
        var backgroundColor: UIColor
        var contentInsets: UIEdgeInsets
        var keyboardDismissMode: UIScrollView.KeyboardDismissMode
        var scrollIndicatorInsets: UIEdgeInsets
        var shouldShowVerticalScrollView: Bool
    }
}

extension ChatMessagesViewController.Style {
    static var `default`: Self {
        return .init(
            alwaysBounceVertical: true,
            backgroundColor: .clear,
            contentInsets: .init(
                top: 10,
                left: 0,
                bottom: 10,
                right: 0
            ),
            keyboardDismissMode: .interactive,
            scrollIndicatorInsets: .zero,
            shouldShowVerticalScrollView: true
        )
    }
}
