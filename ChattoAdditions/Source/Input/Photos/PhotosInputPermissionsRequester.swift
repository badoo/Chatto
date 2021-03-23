//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import AVFoundation
import Photos

public protocol PhotosInputPermissionsRequesterDelegate: AnyObject {
    func requester(_ requester: PhotosInputPermissionsRequesterProtocol, didReceiveUpdatedCameraPermissionStatus status: AVAuthorizationStatus)
    func requester(_ requester: PhotosInputPermissionsRequesterProtocol, didReceiveUpdatedPhotosPermissionStatus status: PHAuthorizationStatus)
}

public protocol PhotosInputPermissionsRequesterProtocol: AnyObject {
    var delegate: PhotosInputPermissionsRequesterDelegate? { get set }

    var cameraAuthorizationStatus: AVAuthorizationStatus { get }
    var photoLibraryAuthorizationStatus: PHAuthorizationStatus { get }

    func requestAccessToCamera()
    func requestAccessToPhotos()
}

final class PhotosInputPermissionsRequester: PhotosInputPermissionsRequesterProtocol {

    // MARK: - PhotosInputPermissionsRequesterProtocol

    weak var delegate: PhotosInputPermissionsRequesterDelegate?

    var cameraAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }

    var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }

    func requestAccessToCamera() {
        self.needsToRequestVideoPermission = true
        self.requestNeededPermissions()
    }

    func requestAccessToPhotos() {
        self.needsToRequestPhotosPermission = true
        self.requestNeededPermissions()
    }

    // MARK: - Private properties

    private var needsToRequestVideoPermission: Bool = false
    private var needsToRequestPhotosPermission: Bool = false

    private var isRequestingPermission: Bool = false

    // MARK: - Private methods

    private func requestNeededPermissions() {
        guard self.isRequestingPermission == false else { return }
        if self.needsToRequestPhotosPermission {
            self.requestPhotosPermission()
        }
        if self.needsToRequestVideoPermission {
            self.requestVideoPermission()
        }
    }

    private func requestVideoPermission() {
        guard self.needsToRequestVideoPermission else { return }
        self.needsToRequestVideoPermission = false
        self.isRequestingPermission = true
        AVCaptureDevice.requestAccess(for: .video) { (_) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.isRequestingPermission = false
                self.delegate?.requester(self, didReceiveUpdatedCameraPermissionStatus: self.cameraAuthorizationStatus)
                self.requestNeededPermissions()
            })
        }
    }

    private func requestPhotosPermission() {
        guard self.needsToRequestPhotosPermission else { return }
        self.needsToRequestPhotosPermission = false
        self.isRequestingPermission = true
        PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.isRequestingPermission = false
                self.delegate?.requester(self, didReceiveUpdatedPhotosPermissionStatus: status)
                self.requestNeededPermissions()
            })
        }
    }
}
