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

protocol PhotosInputCellProviderProtocol {
    func cellForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewCell
}

class PhotosInputPlaceholderCellProvider: PhotosInputCellProviderProtocol {
    private var reuseIdentifier = "PhotosPlaceholderCellProvider"
    private let collectionView: UICollectionView
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        self.collectionView.registerClass(PhotosInputPlaceholderCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
    }

    func cellForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewCell {
        return self.collectionView.dequeueReusableCellWithReuseIdentifier(self.reuseIdentifier, forIndexPath: indexPath)
    }
}

class PhotosInputCellProvider: PhotosInputCellProviderProtocol {
    private var reuseIdentifier = "PhotosCellProvider"
    private let collectionView: UICollectionView
    private let dataProvider: PhotosInputDataProvider
    init(collectionView: UICollectionView, dataProvider: PhotosInputDataProvider) {
        self.dataProvider = dataProvider
        self.collectionView = collectionView
        self.collectionView.registerClass(PhotosInputCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
    }

    func cellForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCellWithReuseIdentifier(self.reuseIdentifier, forIndexPath: indexPath) as! PhotosInputCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    private let previewRequests = NSMapTable.weakToStrongObjectsMapTable()
    private func configureCell(cell: PhotosInputCell, atIndexPath indexPath: NSIndexPath) {
        if let requestID = self.previewRequests.objectForKey(cell) as? NSNumber {
            self.previewRequests.removeObjectForKey(cell)
            self.dataProvider.cancelPreviewImageRequest(requestID.intValue)
        }

        let index = indexPath.item - 1
        let targetSize = cell.bounds.size
        let requestID = self.dataProvider.requestPreviewImageAtIndex(index, targetSize: targetSize) { image in
            self.previewRequests.removeObjectForKey(cell)
            cell.image = image
        }

        self.previewRequests.setObject(NSNumber(int: requestID), forKey:cell)
    }
}
