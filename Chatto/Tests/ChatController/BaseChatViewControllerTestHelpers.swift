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

func createFakeChatItems(count: Int) -> [ChatItemProtocol] {
    var items = [ChatItemProtocol]()
    for i in 0..<count {
        items.append(FakeChatItem(uid: "\(i)", type: "fake-type"))
    }
    return items
}

final class TesteableChatViewController: BaseChatViewController {
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

final class FakeDataSource: ChatDataSourceProtocol {
    var hasMoreNext = false
    var hasMorePrevious = false
    var wasRequestedForPrevious = false
    var wasRequestedForMessageCountContention = false
    var chatItemsForLoadNext: [ChatItemProtocol]?
    var chatItems = [ChatItemProtocol]()
    weak var delegate: ChatDataSourceDelegateProtocol?

    func loadNext() {
        if let chatItemsForLoadNext = self.chatItemsForLoadNext {
            self.chatItems = chatItemsForLoadNext
        }
        self.delegate?.chatDataSourceDidUpdate(self, updateType: .pagination)
    }

    func loadPrevious() {
        self.wasRequestedForPrevious = true
        self.delegate?.chatDataSourceDidUpdate(self, updateType: .pagination)
    }

    func adjustNumberOfMessages(preferredMaxCount: Int?, focusPosition: Double, completion: ((Bool)) -> Void) {
        self.wasRequestedForMessageCountContention = true
        completion(false)
    }
}

final class FakeCell: UICollectionViewCell {}

final class FakePresenterBuilder: ChatItemPresenterBuilderProtocol {
    private(set) var createdPresenters: [ChatItemPresenterProtocol] = []

    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem.type == "fake-type"
    }

    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        let presenter = FakePresenter()
        presenter._isItemUpdateSupportedResult = false
        self.createdPresenters.append(presenter)
        return presenter
    }

    var presenterType: ChatItemPresenterProtocol.Type {
        return FakePresenter.self
    }
}

final class FakeChatItem: ChatItemProtocol {
    var uid: String
    var type: ChatItemType
    init(uid: String, type: ChatItemType) {
        self.uid = uid
        self.type = type
    }
}

final class SerialTaskQueueTestHelper: SerialTaskQueueProtocol {

    var onAllTasksFinished: (() -> Void)?

    var isBusy = false
    var isStopped = true
    var tasksQueue = [TaskClosure]()

    func addTask(_ task: @escaping TaskClosure) {
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

    func flushQueue() {
        self.tasksQueue.removeAll()
    }

    private func maybeExecuteNextTask() {
        if !self.isStopped && !self.isBusy {
            if !self.isEmpty {
                let firstTask = self.tasksQueue.removeFirst()
                self.isBusy = true
                firstTask({ [weak self] () -> Void in
                    self?.isBusy = false
                    self?.maybeExecuteNextTask()
                    })
            } else {
                self.onAllTasksFinished?()
            }
        }
    }
}

// MARK: - Updatable

final class FakeUpdatablePresenterBuilder: ChatItemPresenterBuilderProtocol {

    private(set) var createdPresenters: [ChatItemPresenterProtocol] = []

    var updatedPresentersCount: Int {
        return self.createdPresenters.reduce(0) { return $0 + ($1 as! FakePresenter)._updateWithChatItemCallsCount }
    }

    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem.type == "fake-type"
    }

    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        let presenter = FakePresenter()
        presenter._isItemUpdateSupportedResult = true
        self.createdPresenters.append(presenter)
        return presenter
    }

    var presenterType: ChatItemPresenterProtocol.Type {
        return FakePresenter.self
    }
}

final class FakePresenter: ChatItemPresenterProtocol {

    static func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(FakeCell.self, forCellWithReuseIdentifier: "fake-cell")
    }

    var _isItemUpdateSupportedResult: Bool!
    var isItemUpdateSupported: Bool {
        return self._isItemUpdateSupportedResult
    }

    private var _updateWithChatItemCalls: [(ChatItemProtocol)] = []
    var _updateWithChatItemIsCalled: Bool { return self._updateWithChatItemCallsCount > 0 }
    var _updateWithChatItemCallsCount: Int { return self._updateWithChatItemCalls.count }
    var _updateWithChatItemLastCallParams: ChatItemProtocol? { return self._updateWithChatItemCalls.last }
    func update(with chatItem: ChatItemProtocol) {
        self._updateWithChatItemCalls.append((chatItem))
    }

    func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 10
    }

    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "fake-cell", for: indexPath as IndexPath)
    }

    func configureCell(_ cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        let fakeCell = cell as! FakeCell
        fakeCell.backgroundColor = UIColor.red
    }
}
