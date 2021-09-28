//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import UIKit

@frozen
public enum InputBarMode {
    case text
    case custom
}

public protocol ScrollViewEventsHandling: AnyObject {
    func onScrollViewDidScroll(_ scrollView: UIScrollView)
    func onScrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func onScrollViewWillEndDragging(_ scrollView: UIScrollView, velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    func onScrollViewDidEndDragging(_ scrollView: UIScrollView, decelerate: Bool)
}

public extension ScrollViewEventsHandling {
    func onScrollViewDidScroll(_ scrollView: UIScrollView) { }

    func onScrollViewWillBeginDragging(_ scrollView: UIScrollView) { }

    func onScrollViewWillEndDragging(_ scrollView: UIScrollView, velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) { }

    func onScrollViewDidEndDragging(_ scrollView: UIScrollView, decelerate: Bool) { }
}

public protocol CollectionViewEventsHandling: ScrollViewEventsHandling {
    func onCollectionView(_ collectionView: UICollectionView,
                          didDisplayCellWithIndexPath indexPath: IndexPath,
                          companionCollection: ChatItemCompanionCollection)

    func onCollectionView(_ collectionView: UICollectionView,
                          didUpdateItemsWithUpdateType updateType: UpdateType)
}

public extension CollectionViewEventsHandling {
    func onCollectionView(_ collectionView: UICollectionView,
                          didDisplayCellWithIndexPath indexPath: IndexPath,
                          companionCollection: ChatItemCompanionCollection) { }

    func onCollectionView(_ collectionView: UICollectionView,
                          didUpdateItemsWithUpdateType updateType: UpdateType) { }
}

public protocol ViewPresentationEventsHandling {
    func onViewDidLoad()

    func onViewWillAppear()
    func onViewDidAppear()

    func onViewWillDisappear()
    func onViewDidDisappear()
}

public protocol ChatInputBarPresentingController: UIViewController, InputPositionControlling {
    func setup(inputView: UIView)
}

public protocol ViewModelEventsHandling {
    func onViewDidUpdate()
}

public protocol BaseChatInputBarPresenterProtocol: AnyObject {

    var viewController: ChatInputBarPresentingController? { get set }

    func onViewDidUpdate() // TODO: View Model updates should not be triggered by the BaseChatViewController
}
