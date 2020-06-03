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

protocol MediaInputDataProviderDelegate: class {
    func handlePhotosInputDataProviderUpdate(_ dataProvider: MediaInputDataProviderProtocol, updateBlock: @escaping () -> Void)
}

protocol MediaInputDataProviderProtocol: class {
    var delegate: MediaInputDataProviderDelegate? { get set }
    var count: Int { get }
    @discardableResult
    func requestPreviewImage(at index: Int,
                             targetSize: CGSize,
                             completion: @escaping MediaInputDataProviderCompletion) -> MediaInputDataProviderResourceRequestProtocol

    @discardableResult
    func requestResource(at index: Int,
                         progressHandler: MediaInputDataProviderProgressHandler?,
                         completion: @escaping MediaInputDataProviderCompletion) -> MediaInputDataProviderResourceRequestProtocol
    func resourceRequest(at index: Int) -> MediaInputDataProviderResourceRequestProtocol?
}

typealias MediaInputDataProviderProgressHandler = (Double) -> Void
typealias MediaInputDataProviderCompletion = (MediaInputDataProviderResult) -> Void

enum MediaInputDataProviderResult {
    case successImage(UIImage)
    case successVideo(URL)
    case error(Error?)

    var image: UIImage? {
        guard case let .successImage(resultImage) = self else { return nil }
        return resultImage
    }
}

protocol MediaInputDataProviderResourceRequestProtocol: class {
    var requestId: Int32 { get }
    var progress: Double { get }

    func observeProgress(with progressHandler: MediaInputDataProviderProgressHandler?,
                         completion: MediaInputDataProviderCompletion?)
    func cancel()
}

final class MediaInputWithPlaceholdersDataProvider: MediaInputDataProviderProtocol, MediaInputDataProviderDelegate {
    weak var delegate: MediaInputDataProviderDelegate?
    private let mediaDataProvider: MediaInputDataProviderProtocol
    private let placeholdersDataProvider: MediaInputDataProviderProtocol

    init(mediaDataProvider: MediaInputDataProviderProtocol, placeholdersDataProvider: MediaInputDataProviderProtocol) {
        self.mediaDataProvider = mediaDataProvider
        self.placeholdersDataProvider = placeholdersDataProvider
        self.mediaDataProvider.delegate = self
    }

    var count: Int {
        return max(self.mediaDataProvider.count, self.placeholdersDataProvider.count)
    }

    @discardableResult
    func requestPreviewImage(at index: Int,
                             targetSize: CGSize,
                             completion: @escaping MediaInputDataProviderCompletion) -> MediaInputDataProviderResourceRequestProtocol {
        if index < self.mediaDataProvider.count {
            return self.mediaDataProvider.requestPreviewImage(at: index, targetSize: targetSize, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestPreviewImage(at: index, targetSize: targetSize, completion: completion)
        }
    }

    @discardableResult
    func requestResource(at index: Int,
                         progressHandler: MediaInputDataProviderProgressHandler?,
                         completion: @escaping MediaInputDataProviderCompletion) -> MediaInputDataProviderResourceRequestProtocol {
        if index < self.mediaDataProvider.count {
            return self.mediaDataProvider.requestResource(at: index, progressHandler: progressHandler, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestResource(at: index, progressHandler: progressHandler, completion: completion)
        }
    }

    func resourceRequest(at index: Int) -> MediaInputDataProviderResourceRequestProtocol? {
        if index < self.mediaDataProvider.count {
            return self.mediaDataProvider.resourceRequest(at: index)
        } else {
            return self.placeholdersDataProvider.resourceRequest(at: index)
        }
    }

    // MARK: MediaInputDataProviderDelegate

    func handlePhotosInputDataProviderUpdate(_ dataProvider: MediaInputDataProviderProtocol, updateBlock: @escaping () -> Void) {
        self.delegate?.handlePhotosInputDataProviderUpdate(self, updateBlock: updateBlock)
    }
}
