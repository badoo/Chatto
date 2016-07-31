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

import Foundation
import Photos

final class LiveCameraCellPresenter {

    deinit {
        self.unsubscribeFromAppNotifications()
    }

    private weak var cell: LiveCameraCell?

    func cellWillBeShown(cell: LiveCameraCell) {
        self.cell = cell
        self.configureCell()
        self.startCapturing()
    }

    func cellWasHidden(cell: LiveCameraCell) {
        if self.cell === cell {
            cell.captureLayer = nil
            self.cell = nil
            self.stopCapturing()
        }
    }

    private func configureCell() {
        guard let cameraCell = self.cell else { return }

        cameraCell.updateWithAuthorizationStatus(self.cameraAuthorizationStatus)

        if self.captureSession.isCapturing {
            cameraCell.captureLayer = self.captureSession.captureLayer
        } else {
            cameraCell.captureLayer = nil
        }

        cameraCell.onWasAddedToWindow = { [weak self] (cell) in
            guard let sSelf = self where sSelf.cell === cell else { return }
            if !sSelf.cameraPickerIsVisible {
                sSelf.startCapturing()
            }
        }

        cameraCell.onWasRemovedFromWindow = { [weak self] (cell) in
            guard let sSelf = self where sSelf.cell === cell else { return }
            if !sSelf.cameraPickerIsVisible {
                sSelf.stopCapturing()
            }
        }
    }

    // MARK: - App Notifications
    lazy var notificationCenter = NSNotificationCenter.defaultCenter()

    private func subscribeToAppNotifications() {
        self.notificationCenter.addObserver(self, selector: #selector(LiveCameraCellPresenter.handleWillResignActiveNotification), name: UIApplicationWillResignActiveNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(LiveCameraCellPresenter.handleDidBecomeActiveNotification), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    private func unsubscribeFromAppNotifications() {
        self.notificationCenter.removeObserver(self)
    }

    private var needsRestoreCaptureSession = false

    @objc
    private func handleWillResignActiveNotification() {
        if self.captureSession.isCapturing ?? false {
            self.needsRestoreCaptureSession = true
            self.stopCapturing()
        }
    }

    @objc
    private func handleDidBecomeActiveNotification() {
        if self.needsRestoreCaptureSession {
            self.needsRestoreCaptureSession = false
            self.startCapturing()
        }
    }

    var cameraPickerIsVisible = false
    func cameraPickerWillAppear() {
        self.cameraPickerIsVisible = true
        self.stopCapturing()
    }

    func cameraPickerDidDisappear() {
        self.cameraPickerIsVisible = false
        self.startCapturing()
    }

    func startCapturing() {
        guard self.isCaptureAvailable, let _ = self.cell else { return }

        self.captureSession.startCapturing() { [weak self] in
            self?.cell?.captureLayer = self?.captureSession.captureLayer
        }
    }

    func stopCapturing() {
        guard self.isCaptureAvailable else { return }

        self.captureSession.stopCapturing() { [weak self] in
            self?.cell?.captureLayer = nil
        }
    }

    private var isCaptureAvailable: Bool {
        switch self.cameraAuthorizationStatus {
        case .NotDetermined, .Restricted, .Denied:
            return false
        case .Authorized:
            return true
        }
    }

    lazy var captureSession: LiveCameraCaptureSessionProtocol = LiveCameraCaptureSession()

    var cameraAuthorizationStatus: AVAuthorizationStatus = .NotDetermined {
        didSet {
            if self.isCaptureAvailable {
                self.subscribeToAppNotifications()
            } else {
                self.unsubscribeFromAppNotifications()
            }
        }
    }
}
