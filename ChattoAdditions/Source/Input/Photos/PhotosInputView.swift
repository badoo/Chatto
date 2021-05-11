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

public protocol PhotosInputViewProtocol {
    var delegate: PhotosInputViewDelegate? { get set }
}

public enum CameraType {
    case front, rear
}

public enum PhotosInputViewPhotoSource: Equatable {
    case camera(CameraType)
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

    public typealias LiveCameraCellPressedAction = () -> Void
    public typealias PhotoCellPressedAction = () -> Void

    fileprivate struct Constants {
        static let liveCameraItemIndex = 0
    }

    fileprivate lazy var collectionViewQueue = SerialTaskQueue()
    fileprivate var collectionView: UICollectionView!
    fileprivate var collectionViewLayout: UICollectionViewFlowLayout!
    fileprivate var dataProvider: PhotosInputDataProviderProtocol!
    fileprivate var cellProvider: PhotosInputCellProviderProtocol!
    fileprivate var permissionsRequester: PhotosInputPermissionsRequesterProtocol!
    fileprivate var itemSizeCalculator: PhotosInputViewItemSizeCalculator!

    var cameraAuthorizationStatus: AVAuthorizationStatus {
        return self.permissionsRequester.cameraAuthorizationStatus
    }

    var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        return self.permissionsRequester.photoLibraryAuthorizationStatus
    }

    public weak var delegate: PhotosInputViewDelegate?
    public var onLiveCameraCellPressed: LiveCameraCellPressedAction?
    public var onPhotoCellPressed: PhotoCellPressedAction?

    private let cameraPickerFactory: PhotosInputCameraPickerFactoryProtocol
    private let liveCameraCellPresenterFactory: LiveCameraCellPresenterFactoryProtocol

    public init(cameraPickerFactory: PhotosInputCameraPickerFactoryProtocol,
                liveCameraCellPresenterFactory: LiveCameraCellPresenterFactoryProtocol) {
        self.cameraPickerFactory = cameraPickerFactory
        self.liveCameraCellPresenterFactory = liveCameraCellPresenterFactory

        super.init(frame: CGRect.zero)

        self.commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        self.permissionsRequester = PhotosInputPermissionsRequester()
        self.permissionsRequester.delegate = self
        self.collectionViewQueue.start()
        self.requestAccessToPhoto()
        self.requestAccessToVideo()
    }

    private func configureItemSizeCalculator() {
        self.itemSizeCalculator = PhotosInputViewItemSizeCalculator()
        self.itemSizeCalculator.itemsPerRow = 3
        self.itemSizeCalculator.interitemSpace = 1
    }

    private func requestAccessToVideo() {
        guard self.cameraAuthorizationStatus != .authorized else { return }
        self.permissionsRequester.requestAccessToCamera()
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
        self.permissionsRequester.requestAccessToPhotos()
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

    fileprivate lazy var cameraPicker: PhotosInputCameraPickerProtocol = {
        return self.cameraPickerFactory.makePhotosInputCameraPicker()
    }()

    fileprivate lazy var liveCameraPresenter: LiveCameraCellPresenterProtocol = {
        return self.liveCameraCellPresenterFactory.makeLiveCameraCellPresenter()
    }()
}

extension PhotosInputView: UICollectionViewDataSource {

    func configureCollectionView() {
        self.collectionViewLayout = PhotosInputCollectionViewLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.collectionViewLayout)
        self.collectionView.backgroundColor = UIColor.white
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.liveCameraPresenter.registerCells(collectionView: self.collectionView)

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.addSubview(self.collectionView)
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
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
            self.onLiveCameraCellPressed?()
            if self.cameraAuthorizationStatus != .authorized {
                self.delegate?.inputViewDidRequestCameraPermission(self)
            } else {
                self.liveCameraPresenter.cameraPickerWillAppear()
                self.cameraPicker.presentCameraPicker(onImageTaken: { [weak self] (result) in
                    guard let sSelf = self else { return }
                    if let result = result {
                        sSelf.delegate?.inputView(sSelf, didSelectImage: result.image, source: .camera(result.cameraType))
                    }
                }, onCameraPickerDismissed: { [weak self] in
                    self?.liveCameraPresenter.cameraPickerDidDisappear()
                })
            }
        } else {
            self.onPhotoCellPressed?()
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

extension PhotosInputView: PhotosInputPermissionsRequesterDelegate {
    public func requester(_ requester: PhotosInputPermissionsRequesterProtocol, didReceiveUpdatedCameraPermissionStatus status: AVAuthorizationStatus) {
        self.reloadVideoItem()
    }

    public func requester(_ requester: PhotosInputPermissionsRequesterProtocol, didReceiveUpdatedPhotosPermissionStatus status: PHAuthorizationStatus) {
        guard status == .authorized else { return }
        self.replacePlaceholderItemsWithPhotoItems()
    }
}

private class PhotosInputCollectionViewLayout: UICollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.width != self.collectionView?.bounds.width
    }
}
