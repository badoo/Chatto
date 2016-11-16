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

class ConversationsViewController: UITableViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        var initialCount = 0
        let pageSize = 50

        var dataSource: FakeDataSource!
        if segue.identifier == "0 messages" {
            initialCount = 0
        } else if segue.identifier == "2 messages" {
            initialCount = 2
        } else if segue.identifier == "10000 messages" {
            initialCount = 10000
        } else if segue.identifier == "overview" {
            dataSource = FakeDataSource(messages: TutorialMessageFactory.createMessages(), pageSize: pageSize)
        } else {
            assert(false, "segue not handled!")
        }

        let chatController = { () -> DemoChatViewController? in
            if let controller = segue.destination as? DemoChatViewController {
                return controller
            }
            if let tabController = segue.destination as? UITabBarController,
                let controller = tabController.viewControllers?.first as? DemoChatViewController {
                return controller
            }
            return nil
        }()!

        if dataSource == nil {
            dataSource = FakeDataSource(count: initialCount, pageSize: pageSize)
        }
        chatController.dataSource = dataSource
        chatController.messageSender = dataSource.messageSender
    }
}
