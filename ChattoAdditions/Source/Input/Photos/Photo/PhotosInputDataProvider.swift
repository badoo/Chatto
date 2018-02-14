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

import PhotosUI
import UIKit

private class PhotosInputDataProviderImageRequest: PhotosInputDataProviderImageRequestProtocol {
    fileprivate(set) var requestId: Int32 = -1
    private(set) var progress: Double = 0
    fileprivate var cancelBlock: (() -> Void)?

    private var progressHandlers = [PhotosInputDataProviderProgressHandler]()
    private var completionHandlers = [PhotosInputDataProviderCompletion]()

    func observeProgress(with progressHandler: PhotosInputDataProviderProgressHandler?,
                         completion: PhotosInputDataProviderCompletion?) {
        if let progressHandler = progressHandler {
            self.progressHandlers.append(progressHandler)
        }
        if let completion = completion {
            self.completionHandlers.append(completion)
        }
    }

    func cancel() {
        self.cancelBlock?()
    }

    fileprivate func handleProgressChange(with progress: Double) {
        self.progressHandlers.forEach { $0(progress) }
        self.progress = progress
    }

    fileprivate func handleCompletion(with result: PhotosInputDataProviderResult) {
        self.completionHandlers.forEach { $0(result) }
    }
}

@objc
final class PhotosInputDataProvider: NSObject, PhotosInputDataProviderProtocol, PHPhotoLibraryChangeObserver {
    weak var delegate: PhotosInputDataProviderDelegate?
    private var imageManager = PHCachingImageManager()
    private var fetchResult: PHFetchResult<PHAsset>!
    private var fullImageRequests = [PHAsset: PhotosInputDataProviderImageRequestProtocol]()
    override init() {
        func fetchOptions(_ predicate: NSPredicate?) -> PHFetchOptions {
            let options = PHFetchOptions()
            options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
            options.predicate = predicate
            return options
        }

        if let userLibraryCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject {
            self.fetchResult = PHAsset.fetchAssets(in: userLibraryCollection, options: fetchOptions(NSPredicate(format: "mediaType = \(PHAssetMediaType.image.rawValue)")))
        } else {
            self.fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions(nil))
        }
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    var count: Int {
        return self.fetchResult.count
    }

    func requestPreviewImage(at index: Int,
                             targetSize: CGSize,
                             completion: @escaping PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        let asset = self.fetchResult[index]
        let request = PhotosInputDataProviderImageRequest()
        request.observeProgress(with: nil, completion: completion)
        let options = self.makePreviewRequestOptions()
        var requestId: Int32 = -1
        requestId = self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (image, info) in
            let result: PhotosInputDataProviderResult
            if let image = image {
                result = .success(image)
            } else {
                result = .error(info?[PHImageErrorKey] as? Error)
            }
            request.handleCompletion(with: result)
        }
        request.cancelBlock = { [weak self] in
            self?.imageManager.cancelImageRequest(requestId)
        }
        request.requestId = requestId
        return request
    }

    func requestFullImage(at index: Int,
                          progressHandler: PhotosInputDataProviderProgressHandler?,
                          completion: @escaping PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        if let existedRequest = self.fullImageRequest(at: index) {
            return existedRequest
        } else {
            let asset = self.fetchResult[index]
            let request = PhotosInputDataProviderImageRequest()
            request.observeProgress(with: progressHandler, completion: completion)
            let options = self.makeFullImageRequestOptions()
            options.progressHandler = { (progress, _, _, _) -> Void in
                DispatchQueue.main.async {
                    request.handleProgressChange(with: progress)
                }
            }
            var requestId: Int32 = -1
            self.fullImageRequests[asset] = request
            requestId = self.imageManager.requestImageData(for: asset, options: options, resultHandler: { [weak self] (data, _, _, info) in
                guard let sSelf = self else { return }
                let result: PhotosInputDataProviderResult
                if let data = data, let image = UIImage(data: data) {
                    result = .success(image)
                } else {
                    result = .error(info?[PHImageErrorKey] as? Error)
                }
                request.handleCompletion(with: result)
                sSelf.fullImageRequests[asset] = nil
            })
            request.cancelBlock = { [weak self, weak request] in
                guard let sSelf = self, let sRequest = request else { return }
                sSelf.cancelFullImageRequest(sRequest)
            }
            request.requestId = requestId
            return request
        }
    }

    func fullImageRequest(at index: Int) -> PhotosInputDataProviderImageRequestProtocol? {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        let asset = self.fetchResult[index]
        return self.fullImageRequests[asset]
    }

    func cancelFullImageRequest(_ request: PhotosInputDataProviderImageRequestProtocol) {
        assert(Thread.isMainThread, "Cancel function is called not on Main Thread. It's not a thread-safe.")
        self.imageManager.cancelImageRequest(request.requestId)
        if let assetAndRequestPair = self.fullImageRequests.first(where: { $0.value === request }) {
            self.fullImageRequests[assetAndRequestPair.key] = nil
        }
    }

    private func makePreviewRequestOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return options
    }

    private func makeFullImageRequestOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        return options
    }

    // MARK: PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Photos may call this method on a background queue; switch to the main queue to update the UI.
        DispatchQueue.main.async { [weak self]  in
            guard let sSelf = self else { return }

            if let changeDetails = changeInstance.changeDetails(for: sSelf.fetchResult as! PHFetchResult<PHObject>) {
                let updateBlock = { () -> Void in
                    self?.fetchResult = changeDetails.fetchResultAfterChanges as! PHFetchResult<PHAsset>
                }
                sSelf.delegate?.handlePhotosInputDataProviderUpdate(sSelf, updateBlock: updateBlock)
            }
        }
    }
}
