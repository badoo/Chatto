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
    public var liveCameraHeaderAppearance: LiveCameraHeaderAppearance
    public init(liveCameraHeaderAppearance: LiveCameraHeaderAppearance) {
        self.liveCameraHeaderAppearance = liveCameraHeaderAppearance
    }
}

protocol PhotosInputViewProtocol {
    weak var delegate: PhotosInputViewDelegate? { get set }
    weak var presentingController: UIViewController? { get }
}

protocol PhotosInputViewDelegate: class {
    func inputView(_ inputView: PhotosInputViewProtocol, didSelectImage image: URL?)
    func inputViewSelectImages(_ inputView: PhotosInputViewProtocol, selectImageList image: [(index: IndexPath, url: URL)]?)
    func inputViewDidRequestCameraPermission(_ inputView: PhotosInputViewProtocol)
    func inputViewDidRequestPhotoLibraryPermission(_ inputView: PhotosInputViewProtocol)
}

class PhotosInputView: UIView, PhotosInputViewProtocol, LiveCameraHeaderPresenterDelegate {

    fileprivate lazy var collectionViewQueue = SerialTaskQueue()
    fileprivate var collectionView: UICollectionView!
    fileprivate var collectionViewLayout: UICollectionViewFlowLayout!
    fileprivate var dataProvider: PhotosInputDataProviderProtocol!
    fileprivate var cellProvider: PhotosInputCellProviderProtocol!
    fileprivate var itemSizeCalculator: PhotosInputViewItemSizeCalculator!
    fileprivate var selectedItemList = [(index: IndexPath, url: URL)]()

    var cameraAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
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
        self.itemSizeCalculator.itemsPerCell = 2
        self.itemSizeCalculator.interitemSpace = 1
    }

    private func requestAccessToVideo() {
        guard self.cameraAuthorizationStatus != .authorized else { return }

        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { (success) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.reloadVideoItem()
            })
        }
    }

    private func reloadVideoItem() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            sSelf.collectionView.performBatchUpdates({
//                sSelf.collectionView.reloadItems(at: [IndexPath(item: Constants.liveCameraItemIndex, section: 0)])
            }, completion: { (finished) in
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
        self.collectionViewQueue.addTask { [weak self] (completion) in
            guard let sSelf = self else { return }

            let newDataProvider = PhotosInputWithPlaceholdersDataProvider(photosDataProvider: PhotosInputDataProvider(), placeholdersDataProvider: PhotosInputPlaceholderDataProvider())
            newDataProvider.delegate = sSelf
            sSelf.dataProvider = newDataProvider
            sSelf.cellProvider = PhotosInputCellProvider(collectionView: sSelf.collectionView, dataProvider: newDataProvider)
            sSelf.collectionView.reloadData()
            DispatchQueue.main.async(execute: completion)
        }
    }

    func reload() {
        self.collectionViewQueue.addTask { [weak self] (completion) in
            self?.collectionView.reloadData()
            DispatchQueue.main.async(execute: completion)
        }
    }

    fileprivate lazy var cameraPicker: PhotosInputCameraPicker = {
        return PhotosInputCameraPicker(presentingController: self.presentingController)
    }()

    fileprivate lazy var liveCameraPresenter: LiveCameraHeaderPresenter = {
        var presenter = LiveCameraHeaderPresenter(headerAppearance: self.appearance?.liveCameraHeaderAppearance ?? LiveCameraHeaderAppearance.createDefaultAppearance())
        presenter.delegate = self
        return presenter
    }()

    public func removeItemFromList(item: (index: IndexPath, url: URL)) {
        for (index, image) in selectedItemList.enumerated() {
            if image.index == item.index {
                selectedItemList.remove(at: index)
                
                if image.index.section != 2 {
                    self.collectionView.reloadItems(at: [image.index])
                }
                
                break
            }
        }
    }
    
    public func getSelectedPhotoItems() -> [(index: IndexPath, url: URL)] {
        return selectedItemList
    }
    
    internal func liveCameraHeaderPresenterImageSavedToPath(_ url: URL) {
        self.selectedItemList.append((index: IndexPath(item: 0, section: 2), url: url))
        self.delegate?.inputViewSelectImages(self, selectImageList: self.selectedItemList)
    }
}

extension PhotosInputView: UICollectionViewDataSource {

    func configureCollectionView() {
        self.collectionViewLayout = PhotosInputCollectionViewLayout()
        self.collectionViewLayout.headerReferenceSize = CGSize(width: 153, height: 1)
        self.collectionViewLayout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.collectionViewLayout)
        self.collectionView.backgroundColor = UIColor.white
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        LiveCameraCellPresenter.registerCells(collectionView: self.collectionView)
        self.collectionView.register(LiveCameraHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.addSubview(self.collectionView)
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 1))
        self.addConstraint(NSLayoutConstraint(item: self.collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataProvider.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: PhotosInputCell

        cell = self.cellProvider.cellForItemAtIndexPath(indexPath) as! PhotosInputCell

        var found: Bool = false
        
        for (index, item) in selectedItemList.enumerated() {
            if item.index == indexPath {
                cell.selectForSend = true
                found = true
                
                break
            }
        }
        
        if !found {
            cell.selectForSend = false
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
            
        case UICollectionElementKindSectionHeader:
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
            headerView.backgroundColor = UIColor.clear
            
            return headerView
            
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath)
            
            footerView.backgroundColor = UIColor.green
            return footerView
            
        default:
            
            assert(false, "Unexpected element kind")
        }
    }
}

extension PhotosInputView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.photoLibraryAuthorizationStatus != .authorized {
            self.delegate?.inputViewDidRequestPhotoLibraryPermission(self)
        } else {
            var cell: PhotosInputCell
            cell = collectionView.cellForItem(at: indexPath) as! PhotosInputCell
            
            var found: Bool = false
            
            for (index, item) in selectedItemList.enumerated() {
                if item.index == indexPath {
                    selectedItemList.remove(at: index)
                    cell.selectForSend = false
                    self.delegate?.inputViewSelectImages(self, selectImageList: self.selectedItemList)
                    found = true
                    
                    break
                }
            }
            
            if !found {
                self.dataProvider.requestFileURLAtIndex(indexPath.item) { image in
                    self.selectedItemList.append((index: indexPath, url: image!))
                    self.delegate?.inputViewSelectImages(self, selectImageList: self.selectedItemList)
                }
                
                cell.selectForSend = true
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSizeCalculator.itemSizeForWidth(collectionView.bounds.height, atIndex: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemSizeCalculator.interitemSpace
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.itemSizeCalculator.interitemSpace
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        self.liveCameraPresenter.cellWillBeShown(view)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        self.liveCameraPresenter.cellWasHidden(view)
    }
}

extension PhotosInputView: PhotosInputDataProviderDelegate {
    func handlePhotosInpudDataProviderUpdate(_ dataProvider: PhotosInputDataProviderProtocol, updateBlock: @escaping () -> Void) {
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
