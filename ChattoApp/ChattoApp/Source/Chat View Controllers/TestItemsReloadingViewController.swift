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

final class TestItemsReloadingViewController: DemoChatViewController {

    // MARK: - UIViewController

    override func viewDidLoad() {
        self.dataSource = DemoChatDataSource(messages: self.remakeItems(), pageSize: 50)
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
        self.dataSource = DemoChatDataSource(messages: self.remakeItems(), pageSize: 50)
    }

    private func remakeItems() -> [ChatItemProtocol] {
        let randomGoodAnswer = ["Nice!", "Great!", "Amazing!", "Brilliant!", "Another very very long answer to test how cell resizing works."].randomElement()!
        let randomImageName = "pic-test-\((1...3).randomElement()!)"
        let randomImage = UIImage(named: randomImageName)!

        return [
            DemoChatMessageFactory.makeTextMessage("1", text: "Hello", isIncoming: true),
            DemoChatMessageFactory.makeTextMessage("2", text: "Hi!", isIncoming: false),
            DemoChatMessageFactory.makeTextMessage("3", text: "How are you doing?", isIncoming: true),
            DemoChatMessageFactory.makeTextMessage("4", text: "I'm fine, thanks!", isIncoming: false),
            DemoChatMessageFactory.makeTextMessage("5", text: randomGoodAnswer, isIncoming: true),
            DemoChatMessageFactory.makePhotoMessage("6", image: randomImage, size: randomImage.size, isIncoming: false),
            DemoChatMessageFactory.makeTextMessage("7", text: "Cool, bye!", isIncoming: true),
            DemoChatMessageFactory.makeCompoundMessage(uid: "8", text: randomGoodAnswer, imageName: randomImageName, isIncoming: false)
        ].reversed()
    }
}
