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

protocol PhotosInputViewProtocol {
    weak var delegate: PhotosInputViewDelegate? { get set }
    weak var presentingController: UIViewController? { get }
}

protocol PhotosInputViewDelegate: class {
    func inputView(inputView: PhotosInputViewProtocol, didSelectImage image: UIImage)
    func inputViewDidRequestCameraPermission(inputView: PhotosInputViewProtocol)
    func inputViewDidRequestPhotoLibraryPermission(inputView: PhotosInputViewProtocol)
}

class PhotosInputView: UIView, PhotosInputViewProtocol {

    private struct Constants {
        static let liveCameraItemIndex = 0
    }

    private lazy var collectionViewQueue = SerialTaskQueue()
    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    private var dataProvider: PhotosInputDataProviderProtocol!
    private var cellProvider: PhotosInputCellProviderProtocol!
    private var itemSizeCalculator: PhotosInputViewItemSizeCalculator!

    var cameraAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
    }

    var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }

    weak var delegate: PhotosInputViewDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    weak var presentingController: UIViewController?
    var appearance: PhotosInputViewAppearance?
    init(presentingController: UIViewController?, appearance: PhotosInputViewAppearance) {
        super.init(frame: CGRect.zero)
        self.presentingController = presentingController
        self.appearance = appearance
        self.commonInit()
    }

    deinit {
        self.collectionView.dataSource = nil
        self.collectionView.delegate = nil
    }

    private func commonInit() {
        self.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
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
        guard self.cameraAuthorizationStatus != .Authorized else { return }

        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.reloadVideoItem()
            })
        }
    }

    private func reloadVideoItem() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            sSelf.collectionView.performBatchUpdates({
                sSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: Constants.liveCameraItemIndex, inSection: 0)])
            }, completion: { (finished) in
                dispatch_async(dispatch_get_main_queue(), completion)
            })
        }
    }

    private func requestAccessToPhoto() {
        guard self.photoLibraryAuthorizationStatus != .Authorized else {
            self.replacePlaceholderItemsWithPhotoItems()
            return
        }

        PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) -> Void in
            if status == PHAuthorizationStatus.Authorized {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.replacePlaceholderItemsWithPhotoItems()
                })
            }
        }
    }

    private func replacePlaceholderItemsWithPhotoItems() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            let newDataProvider = PhotosInputWithPlaceholdersDataProvider(photosDataProvider: PhotosInputDataProvider(), placeholdersDataProvider: PhotosInputPlaceholderDataProvider())
            newDataProvider.delegate = sSelf
            sSelf.dataProvider = newDataProvider
            sSelf.cellProvider = PhotosInputCellProvider(collectionView: sSelf.collectionView, dataProvider: newDataProvider)
            sSelf.collectionView.reloadData()
            dispatch_async(dispatch_get_main_queue(), completion)
        }
    }

    func reload() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            self?.collectionView.reloadData()
            dispatch_async(dispatch_get_main_queue(), completion)
        }
    }

    private lazy var cameraPicker: PhotosInputCameraPicker = {
        return PhotosInputCameraPicker(presentingController: self.presentingController)
    }()

    private lazy var liveCameraPresenter = LiveCameraCellPresenter()
}

extension PhotosInputView: UICollectionViewDataSource {

    func configureCollectionView() {
        self.collectionViewLayout = PhotosInputCollectionViewLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.collectionViewLayout)
        self.collectionView.backgroundColor = UIColor.whiteColor()
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.registerClass(LiveCameraCell.self, forCellWithReuseIdentifier: "LiveCameraCell")

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.addSubview(self.collectionView)
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0))
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataProvider.count + 1
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        if indexPath.item == Constants.liveCameraItemIndex {
            let liveCameraCell = collectionView.dequeueReusableCellWithReuseIdentifier("LiveCameraCell", forIndexPath: indexPath) as! LiveCameraCell
            if let liveCameraCellAppearence = self.appearance?.liveCameraCellAppearence {
                liveCameraCell.appearance = liveCameraCellAppearence
            }
            self.liveCameraPresenter.cameraAuthorizationStatus = self.cameraAuthorizationStatus
            cell = liveCameraCell
        } else {
            cell = self.cellProvider.cellForItemAtIndexPath(indexPath)
        }
        return cell
    }
}

extension PhotosInputView: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            if self.cameraAuthorizationStatus != .Authorized {
                self.delegate?.inputViewDidRequestCameraPermission(self)
            } else {
                self.liveCameraPresenter.cameraPickerWillAppear()
                self.cameraPicker.presentCameraPicker(onImageTaken: { [weak self] (image) in
                    guard let sSelf = self else { return }

                    if let image = image {
                        sSelf.delegate?.inputView(sSelf, didSelectImage: image)
                    }
                }, onCameraPickerDismissed: { [weak self] in
                    self?.liveCameraPresenter.cameraPickerDidDisappear()
                })
            }
        } else {
            if self.photoLibraryAuthorizationStatus != .Authorized {
                self.delegate?.inputViewDidRequestPhotoLibraryPermission(self)
            } else {
                self.dataProvider.requestFullImageAtIndex(indexPath.item - 1) { image in
                    self.delegate?.inputView(self, didSelectImage: image)
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.itemSizeCalculator.itemSizeForWidth(collectionView.bounds.width, atIndex: indexPath.item)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.itemSizeCalculator.interitemSpace
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.itemSizeCalculator.interitemSpace
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            self.liveCameraPresenter.cellWillBeShown(cell as! LiveCameraCell)
        }
    }

    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            self.liveCameraPresenter.cellWasHidden(cell as! LiveCameraCell)
        }
    }
}

extension PhotosInputView: PhotosInputDataProviderDelegate {
    func handlePhotosInpudDataProviderUpdate(dataProvider: PhotosInputDataProviderProtocol, updateBlock: () -> Void) {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            updateBlock()
            sSelf.collectionView.reloadData()
            dispatch_async(dispatch_get_main_queue(), completion)
        }
    }

}

private class PhotosInputCollectionViewLayout: UICollectionViewFlowLayout {
    private override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return newBounds.width != self.collectionView?.bounds.width
    }
}
