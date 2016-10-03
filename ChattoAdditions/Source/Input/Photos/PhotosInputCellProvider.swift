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
    func cellForItemAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell
}

class PhotosInputPlaceholderCellProvider: PhotosInputCellProviderProtocol {
    private let reuseIdentifier = "PhotosPlaceholderCellProvider"
    private let collectionView: UICollectionView
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        self.collectionView.register(PhotosInputPlaceholderCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
    }

    func cellForItemAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        return self.collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath)
    }
}

class PhotosInputCellProvider: PhotosInputCellProviderProtocol {
    private let reuseIdentifier = "PhotosCellProvider"
    private let collectionView: UICollectionView
    private let dataProvider: PhotosInputDataProviderProtocol
    init(collectionView: UICollectionView, dataProvider: PhotosInputDataProviderProtocol) {
        self.dataProvider = dataProvider
        self.collectionView = collectionView
        self.collectionView.register(PhotosInputCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
    }

    func cellForItemAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath) as! PhotosInputCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    private let previewRequests = NSMapTable<PhotosInputCell, NSNumber>.weakToStrongObjects()
    private func configureCell(_ cell: PhotosInputCell, atIndexPath indexPath: IndexPath) {
        if let requestID = self.previewRequests.object(forKey: cell) {
            self.previewRequests.removeObject(forKey: cell)
            self.dataProvider.cancelPreviewImageRequest(requestID.int32Value)
        }

        let index = indexPath.item - 1
        let targetSize = cell.bounds.size
        var imageProvidedSynchronously = true
        var requestID: Int32 = -1
        requestID = self.dataProvider.requestPreviewImageAtIndex(index, targetSize: targetSize) { [weak self, weak cell] image in
            guard let sSelf = self, let sCell = cell else { return }
            // We can get here even afer calling cancelPreviewImageRequest (looks liek a race condition in PHImageManager)
            // Also, according to PHImageManager's documentation, this block can be called several times: we may receive an image with a low quality and then receive an update with a better one
            // This can also be called before returning from requestPreviewImageAtIndex (synchronously) if the image is cached by PHImageManager
            let imageIsForThisCell = imageProvidedSynchronously || sSelf.previewRequests.object(forKey: sCell)?.int32Value == requestID
            if imageIsForThisCell {
                sCell.image = image
            }
        }
        imageProvidedSynchronously = false

        self.previewRequests.setObject(NSNumber(value: requestID), forKey:cell)
    }
}
