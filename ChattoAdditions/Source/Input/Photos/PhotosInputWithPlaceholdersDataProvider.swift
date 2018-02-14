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

protocol PhotosInputDataProviderDelegate: class {
    func handlePhotosInputDataProviderUpdate(_ dataProvider: PhotosInputDataProviderProtocol, updateBlock: @escaping () -> Void)
}

protocol PhotosInputDataProviderProtocol: class {
    weak var delegate: PhotosInputDataProviderDelegate? { get set }
    var count: Int { get }
    @discardableResult
    func requestPreviewImage(at index: Int,
                             targetSize: CGSize,
                             completion: @escaping PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol
    @discardableResult
    func requestFullImage(at index: Int,
                          progressHandler: PhotosInputDataProviderProgressHandler?,
                          completion: @escaping PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol
    func fullImageRequest(at index: Int) -> PhotosInputDataProviderImageRequestProtocol?
}

typealias PhotosInputDataProviderProgressHandler = (Double) -> Void
typealias PhotosInputDataProviderCompletion = (PhotosInputDataProviderResult) -> Void

enum PhotosInputDataProviderResult {
    case success(UIImage)
    case error(Error?)

    var image: UIImage? {
        guard case let .success(resultImage) = self else { return nil }
        return resultImage
    }
}

protocol PhotosInputDataProviderImageRequestProtocol: class {
    var requestId: Int32 { get }
    var progress: Double { get }

    func observeProgress(with progressHandler: PhotosInputDataProviderProgressHandler?,
                         completion: PhotosInputDataProviderCompletion?)
    func cancel()
}

final class PhotosInputWithPlaceholdersDataProvider: PhotosInputDataProviderProtocol, PhotosInputDataProviderDelegate {
    weak var delegate: PhotosInputDataProviderDelegate?
    private let photosDataProvider: PhotosInputDataProviderProtocol
    private let placeholdersDataProvider: PhotosInputDataProviderProtocol

    init(photosDataProvider: PhotosInputDataProviderProtocol, placeholdersDataProvider: PhotosInputDataProviderProtocol) {
        self.photosDataProvider = photosDataProvider
        self.placeholdersDataProvider = placeholdersDataProvider
        self.photosDataProvider.delegate = self
    }

    var count: Int {
        return max(self.photosDataProvider.count, self.placeholdersDataProvider.count)
    }

    @discardableResult
    func requestPreviewImage(at index: Int,
                             targetSize: CGSize,
                             completion: @escaping PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol {
        if index < self.photosDataProvider.count {
            return self.photosDataProvider.requestPreviewImage(at: index, targetSize: targetSize, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestPreviewImage(at: index, targetSize: targetSize, completion: completion)
        }
    }

    @discardableResult
    func requestFullImage(at index: Int,
                          progressHandler: PhotosInputDataProviderProgressHandler?,
                          completion: @escaping PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol {
        if index < self.photosDataProvider.count {
            return self.photosDataProvider.requestFullImage(at: index, progressHandler: progressHandler, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestFullImage(at: index, progressHandler: progressHandler, completion: completion)
        }
    }

    func fullImageRequest(at index: Int) -> PhotosInputDataProviderImageRequestProtocol? {
        if index < self.photosDataProvider.count {
            return self.photosDataProvider.fullImageRequest(at: index)
        } else {
            return self.placeholdersDataProvider.fullImageRequest(at: index)
        }
    }

    // MARK: PhotosInputDataProviderDelegate

    func handlePhotosInputDataProviderUpdate(_ dataProvider: PhotosInputDataProviderProtocol, updateBlock: @escaping () -> Void) {
        self.delegate?.handlePhotosInputDataProviderUpdate(self, updateBlock: updateBlock)
    }
}
