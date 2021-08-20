//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import UIKit

public enum InputBarMode {
    case text
    case custom
}

public protocol ViewPresentationEventsHandling {
    func onViewDidLoad()

    func onViewWillAppear()
    func onViewDidAppear()

    func onViewWillDisappear()
    func onViewDidDisappear()
}

public typealias ChatInputBarPresenterViewController = InputPositionControlling & UIViewController

public protocol ChatInputBarPresenterProtocol: ViewPresentationEventsHandling, ScrollViewEventsHandling, KeyboardEventsHandling {

    var viewController: ChatInputBarPresenterViewController? { get set }

    var inputBarView: UIView { get }
    var inputBarControlPanel: UIView { get }

    func onViewDidUpdate()
    func onDidTapOutside()

    func collapseInput()

    func startTextInput()
    func isEmptyText() -> Bool
}
