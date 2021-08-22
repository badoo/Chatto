//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import UIKit

@frozen
public enum InputBarMode {
    case text
    case custom
}

public protocol KeyboardEventsHandling: AnyObject {
    func onKeyboardStateDidChange(_ height: CGFloat, _ status: KeyboardStatus)
}

public protocol ScrollViewEventsHandling: AnyObject {
    func onScrollViewDidScroll(_ scrollView: UIScrollView)
    func onScrollViewDidEndDragging(_ scrollView: UIScrollView, _ decelerate: Bool)
}

public protocol ViewPresentationEventsHandling {
    func onViewDidLoad()

    func onViewWillAppear()
    func onViewDidAppear()

    func onViewWillDisappear()
    func onViewDidDisappear()
}

public protocol ChatInputBarPresentingController: UIViewController & InputPositionControlling {
    func setup(inputView: UIView)
}

public protocol ViewModelEventsHandling {
    func onViewDidUpdate()
}

public protocol BaseChatInputBarPresenterProtocol: AnyObject {

    var viewController: ChatInputBarPresentingController? { get set }

    func onViewDidUpdate() // TODO: View Model updates should not be triggered by the BaseChatViewController
}
