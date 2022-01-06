//
// Copyright (c) Bumble, 2021-present. All rights reserved.
//

import CoreGraphics
import Foundation

public protocol ChatCollectionViewLayoutModelFactoryProtocol {
    func createLayoutModel(_ items: ChatItemCompanionCollection, collectionViewWidth: CGFloat) -> ChatCollectionViewLayoutModel
}

public final class ChatCollectionViewLayoutModelFactory: ChatCollectionViewLayoutModelFactoryProtocol {

    public init() { }

    public func createLayoutModel(_ items: ChatItemCompanionCollection, collectionViewWidth: CGFloat) -> ChatCollectionViewLayoutModel {
        // swiftlint:disable:next nesting
        typealias IntermediateItemLayoutData = (height: CGFloat?, bottomMargin: CGFloat)
        typealias ItemLayoutData = (height: CGFloat, bottomMargin: CGFloat)
        // swiftlint:disable:previous nesting

        func createLayoutModel(intermediateLayoutData: [IntermediateItemLayoutData]) -> ChatCollectionViewLayoutModel {
            let layoutData = intermediateLayoutData.map { (intermediateLayoutData: IntermediateItemLayoutData) -> ItemLayoutData in
                return (height: intermediateLayoutData.height!, bottomMargin: intermediateLayoutData.bottomMargin)
            }
            return ChatCollectionViewLayoutModel.createModel(collectionViewWidth, itemsLayoutData: layoutData)
        }

        let isInBackground = !Thread.isMainThread
        var intermediateLayoutData = [IntermediateItemLayoutData]()
        var itemsForMainThread = [(index: Int, itemCompanion: ChatItemCompanion)]()

        for (index, itemCompanion) in items.enumerated() {
            var height: CGFloat?
            let bottomMargin: CGFloat = itemCompanion.decorationAttributes?.bottomMargin ?? 0
            if !isInBackground || itemCompanion.presenter.canCalculateHeightInBackground {
                height = itemCompanion.presenter.heightForCell(maximumWidth: collectionViewWidth, decorationAttributes: itemCompanion.decorationAttributes)
            } else {
                itemsForMainThread.append((index: index, itemCompanion: itemCompanion))
            }
            intermediateLayoutData.append((height: height, bottomMargin: bottomMargin))
        }

        if itemsForMainThread.count > 0 {
            DispatchQueue.main.sync {
                for (index, itemCompanion) in itemsForMainThread {
                    let height = itemCompanion.presenter.heightForCell(
                        maximumWidth: collectionViewWidth,
                        decorationAttributes: itemCompanion.decorationAttributes
                    )
                    intermediateLayoutData[index].height = height
                }
            }
        }
        return createLayoutModel(intermediateLayoutData: intermediateLayoutData)
    }
}
