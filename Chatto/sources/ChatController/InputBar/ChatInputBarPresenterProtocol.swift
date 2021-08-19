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

/// sourcery: mockable
public protocol ChatInputBarPresenterDelegate: AnyObject {

    func inputBarPresenterWillExpandInput(_ presenter: ChatInputBarPresenterProtocol)
    func inputBarPresenterDidExpandInput(_ presenter: ChatInputBarPresenterProtocol)

    func inputBarPresenterAsksScreenLayoutDuringAnimation(_ presenter: ChatInputBarPresenterProtocol)

    func inputBarPresenterWillCollapseInput(_ presenter: ChatInputBarPresenterProtocol)
    func inputBarPresenterDidCollapseInput(_ presenter: ChatInputBarPresenterProtocol)

    func inputBarPresenter(_ presenter: ChatInputBarPresenterProtocol, didChangeText text: String)
    func inputBarPresenterDidSendMessage(_ presenter: ChatInputBarPresenterProtocol)

    func inputBarPresenter(_ presenter: ChatInputBarPresenterProtocol, didChangeInputMode inputMode: InputBarMode)

    func inputBarPresenterShouldAnimatePlaceholder(_ presenter: ChatInputBarPresenterProtocol) -> Bool

    func inputBarPresenter(_ presenter: ChatInputBarPresenterProtocol, didAskToPresentAlert alert: UIAlertController)
    func inputBarPresenterDidShowElementOnTopOfInputBar(_ presenter: ChatInputBarPresenterProtocol)
    func inputBarPresenterDidHideElementOnTopOfInputBar(_ presenter: ChatInputBarPresenterProtocol)
}

/// sourcery: mockable
public protocol ChatInputBarPresenterProtocol: AnyObject, ViewPresentationEventsHandling {

    var delegate: ChatInputBarPresenterDelegate? { get set }

    var inputBarView: UIView { get }
    var inputBarControlPanel: UIView { get }

    func onViewDidUpdate()
    func onDidTapOutside()

    func collapseInput()

    func startTextInput()
    func isEmptyText() -> Bool
}

public protocol ChatInputBarPresenterFactoryProtocol: AnyObject {
    func makeInputBarPresenter(for chatViewController: BaseChatViewController) -> ChatInputBarPresenterProtocol
}
