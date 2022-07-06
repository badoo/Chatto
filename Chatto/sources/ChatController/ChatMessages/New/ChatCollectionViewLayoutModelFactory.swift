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

public protocol ChatCollectionViewLayoutModelFactoryProtocol: AnyObject {
    func createLayoutModel(items: ChatItemCompanionCollection,
             collectionViewWidth: CGFloat) -> ChatCollectionViewLayoutModel
}

final class ChatCollectionViewLayoutModelFactory: ChatCollectionViewLayoutModelFactoryProtocol {

    // MARK: - Type declarations

    private struct HeightValue {
        var value: CGFloat = 0
        private let heightProvider: () -> CGFloat

        init(_ heightProvider: @escaping () -> CGFloat) {
            self.heightProvider = heightProvider
        }

        mutating func calculate() {
            self.value = self.heightProvider()
        }
    }

    // MARK: - Instantiation

    init() {}

    // MARK: - ChatCollectionViewLayoutUpdater

    public func createLayoutModel(items: ChatItemCompanionCollection,
              collectionViewWidth width: CGFloat) -> ChatCollectionViewLayoutModel {

        var heights = items.map { companion in
            HeightValue { companion.height(forMaxWidth: width) }
        }

        enum ExecutionContext { case this, main }

        let isMainThread = Thread.isMainThread

        let contexts: Indices<ExecutionContext> = Indices(of: items) {
            isMainThread || $0.presenter.canCalculateHeightInBackground ? .this : .main
        }

        for index in contexts[.this] {
            heights[index].calculate()
        }

        if !contexts[.main].isEmpty {
            DispatchQueue.main.sync {
                for index in contexts[.main] {
                    heights[index].calculate()
                }
            }
        }

        let heightValues = heights.map { $0.value }
        let bottomMargins = items.map(\.bottomMargin)
        let layoutData = Array(zip(heightValues, bottomMargins))

        return ChatCollectionViewLayoutModel.createModel(width, itemsLayoutData: layoutData)
    }
}

private extension ChatItemCompanion {
    func height(forMaxWidth maxWidth: CGFloat) -> CGFloat {
        self.presenter.heightForCell(maximumWidth: maxWidth,
                             decorationAttributes: self.decorationAttributes)
    }

    var bottomMargin: CGFloat { self.decorationAttributes?.bottomMargin ?? 0 }
}

private struct Indices<Key: Hashable> {

    private let indicesByKey: [Key: Set<Int>]

    init<C: Collection>(of collection: C, decide: (C.Element) -> Key) where C.Index == Int {
        var indicesByKey: [Key: Set<Int>] = [:]

        for (index, element) in collection.enumerated() {
            indicesByKey[decide(element), default: []].insert(index)
        }

        self.indicesByKey = indicesByKey
    }

    subscript(_ key: Key) -> Set<Int> {
        self.indicesByKey[key] ?? []
    }
}

