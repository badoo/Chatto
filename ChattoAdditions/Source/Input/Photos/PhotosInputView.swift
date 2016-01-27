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

protocol PhotosInputViewProtocol {
    weak var delegate: PhotosInputViewDelegate? { get set }
    weak var presentingController: UIViewController? { get }
    func reload()
}

protocol PhotosInputViewDelegate: class {
    func inputView(inputView: PhotosInputViewProtocol, didSelectImage image: UIImage)
}

class PhotosInputView: UIView, PhotosInputViewProtocol {

    private struct Constants {
        static let liveCameraItemIndex = 0
    }

    private var collectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    private var dataProvider: PhotosInputDataProviderProtocol!
    private var cellProvider: PhotosInputCellProviderProtocol!
    private var itemSizeCalculator: PhotosInputViewItemSizeCalculator!

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
    init(presentingController: UIViewController?) {
        super.init(frame: CGRect.zero)
        self.presentingController = presentingController
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
        self.requestAccessToVideo()
        self.requestAccessToPhoto()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionViewLayout.invalidateLayout()
    }

    private func configureItemSizeCalculator() {
        self.itemSizeCalculator = PhotosInputViewItemSizeCalculator()
        self.itemSizeCalculator.itemsPerRow = 3
        self.itemSizeCalculator.interitemSpace = 1
    }

    private func requestAccessToVideo() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.reloadVideoItem()
            })
        }
    }

    private func reloadVideoItem() {
        self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: Constants.liveCameraItemIndex, inSection: 0)])
    }

    private func requestAccessToPhoto() {
        PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) -> Void in
            if status == PHAuthorizationStatus.Authorized {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.replacePlaceholderItemsWithPhotoItems()
                })
            }
        }
    }

    private func replacePlaceholderItemsWithPhotoItems() {
        let newDataProvider = PhotosInputDataProvider()
        self.dataProvider = newDataProvider
        self.cellProvider = PhotosInputCellProvider(collectionView: self.collectionView, dataProvider: newDataProvider)
        self.collectionView.reloadSections(NSIndexSet(index: 0))
    }

    func reload() {
        self.collectionView.reloadData()
    }

    private lazy var cameraPicker: PhotosInputCameraPicker = {
        return PhotosInputCameraPicker(presentingController: self.presentingController)
    }()
}

extension PhotosInputView: UICollectionViewDataSource {

    func configureCollectionView() {
        self.collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.collectionViewLayout)
        self.collectionView.backgroundColor = UIColor.whiteColor()
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.registerClass(LiveCameraCell.self, forCellWithReuseIdentifier: "bar")

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
            let liveCameraCell = collectionView.dequeueReusableCellWithReuseIdentifier("bar", forIndexPath: indexPath) as! LiveCameraCell
            liveCameraCell.updateWithAuthorizationStatus(AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo))
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
            self.cameraPicker.requestImage { image in
                if let image = image {
                    self.delegate?.inputView(self, didSelectImage: image)
                }
            }
        } else {
            self.dataProvider.requestFullImageAtIndex(indexPath.item - 1) { image in
                self.delegate?.inputView(self, didSelectImage: image)
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
            (cell as! LiveCameraCell).startCapturing()
        }
    }

    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.item == Constants.liveCameraItemIndex {
            (cell as! LiveCameraCell).stopCapturing()
        }
    }
}
