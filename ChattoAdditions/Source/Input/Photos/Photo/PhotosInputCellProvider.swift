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

protocol PhotosInputCellProviderProtocol: class {
    func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell
    func configureFullImageLoadingIndicator(at indexPath: IndexPath,
                                            request: PhotosInputDataProviderImageRequestProtocol)
}

final class PhotosInputCellProvider: PhotosInputCellProviderProtocol {
    private let reuseIdentifier = "PhotosCellProvider"
    private let collectionView: UICollectionView
    private let dataProvider: PhotosInputDataProviderProtocol
    init(collectionView: UICollectionView, dataProvider: PhotosInputDataProviderProtocol) {
        self.dataProvider = dataProvider
        self.collectionView = collectionView
        self.collectionView.register(PhotosInputCell.self, forCellWithReuseIdentifier: self.reuseIdentifier)
    }

    func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath) as! PhotosInputCell
        self.configureCell(cell, at: indexPath)
        return cell
    }

    func configureFullImageLoadingIndicator(at indexPath: IndexPath,
                                            request: PhotosInputDataProviderImageRequestProtocol) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? PhotosInputCell else { return }
        self.configureCellForFullImageLoadingIfNeeded(cell, request: request)
    }

    private var previewRequests = [Int: PhotosInputDataProviderImageRequestProtocol]()
    private var fullImageRequests = [Int: PhotosInputDataProviderImageRequestProtocol]()
    private func configureCell(_ cell: PhotosInputCell, at indexPath: IndexPath) {
        if let request = self.previewRequests[cell.hash] {
            self.previewRequests[cell.hash] = nil
            request.cancel()
        }
        self.fullImageRequests[cell.hash] = nil
        let index = indexPath.item - 1
        let targetSize = cell.bounds.size
        var imageProvidedSynchronously = true
        var requestId: Int32 = -1
        let request = self.dataProvider.requestPreviewImage(at: index, targetSize: targetSize) { [weak self, weak cell] result in
            guard let sSelf = self, let sCell = cell else { return }
            // We can get here even afer calling cancelPreviewImageRequest (looks liek a race condition in PHImageManager)
            // Also, according to PHImageManager's documentation, this block can be called several times: we may receive an image with a low quality and then receive an update with a better one
            // This can also be called before returning from requestPreviewImage (synchronously) if the image is cached by PHImageManager
            let imageIsForThisCell = imageProvidedSynchronously || sSelf.previewRequests[sCell.hash]?.requestId == requestId
            if imageIsForThisCell {
                sCell.image = result.image
                sSelf.previewRequests[sCell.hash] = nil
            }
        }
        requestId = request.requestId
        imageProvidedSynchronously = false
        self.previewRequests[cell.hash] = request
        if let fullImageRequest = self.dataProvider.fullImageRequest(at: index) {
            self.configureCellForFullImageLoadingIfNeeded(cell, request: fullImageRequest)
        }
    }

    private func configureCellForFullImageLoadingIfNeeded(_ cell: PhotosInputCell, request: PhotosInputDataProviderImageRequestProtocol) {
        guard request.progress < 1 else { return }
        cell.showProgressView()
        cell.updateProgress(CGFloat(request.progress))
        request.observeProgress(with: { [weak self, weak cell, weak request] progress in
            guard let sSelf = self, let sCell = cell, sSelf.fullImageRequests[sCell.hash] === request else { return }
            cell?.updateProgress(CGFloat(progress))
            }, completion: { [weak self, weak cell, weak request] _ in
                guard let sSelf = self, let sCell = cell, sSelf.fullImageRequests[sCell.hash] === request else { return }
                sCell.hideProgressView()
                sSelf.fullImageRequests[sCell.hash] = nil
        })
        self.fullImageRequests[cell.hash] = request
    }
}
