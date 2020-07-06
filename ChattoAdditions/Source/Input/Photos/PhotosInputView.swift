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
import Photos
import Chatto

public struct PhotosInputViewAppearance {
    public var liveCameraCellAppearence: LiveCameraCellAppearance
    public init(liveCameraCellAppearence: LiveCameraCellAppearance) {
        self.liveCameraCellAppearence = liveCameraCellAppearence
    }
}

public protocol PhotosInputViewProtocol {
    var delegate: PhotosInputViewDelegate? { get set }
    var presentingController: UIViewController? { get }
}

public enum PhotosInputViewPhotoSource {
    case camera
    case gallery
}

public protocol PhotosInputViewDelegate: AnyObject {
    func inputView(_ inputView: PhotosInputViewProtocol,
                   didSelectImage image: UIImage,
                   source: PhotosInputViewPhotoSource)
    func inputViewDidRequestCameraPermission(_ inputView: PhotosInputViewProtocol)
    func inputViewDidRequestPhotoLibraryPermission(_ inputView: PhotosInputViewProtocol)
}

public final class PhotosInputView: UIView, PhotosInputViewProtocol {

    fileprivate struct Constants {
        static let liveCameraItemIndex = 0
    }

    fileprivate lazy var collectionViewQueue = SerialTaskQueue()
    fileprivate var collectionView: UICollectionView!
    fileprivate var collectionViewLayout: UICollectionViewFlowLayout!
    fileprivate var dataProvider: PhotosInputDataProviderProtocol!
    fileprivate var cellProvider: PhotosInputCellProviderProtocol!
    fileprivate var itemSizeCalculator: PhotosInputViewItemSizeCalculator!

    var cameraAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }

    var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }

    public weak var delegate: PhotosInputViewDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    public var presentingControllerProvider: () -> UIViewController? = { nil }

    public var presentingController: UIViewController? {
        return self.presentingControllerProvider()
    }

    var appearance: PhotosInputViewAppearance?

    public init(presentingControllerProvider: @escaping () -> UIViewController?,
                appearance: PhotosInputViewAppearance) {
        self.presentingControllerProvider = presentingControllerProvider
        super.init(frame: CGRect.zero)
        self.appearance = appearance
        self.commonInit()
    }

    public convenience init(presentingController: UIViewController?,
                            appearance: PhotosInputViewAppearance) {
        self.init(presentingControllerProvider: { [weak presentingController] in presentingController },
                  appearance: appearance)
    }

    deinit {
        self.collectionView.dataSource = nil
        self.collectionView.delegate = nil
    }

    private func commonInit() {
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.configureCollectionView()
        self.configureItemSizeCalculator()
        self.dataProvider = PhotosInputPlaceholderDataProvider()
        self.cellProvider = PhotosInputPlaceholderCellProvider(collectionView: self.collectionView)
        self.collectionViewQueue.start()
        self.requestAccessToVideo()
        self.requestAccessToPhoto()
    }

    private func configureItemSizeCalculator() {
        self.itemSizeCalculator = PhotosInputViewItemSizeCalculator()
        self.itemSizeCalculator.itemsPerRow = 3
        self.itemSizeCalculator.interitemSpace = 1
    }

    private func requestAccessToVideo() {
        guard self.cameraAuthorizationStatus != .authorized else { return }

        AVCaptureDevice.requestAccess(for: .video) { (_) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.reloadVideoItem()
            })
        }
    }

    private func reloadVideoItem() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            sSelf.collectionView.performBatchUpdates({
                sSelf.collectionView.reloadItems(at: [IndexPath(item: Constants.liveCameraItemIndex, section: 0)])
            }, completion: { (_) in
                DispatchQueue.main.async(execute: completion)
            })
        }
    }

    private func requestAccessToPhoto() {
        guard self.photoLibraryAuthorizationStatus != .authorized else {
            self.replacePlaceholderItemsWithPhotoItems()
            return
        }

        PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) -> Void in
            if status == PHAuthorizationStatus.authorized {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.replacePlaceholderItemsWithPhotoItems()
                })
            }
        }
    }

    private func replacePlaceholderItemsWithPhotoItems() {
        let photosDataProvider = PhotosInputDataProvider()
        photosDataProvider.prepare { [weak self] in
            guard let sSelf = self else { return }

            sSelf.collectionViewQueue.addTask { [weak self] (completion) in
                guard let sSelf = self else { return }

                let newDataProvider = PhotosInputWithPlaceholdersDataProvider(photosDataProvider: photosDataProvider, placeholdersDataProvider: PhotosInputPlaceholderDataProvider())
                newDataProvider.delegate = sSelf
                sSelf.dataProvider = newDataProvider
                sSelf.cellProvider = PhotosInputCellProvider(collectionView: sSelf.collectionView, dataProvider: newDataProvider)
                sSelf.collectionView.reloadData()
                DispatchQueue.main.async(execute: completion)
            }
        }
    }

    func reload() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            self?.collectionView.reloadData()
            DispatchQueue.main.async(execute: completion)
        }
    }

    fileprivate lazy var cameraPicker: PhotosInputCameraPicker = {
        return PhotosInputCameraPicker(presentingControllerProvider: self.presentingControllerProvider)
    }()

    fileprivate lazy var liveCameraPresenter: LiveCameraCellPresenter = {
        return LiveCameraCellPresenter(cellAppearance: self.appearance?.liveCameraCellAppearence ?? LiveCameraCellAppearance.createDefaultAppearance())
    }()
}

extension PhotosInputView: UICollectionViewDataSource {

    func configureCollectionView() {
        self.collectionViewLayout = PhotosInputCollectionViewLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.collectionViewLayout)
        self.collectionView.backgroundColor = UIColor.white
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        LiveCameraCellPresenter.registerCells(collectionView: self.collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.addSubview(self.collectionView)
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataProvider.count + 1
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        if indexPath.item == Constants.liveCameraItemIndex {
            cell = self.liveCameraPresenter.dequeueCell(collectionView: collectionView, indexPath: indexPath)
        } else {
            cell = self.cellProvider.cellForItem(at: indexPath)
        }
        return cell
    }
}

extension PhotosInputView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            if self.cameraAuthorizationStatus != .authorized {
                self.delegate?.inputViewDidRequestCameraPermission(self)
            } else {
                self.liveCameraPresenter.cameraPickerWillAppear()
                self.cameraPicker.presentCameraPicker(onImageTaken: { [weak self] (image) in
                    guard let sSelf = self else { return }

                    if let image = image {
                        sSelf.delegate?.inputView(sSelf, didSelectImage: image, source: .camera)
                    }
                }, onCameraPickerDismissed: { [weak self] in
                    self?.liveCameraPresenter.cameraPickerDidDisappear()
                })
            }
        } else {
            if self.photoLibraryAuthorizationStatus != .authorized {
                self.delegate?.inputViewDidRequestPhotoLibraryPermission(self)
            } else {
                let request = self.dataProvider.requestFullImage(at: indexPath.item - 1, progressHandler: nil, completion: { [weak self] result in
                    guard let sSelf = self, let image = result.image else { return }
                    sSelf.delegate?.inputView(sSelf, didSelectImage: image, source: .gallery)
                })
                self.cellProvider.configureFullImageLoadingIndicator(at: indexPath, request: request)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSizeCalculator.itemSizeForWidth(collectionView.bounds.width, atIndex: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemSizeCalculator.interitemSpace
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemSizeCalculator.interitemSpace
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            self.liveCameraPresenter.cellWillBeShown(cell)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            self.liveCameraPresenter.cellWasHidden(cell)
        }
    }
}

extension PhotosInputView: PhotosInputDataProviderDelegate {
    func handlePhotosInputDataProviderUpdate(_ dataProvider: PhotosInputDataProviderProtocol, updateBlock: @escaping () -> Void) {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            updateBlock()
            sSelf.collectionView.reloadData()
            DispatchQueue.main.async(execute: completion)
        }
    }

}

private class PhotosInputCollectionViewLayout: UICollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.width != self.collectionView?.bounds.width
    }
}
