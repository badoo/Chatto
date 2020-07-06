/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit

class ChatExamplesViewController: CellsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Examples"

        self.cellItems = [
            self.makeOverviewCellItem(),
            self.makeChatCellItem(title: "Empty chat", messagesCount: 0),
            self.makeChatCellItem(title: "Chat with 10000 messages", messagesCount: 10_000),
            self.makeChatCellItem(title: "Chat with expandable input", messagesCount: 10_000, shouldUseAlternativePresenter: true),
            self.makeMessageSelectionCellItem(),
            self.makeOpenWithTabBarCellItem(),
            self.makeScrollToBottomCellItem(),
            self.makeCompoundDemoViewController(),
            self.makeUpdateItemTypeViewController(),
            self.makeTestItemsReloadingCellItem(),
            self.makeAsyncAvatarLoadingCellItem()
        ]
    }

    // MARK: - Cells

    private func makeOverviewCellItem() -> CellItem {
        return CellItem(title: "Overview", action: { [weak self] in
            let dataSource = DemoChatDataSource(messages: DemoChatMessageFactory.makeOverviewMessages(), pageSize: 50)
            let viewController = AddRandomMessagesChatViewController()
            viewController.dataSource = dataSource
            self?.navigationController?.pushViewController(viewController, animated: true)
        })
    }

    private func makeChatCellItem(title: String, messagesCount: Int, shouldUseAlternativePresenter: Bool = false) -> CellItem {
        return CellItem(title: title, action: { [weak self] in
            let dataSource = DemoChatDataSource(count: messagesCount, pageSize: 50)
            let viewController = AddRandomMessagesChatViewController()
            viewController.dataSource = dataSource
            viewController.shouldUseAlternativePresenter = shouldUseAlternativePresenter
            self?.navigationController?.pushViewController(viewController, animated: true)
        })
    }

    private func makeMessageSelectionCellItem() -> CellItem {
        return CellItem(title: "Chat with message selection", action: { [weak self] in
            let messages = DemoChatMessageFactory.makeMessagesSelectionMessages()
            let dataSource = DemoChatDataSource(messages: messages, pageSize: 50)
            let viewController = MessagesSelectionChatViewController()
            viewController.dataSource = dataSource
            self?.navigationController?.pushViewController(viewController, animated: true)
        })
    }

    private func makeOpenWithTabBarCellItem() -> CellItem {
        return CellItem(title: "UITabBarController examples", action: { [weak self] in
            guard let sSelf = self else { return }
            let viewController = ChatWithTabBarExamplesViewController()
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Close",
                style: .done,
                target: sSelf,
                action: #selector(sSelf.dismissPresentedController)
            )
            let navigationController = UINavigationController(rootViewController: viewController)
            let tabBarViewController = UITabBarController()
            tabBarViewController.setViewControllers([navigationController], animated: false)
            sSelf.present(tabBarViewController, animated: true, completion: nil)
        })
    }

    private func makeScrollToBottomCellItem() -> CellItem {
        return CellItem(title: "Scroll To Bottom Button Example", action: { [weak self] in
            let dataSource = DemoChatDataSource(count: 10_000, pageSize: 50)
            let viewController = ScrollToBottomButtonChatViewController()
            viewController.dataSource = dataSource
            self?.navigationController?.pushViewController(viewController, animated: true)
        })
    }

    private func makeUpdateItemTypeViewController() -> CellItem {
        return CellItem(title: "Dynamically change item type") { [unowned self] in
            self.navigationController?.pushViewController(UpdateItemTypeViewController(), animated: true)
        }
    }

    private func makeCompoundDemoViewController() -> CellItem {
        return CellItem(title: "Compound message examples") { [unowned self] in
            let messages = DemoChatMessageFactory.makeCompoundMessages()
            let dataSource = DemoChatDataSource(messages: messages, pageSize: 50)
            let viewController = DemoChatViewController()
            viewController.dataSource = dataSource
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private func makeTestItemsReloadingCellItem() -> CellItem {
        return CellItem(title: "Test items reloading") { [unowned self] in
            self.navigationController?.pushViewController(TestItemsReloadingViewController(), animated: true)
        }
    }

    private func makeAsyncAvatarLoadingCellItem() -> CellItem {
        return CellItem(title: "Async avatar loading") { [unowned self] in
            self.navigationController?.pushViewController(AsyncAvatarLoadingViewController(), animated: true)
        }
    }

    @objc
    private func dismissPresentedController() {
        self.dismiss(animated: true, completion: nil)
    }
}
