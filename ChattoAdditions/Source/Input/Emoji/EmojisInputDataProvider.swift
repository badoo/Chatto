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

protocol EmojisInputDataProviderDelegate: class {
    func handleEmojisInpudDataProviderUpdate(_ dataProvider: EmojisInputDataProviderProtocol, updateBlock: @escaping () -> Void)
}

protocol EmojisInputDataProviderProtocol {
    weak var delegate: EmojisInputDataProviderDelegate? { get set }
    var count: Int { get }
    func requestPreviewImageAtIndex(_ index: Int, targetSize: CGSize, completion: @escaping (UIImage) -> Void) -> Int32
    func requestFileURLAtIndex(_ index: Int, completion: @escaping (URL?) -> Void)
    func cancelPreviewImageRequest(_ requestID: Int32)
}

class EmojisInputPlaceholderDataProvider: EmojisInputDataProviderProtocol {
    weak var delegate: EmojisInputDataProviderDelegate?

    let numberOfPlaceholders: Int

    init(numberOfPlaceholders: Int = 5) {
        self.numberOfPlaceholders = numberOfPlaceholders
    }

    var count: Int {
        return self.numberOfPlaceholders
    }

    func requestPreviewImageAtIndex(_ index: Int, targetSize: CGSize, completion: @escaping (UIImage) -> Void) -> Int32 {
        return 0
    }

    func requestFileURLAtIndex(_ index: Int, completion: @escaping (URL?) -> Void) {
    }

    func cancelPreviewImageRequest(_ requestID: Int32) {
    }
}

@objc
class EmojisInputDataProvider: NSObject, EmojisInputDataProviderProtocol {
    weak var delegate: EmojisInputDataProviderDelegate?
    private var imageManager = PHCachingImageManager()
    private var fetchResult: PHFetchResult<PHAsset>!
    override init() {
        func fetchOptions(_ predicate: NSPredicate?) -> PHFetchOptions {
            let options = PHFetchOptions()
            options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
            if #available(iOS 9.0, *) {
                options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
            }
            options.predicate = predicate
            return options
        }

        if let userLibraryCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject {
            self.fetchResult = PHAsset.fetchAssets(in: userLibraryCollection, options: fetchOptions(NSPredicate(format: "mediaType = \(PHAssetMediaType.image.rawValue)")))
        } else {
            self.fetchResult = PHAsset.fetchAssets(with: fetchOptions(nil))
        }
        super.init()
    }

    deinit {
    }

    var count: Int {
        return self.fetchResult.count
    }

    func requestPreviewImageAtIndex(_ index: Int, targetSize: CGSize, completion: @escaping (UIImage) -> Void) -> Int32 {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        let asset = self.fetchResult[index]
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        return self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (image, info) in
            if let image = image {
                completion(image)
            }
        }
    }

    func cancelPreviewImageRequest(_ requestID: Int32) {
        self.imageManager.cancelImageRequest(requestID)
    }

    func requestFileURLAtIndex(_ index: Int, completion: @escaping (URL?) -> Void) {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        let asset = self.fetchResult[index] as! PHAsset
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
        if asset.mediaType == .video {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("mergeVideo\(arc4random()%1000)d").appendingPathExtension("mov")
            if FileManager.default.fileExists(atPath: outputURL.absoluteString) {
                try! FileManager.default.removeItem(atPath: outputURL.absoluteString)
            }
            self.imageManager.requestExportSession(forVideo: asset, options: .none, exportPreset: AVAssetExportPresetMediumQuality) {(session, info) -> Void in
                if let session = session {
                    session.outputFileType = AVFileTypeQuickTimeMovie
                    session.outputURL = outputURL
                    session.exportAsynchronously { () -> Void in
                        if session.status == .completed {
                            completion(outputURL)
                        } else {
                            completion(nil)
                        }
                    }
                } else {
                    completion(nil)
                }
            }
        } else if asset.mediaType == .image {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            self.imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) -> Void in
                if let degraded = info?[PHImageResultIsDegradedKey] as? Bool, degraded {
                    return
                }
                if let image = image, let data = UIImageJPEGRepresentation(image, 1.0) {
                    let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("image\(arc4random()%1000)d").appendingPathExtension("jpg")
                    if FileManager.default.fileExists(atPath: outputURL.absoluteString) {
                        try! FileManager.default.removeItem(atPath: outputURL.absoluteString)
                    }
                    if (try? data.write(to: outputURL, options: .atomic)) != nil {
                        completion(outputURL)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }


    // MARK: PHEmojiLibraryChangeObserver

    func emojiLibraryDidChange(_ changeInstance: PHChange) {
        // Emojis may call this method on a background queue; switch to the main queue to update the UI.
        DispatchQueue.main.async { [weak self]  in
            guard let sSelf = self else { return }

            if let changeDetails = changeInstance.changeDetails(for: sSelf.fetchResult as! PHFetchResult<PHObject>) {
                let updateBlock = { () -> Void in
                    self?.fetchResult = changeDetails.fetchResultAfterChanges as! PHFetchResult<PHAsset>
                }
                sSelf.delegate?.handleEmojisInpudDataProviderUpdate(sSelf, updateBlock: updateBlock)
            }
        }
    }
}

class EmojisInputWithPlaceholdersDataProvider: EmojisInputDataProviderProtocol, EmojisInputDataProviderDelegate {
    weak var delegate: EmojisInputDataProviderDelegate?
    private let emojisDataProvider: EmojisInputDataProviderProtocol
    private let placeholdersDataProvider: EmojisInputDataProviderProtocol

    init(emojisDataProvider: EmojisInputDataProviderProtocol, placeholdersDataProvider: EmojisInputDataProviderProtocol) {
        self.emojisDataProvider = emojisDataProvider
        self.placeholdersDataProvider = placeholdersDataProvider
        self.emojisDataProvider.delegate = self
    }

    var count: Int {
        return max(self.emojisDataProvider.count, self.placeholdersDataProvider.count)
    }

    func requestPreviewImageAtIndex(_ index: Int, targetSize: CGSize, completion: @escaping (UIImage) -> Void) -> Int32 {
        if index < self.emojisDataProvider.count {
            return self.emojisDataProvider.requestPreviewImageAtIndex(index, targetSize: targetSize, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestPreviewImageAtIndex(index, targetSize: targetSize, completion: completion)
        }
    }

    func requestFileURLAtIndex(_ index: Int, completion: @escaping (URL?) -> Void) {
        if index < self.emojisDataProvider.count {
            return self.emojisDataProvider.requestFileURLAtIndex(index, completion: completion)
        } else {
            return self.placeholdersDataProvider.requestFileURLAtIndex(index, completion: completion)
        }
    }

    func cancelPreviewImageRequest(_ requestID: Int32) {
        return self.emojisDataProvider.cancelPreviewImageRequest(requestID)
    }

    // MARK: EmojisInputDataProviderDelegate

    func handleEmojisInpudDataProviderUpdate(_ dataProvider: EmojisInputDataProviderProtocol, updateBlock: @escaping () -> Void) {
        self.delegate?.handleEmojisInpudDataProviderUpdate(self, updateBlock: updateBlock)
    }
}
