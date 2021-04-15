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

private class MediaInputDataProviderResourceRequest: MediaInputDataProviderResourceRequestProtocol {
    fileprivate(set) var requestId: Int32 = -1
    private(set) var progress: Double = 0
    fileprivate var cancelBlock: (() -> Void)?

    private var progressHandlers = [MediaInputDataProviderProgressHandler]()
    private var completionHandlers = [MediaInputDataProviderCompletion]()

    func observeProgress(with progressHandler: MediaInputDataProviderProgressHandler?,
                         completion: MediaInputDataProviderCompletion?) {
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

    fileprivate func handleCompletion(with result: MediaInputDataProviderResult) {
        self.completionHandlers.forEach { $0(result) }
    }
}

private class MediaInputDataProviderPreviewRequest: MediaInputDataProviderPreviewRequestProtocol {
    fileprivate(set) var requestId: Int32 = -1
    private(set) var progress: Double = 0
    fileprivate var cancelBlock: (() -> Void)?

    private var progressHandlers = [MediaInputDataProviderProgressHandler]()
    private var completionHandlers = [MediaInputDataProviderPreviewCompletion]()

    func observeProgress(with progressHandler: MediaInputDataProviderProgressHandler?,
                         completion: MediaInputDataProviderPreviewCompletion?) {
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

    fileprivate func handleCompletion(with image: UIImage?, duration: TimeInterval) {
        self.completionHandlers.forEach { $0(image, duration) }
    }
}


@objc
final class MediaInputDataProvider: NSObject, MediaInputDataProviderProtocol, PHPhotoLibraryChangeObserver {
    weak var delegate: MediaInputDataProviderDelegate?
    private var imageManager: PHCachingImageManager?
    private var fetchResult: PHFetchResult<PHAsset>?
    private var fullResourcesRequests = [PHAsset: MediaInputDataProviderResourceRequestProtocol]()
    private let mediaTypes: [PHAssetMediaType]

    init(mediaTypes: [PHAssetMediaType]) {
        self.mediaTypes = mediaTypes
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func prepare(_ completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async(execute: completion)
                return
            }

            func fetchOptions(_ predicate: NSPredicate?) -> PHFetchOptions {
                let options = PHFetchOptions()
                options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
                options.predicate = predicate
                return options
            }

            let fetchResult: PHFetchResult<PHAsset> = {
                if let userLibraryCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject {
                    let options = fetchOptions(NSPredicate(format: "mediaType IN %@", self.mediaTypes.map({ $0.rawValue })))
                    return PHAsset.fetchAssets(in: userLibraryCollection,
                                               options: options)
                } else {
                    return PHAsset.fetchAssets(with: .image, options: fetchOptions(nil))
                }
            }()
            let imageManager = PHCachingImageManager()
            PHPhotoLibrary.shared().register(self)

            DispatchQueue.main.async(execute: { [weak self] in
                self?.fetchResult = fetchResult
                self?.imageManager = imageManager
                completion()
            })
        }
    }

    var count: Int {
        return self.fetchResult?.count ?? 0
    }

    func requestPreviewImage(at index: Int,
                             targetSize: CGSize,
                             completion: @escaping MediaInputDataProviderPreviewCompletion) -> MediaInputDataProviderPreviewRequestProtocol {
        guard let fetchResult = self.fetchResult, let imageManager = self.imageManager else {
            assertionFailure("MediaInputDataProvider is not prepared")
            return MediaInputDataProviderPreviewRequest()
        }
        assert(index >= 0 && index < self.count, "Index out of bounds")
        let asset = fetchResult[index]
        let request = MediaInputDataProviderPreviewRequest()
        request.observeProgress(with: nil, completion: completion)
        let options = self.makePreviewRequestOptions()
        var requestId: Int32 = -1
        requestId = imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (image, info) in
            if let image = image {
                request.handleCompletion(with: image, duration: asset.duration)
            } else {
                request.handleCompletion(with: nil, duration: 0)
            }
        }
        request.cancelBlock = { [weak imageManager] in
            imageManager?.cancelImageRequest(requestId)
        }
        request.requestId = requestId
        return request
    }

    func requestResource(at index: Int,
                         progressHandler: MediaInputDataProviderProgressHandler?,
                         completion: @escaping MediaInputDataProviderCompletion) -> MediaInputDataProviderResourceRequestProtocol {
        guard let fetchResult = self.fetchResult, let imageManager = self.imageManager else {
            assertionFailure("MediaInputDataProvider is not prepared")
            return MediaInputDataProviderResourceRequest()
        }
        assert(index >= 0 && index < self.count, "Index out of bounds")
        let asset = fetchResult[index]

        if let existedRequest = self.resourceRequest(at: index) {
            return existedRequest
        } else {
            let request = MediaInputDataProviderResourceRequest()
            request.observeProgress(with: progressHandler, completion: completion)
            let options = self.makeFullImageRequestOptions()
            options.progressHandler = { (progress, _, _, _) -> Void in
                DispatchQueue.main.async {
                    request.handleProgressChange(with: progress)
                }
            }
            var requestId: Int32 = -1
            self.fullResourcesRequests[asset] = request

            if asset.mediaType == .image {
                requestId = imageManager.requestImageData(for: asset, options: options, resultHandler: { [weak self] (data, _, _, info) in
                    guard let sSelf = self else { return }
                    let result: MediaInputDataProviderResult
                    if let data = data, let image = UIImage(data: data) {
                        result = .successImage(image)
                    } else {
                        result = .error(info?[PHImageErrorKey] as? Error)
                    }
                    request.handleCompletion(with: result)
                    sSelf.fullResourcesRequests[asset] = nil
                })
            } else if asset.mediaType == .video {
                let videoOptions = PHVideoRequestOptions()
                videoOptions.isNetworkAccessAllowed = true
                videoOptions.deliveryMode = .fastFormat
                requestId = imageManager.requestAVAsset(forVideo: asset, options: videoOptions, resultHandler: { [weak self] (avAsset, _, info) in
                    let result: MediaInputDataProviderResult
                    if let data = avAsset as? AVURLAsset {
                        result = .successVideo(data.url)
                    } else {
                        result = .error(info?[PHImageErrorKey] as? Error)
                    }
                    // Dispatch to main thread as completion may be invoked in background
                    DispatchQueue.main.async {
                        request.handleCompletion(with: result)
                        self?.fullResourcesRequests[asset] = nil
                    }
                })
            }
            request.cancelBlock = { [weak self, weak request] in
                guard let sSelf = self, let sRequest = request else { return }
                sSelf.cancelResourceRequest(sRequest)
            }
            request.requestId = requestId
            return request
        }
    }

    func resourceRequest(at index: Int) -> MediaInputDataProviderResourceRequestProtocol? {
        guard let fetchResult = self.fetchResult else {
            assertionFailure("MediaInputDataProvider is not prepared")
            return nil
        }
        assert(index >= 0 && index < self.count, "Index out of bounds")
        let asset = fetchResult[index]
        return self.fullResourcesRequests[asset]
    }

    func cancelResourceRequest(_ request: MediaInputDataProviderResourceRequestProtocol) {
        guard let imageManager = self.imageManager else {
            assertionFailure("MediaInputDataProvider is not prepared")
            return
        }
        assert(Thread.isMainThread, "Cancel function is called not on Main Thread. It's not a thread-safe.")
        imageManager.cancelImageRequest(request.requestId)
        if let assetAndRequestPair = self.fullResourcesRequests.first(where: { $0.value === request }) {
            self.fullResourcesRequests[assetAndRequestPair.key] = nil
        }
    }

    private func makePreviewRequestOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
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
            guard let sSelf = self, let fetchResult = sSelf.fetchResult else { return }

            if let changeDetails = changeInstance.changeDetails(for: fetchResult) {
                let updateBlock = { () -> Void in
                    self?.fetchResult = changeDetails.fetchResultAfterChanges
                }
                sSelf.delegate?.handleMediaInputDataProviderUpdate(sSelf, updateBlock: updateBlock)
            }
        }
    }
}
