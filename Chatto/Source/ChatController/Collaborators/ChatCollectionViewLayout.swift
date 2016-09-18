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

public protocol ChatCollectionViewLayoutDelegate: class {
    func chatCollectionViewLayoutModel() -> ChatCollectionViewLayoutModel
}

public struct ChatCollectionViewLayoutModel {
    let contentSize: CGSize
    let layoutAttributes: [UICollectionViewLayoutAttributes]
    let layoutAttributesBySectionAndItem: [[UICollectionViewLayoutAttributes]]
    let calculatedForWidth: CGFloat

    public static func createModel(_ collectionViewWidth: CGFloat, itemsLayoutData: [(height: CGFloat, bottomMargin: CGFloat)]) -> ChatCollectionViewLayoutModel {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        var layoutAttributesBySectionAndItem = [[UICollectionViewLayoutAttributes]]()
        layoutAttributesBySectionAndItem.append([UICollectionViewLayoutAttributes]())

        var verticalOffset: CGFloat = 0
        for (index, layoutData) in itemsLayoutData.enumerated() {
            let indexPath = IndexPath(item: index, section: 0)
            let (height, bottomMargin) = layoutData
            let itemSize = CGSize(width: collectionViewWidth, height: height)
            let frame = CGRect(origin: CGPoint(x: 0, y: verticalOffset), size: itemSize)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            layoutAttributes.append(attributes)
            layoutAttributesBySectionAndItem[0].append(attributes)
            verticalOffset += itemSize.height
            verticalOffset += bottomMargin
        }

        return ChatCollectionViewLayoutModel(
            contentSize: CGSize(width: collectionViewWidth, height: verticalOffset),
            layoutAttributes: layoutAttributes,
            layoutAttributesBySectionAndItem: layoutAttributesBySectionAndItem,
            calculatedForWidth: collectionViewWidth
        )
    }
}


open class ChatCollectionViewLayout: UICollectionViewLayout {
    var layoutModel: ChatCollectionViewLayoutModel!
    public weak var delegate: ChatCollectionViewLayoutDelegate?

    // Optimization: after reloadData we'll get invalidateLayout, but prepareLayout will be delayed until next run loop.
    // Client may need to force prepareLayout after reloadData, but we don't want to compute layout again in the next run loop.
    private var layoutNeedsUpdate = true
    open override func invalidateLayout() {
        super.invalidateLayout()
        self.layoutNeedsUpdate = true
    }

    open override func prepare() {
        super.prepare()
        guard self.layoutNeedsUpdate else { return }
        guard let delegate = self.delegate else { return }
        var oldLayoutModel = self.layoutModel
        self.layoutModel = delegate.chatCollectionViewLayoutModel()
        self.layoutNeedsUpdate = false
        DispatchQueue.global(qos: .default).async { () -> Void in
            // Dealloc of layout with 5000 items take 25 ms on tests on iPhone 4s
            // This moves dealloc out of main thread
            if oldLayoutModel != nil {
                // Use nil check above to remove compiler warning: Variable 'oldLayoutModel' was written to, but never read
                oldLayoutModel = nil
            }
        }
    }

    open override var collectionViewContentSize: CGSize {
        return self.layoutModel?.contentSize ?? .zero
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.layoutModel.layoutAttributes.filter { $0.frame.intersects(rect) }
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section < self.layoutModel.layoutAttributesBySectionAndItem.count && indexPath.item < self.layoutModel.layoutAttributesBySectionAndItem[indexPath.section].count {
            return self.layoutModel.layoutAttributesBySectionAndItem[indexPath.section][indexPath.item]
        }
        assert(false, "Unexpected indexPath requested:\(indexPath)")
        return nil
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return self.layoutModel.calculatedForWidth != newBounds.width
    }
}
