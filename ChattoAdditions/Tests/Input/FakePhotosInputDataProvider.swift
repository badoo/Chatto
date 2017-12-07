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

@testable import ChattoAdditions

final class FakePhotosInputDataProviderImageRequest: PhotosInputDataProviderImageRequestProtocol {
    var requestId: Int32 = 1
    var progress: Double = 0

    var onObserveProgress: ((PhotosInputDataProviderProgressHandler?, PhotosInputDataProviderCompletion?) -> Void)?
    func observeProgress(with progressHandler: PhotosInputDataProviderProgressHandler?,
                         completion: PhotosInputDataProviderCompletion?) {
        self.onObserveProgress?(progressHandler, completion)
    }

    var onCancel: (() -> Void)?
    func cancel() {
        self.onCancel?()
    }
}

final class FakePhotosInputDataProvider: PhotosInputDataProviderProtocol {
    weak var delegate: PhotosInputDataProviderDelegate?
    var count: Int = 0

    var onRequestPreviewImage: ((Int, CGSize, PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol)?
    func requestPreviewImage(at index: Int,
                             targetSize: CGSize,
                             completion: @escaping PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol {
        return self.onRequestPreviewImage?(index, targetSize, completion) ?? FakePhotosInputDataProviderImageRequest()
    }

    var onRequestFullImage: ((Int, PhotosInputDataProviderProgressHandler?, PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol)?
    func requestFullImage(at index: Int,
                          progressHandler: PhotosInputDataProviderProgressHandler?,
                          completion: @escaping PhotosInputDataProviderCompletion) -> PhotosInputDataProviderImageRequestProtocol {
        return self.onRequestFullImage?(index, progressHandler, completion) ?? FakePhotosInputDataProviderImageRequest()
    }

    var onFullImageRequest: ((Int) -> PhotosInputDataProviderImageRequestProtocol?)?
    func fullImageRequest(at index: Int) -> PhotosInputDataProviderImageRequestProtocol? {
        return self.onFullImageRequest?(index)
    }
}
