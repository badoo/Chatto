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
    func handlePhotosInpudDataProviderUpdate(_ dataProvider: PhotosInputDataProviderProtocol, updateBlock: @escaping () -> Void)
}

protocol PhotosInputDataProviderProtocol: class {
    weak var delegate: PhotosInputDataProviderDelegate? { get set }
    var count: Int { get }
    func requestPreviewImageAtIndex(_ index: Int, targetSize: CGSize, completion: @escaping (UIImage) -> Void) -> Int32
    func requestFullImageAtIndex(_ index: Int, completion: @escaping (UIImage) -> Void)
    func cancelPreviewImageRequest(_ requestID: Int32)
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

    func requestPreviewImageAtIndex(_ index: Int, targetSize: CGSize, completion: @escaping (UIImage) -> Void) -> Int32 {
        if index < self.photosDataProvider.count {
            return self.photosDataProvider.requestPreviewImageAtIndex(index, targetSize: targetSize, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestPreviewImageAtIndex(index, targetSize: targetSize, completion: completion)
        }
    }

    func requestFullImageAtIndex(_ index: Int, completion: @escaping (UIImage) -> Void) {
        if index < self.photosDataProvider.count {
            return self.photosDataProvider.requestFullImageAtIndex(index, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestFullImageAtIndex(index, completion: completion)
        }
    }

    func cancelPreviewImageRequest(_ requestID: Int32) {
        return self.photosDataProvider.cancelPreviewImageRequest(requestID)
    }

    // MARK: PhotosInputDataProviderDelegate

    func handlePhotosInpudDataProviderUpdate(_ dataProvider: PhotosInputDataProviderProtocol, updateBlock: @escaping () -> Void) {
        self.delegate?.handlePhotosInpudDataProviderUpdate(self, updateBlock: updateBlock)
    }
}
