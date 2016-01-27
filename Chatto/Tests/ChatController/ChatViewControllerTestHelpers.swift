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

@testable import Chatto

func createFakeChatItems(count count: Int) -> [ChatItemProtocol] {
    var items = [ChatItemProtocol]()
    for i in 0..<count {
        items.append(FakeChatItem(uid: "\(i)", type: "fake-type"))
    }
    return items
}

class TesteableChatViewController: ChatViewController {
    let presenterBuilders: [ChatItemType: [ChatItemPresenterBuilderProtocol]]
    let chatInputView = UIView()
    init(presenterBuilders: [ChatItemType: [ChatItemPresenterBuilderProtocol]] = [ChatItemType: [ChatItemPresenterBuilderProtocol]]()) {
        self.presenterBuilders = presenterBuilders
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        return self.presenterBuilders
    }

    override func createChatInputView() -> UIView {
        return self.chatInputView
    }
}

class FakeDataSource: ChatDataSourceProtocol {
    var hasMoreNext = false
    var hasMorePrevious = false
    var wasRequestedForPrevious = false
    var wasRequestedForMessageCountContention = false
    var chatItemsForLoadNext: [ChatItemProtocol]?
    var chatItems = [ChatItemProtocol]()
    weak var delegate: ChatDataSourceDelegateProtocol?

    func loadNext(completion: () -> Void) {
        if let chatItemsForLoadNext = self.chatItemsForLoadNext {
            self.chatItems = chatItemsForLoadNext
        }
        completion()
    }

    func loadPrevious(completion: () -> Void) {
        self.wasRequestedForPrevious = true
        completion()
    }

    func adjustNumberOfMessages(preferredMaxCount preferredMaxCount: Int?, focusPosition: Double, completion:(didAdjust: Bool) -> Void) {
        self.wasRequestedForMessageCountContention = true
        completion(didAdjust: false)
    }
}

class FakeCell: UICollectionViewCell { }

class FakePresenterBuilder: ChatItemPresenterBuilderProtocol {
    var presentersCreatedCount: Int = 0
    func canHandleChatItem(chatItem: ChatItemProtocol) -> Bool {
        return chatItem.type == "fake-type"
    }

    func createPresenterWithChatItem(chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        self.presentersCreatedCount += 1
        return FakePresenter()
    }

    var presenterType: ChatItemPresenterProtocol.Type {
        return FakePresenter.self
    }
}

class FakePresenter: BaseChatItemPresenter<FakeCell> {
    override class func registerCells(collectionView: UICollectionView) {
        collectionView.registerClass(FakeCell.self, forCellWithReuseIdentifier: "fake-cell")
    }

    override func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 10
    }

    override func dequeueCell(collectionView collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier("fake-cell", forIndexPath: indexPath)
    }

    override func configureCell(cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        let fakeCell = cell as! FakeCell
        fakeCell.backgroundColor = UIColor.redColor()
    }
}

class FakeChatItem: ChatItemProtocol {
    var uid: String
    var type: ChatItemType
    init(uid: String, type: ChatItemType) {
        self.uid = uid
        self.type = type
    }
}

final class SerialTaskQueueTestHelper: SerialTaskQueueProtocol {
    var onAllTasksFinished: (() -> Void)?

    private var isBusy = false
    private var isStopped = true
    private var tasksQueue = [TaskClosure]()

    func addTask(task: TaskClosure) {
        self.tasksQueue.append(task)
        self.maybeExecuteNextTask()
    }

    func start() {
        self.isStopped = false
        self.maybeExecuteNextTask()
    }

    func stop() {
        self.isStopped = true
    }

    var isEmpty: Bool {
        return self.tasksQueue.isEmpty
    }

    private func maybeExecuteNextTask() {
        if !self.isStopped && !self.isBusy {
            if !self.isEmpty {
                let firstTask = self.tasksQueue.removeFirst()
                self.isBusy = true
                firstTask(completion: { [weak self] () -> Void in
                    self?.isBusy = false
                    self?.maybeExecuteNextTask()
                    })
            } else {
                self.onAllTasksFinished?()
            }
        }
    }
}
