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

final class UpdateItemTypeViewController: DemoChatViewController {

    private var textItem: DemoTextMessageModel!
    private var photoItem: DemoPhotoMessageModel!

    private var displayedItem: ChatItemProtocol!

    // MARK: - UIViewController

    init() {
        self.textItem = DemoChatMessageFactory.makeTextMessage(
            "1",
            text: "Hello",
            isIncoming: true
        )
        self.photoItem = DemoChatMessageFactory.makePhotoMessage(
            "1",
            image: UIImage(named: "pic-test-1")!,
            size: CGSize(width: 300, height: 300),
            isIncoming: true
        )
        self.displayedItem = self.textItem
        let dataSource = DemoChatDataSource(messages: [self.displayedItem], pageSize: 50)

        super.init(dataSource: dataSource)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Update",
            style: .plain,
            target: self,
            action: #selector(self.didPressUpdateItemType)
        )
    }

    // MARK: - Private methods

    @objc
    private func didPressUpdateItemType() {
        self.toggleCurrentItem()
    }

    private func toggleCurrentItem() {
        let previousUID = self.displayedItem.uid
        if self.displayedItem === self.textItem {
            self.displayedItem = self.photoItem
        } else {
            self.displayedItem = self.textItem
        }
        self.dataSource.replaceMessage(withUID: previousUID, withNewMessage: self.displayedItem)
    }
}
