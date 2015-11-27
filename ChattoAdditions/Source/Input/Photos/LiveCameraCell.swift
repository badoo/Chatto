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

import AVFoundation
import Foundation
import UIKit
import Chatto

protocol LiveCameraCaptureSessionProtocol {
    var captureLayer: AVCaptureVideoPreviewLayer? { get }
    var isCapturing: Bool { get }
    func startCapturing(completion: () -> Void)
    func stopCapturing(completion: () -> Void)
}

class LiveCameraCell: UICollectionViewCell {

    private struct Constants {
        static let backgroundColor = UIColor(red: 24.0/255.0, green: 101.0/255.0, blue: 245.0/255.0, alpha: 1)
        static let cameraImageName = "camera"
        static let lockedCameraImageName = "camera_lock"
    }

    lazy var captureSession: LiveCameraCaptureSessionProtocol = {
        return LiveCameraCaptureSession()
    }()

    private var iconImageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    deinit {
        self.unsubscribeFromAppNotifications()
    }

    private func commonInit() {
        self.configureIcon()
        self.contentView.backgroundColor = Constants.backgroundColor
    }

    private func configureIcon() {
        self.iconImageView = UIImageView()
        self.iconImageView.contentMode = .Center
        self.contentView.addSubview(self.iconImageView)
    }

    private var authorizationStatus: AVAuthorizationStatus = .NotDetermined
    func updateWithAuthorizationStatus(status: AVAuthorizationStatus) {
        self.authorizationStatus = status
        self.updateIcon()

        if self.isCaptureAvailable {
            self.subscribeToAppNotifications()
        } else {
            self.unsubscribeFromAppNotifications()
        }
    }

    private func updateIcon() {
        switch self.authorizationStatus {
        case .NotDetermined, .Authorized:
            self.iconImageView.image = UIImage(named: Constants.cameraImageName, inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)
        case .Restricted, .Denied:
            self.iconImageView.image = UIImage(named: Constants.lockedCameraImageName, inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)
        }
        self.setNeedsLayout()
    }

    private var isCaptureAvailable: Bool {
        switch self.authorizationStatus {
        case .NotDetermined, .Restricted, .Denied:
            return false
        case .Authorized:
            return true
        }
    }

    func startCapturing() {
        guard self.isCaptureAvailable else { return }
        self.captureSession.startCapturing() { [weak self] in
            self?.addCaptureLayer()
        }
    }

    private func addCaptureLayer() {
        guard let captureLayer = self.captureSession.captureLayer else { return }
        self.contentView.layer.insertSublayer(captureLayer, below: self.iconImageView.layer)
        let animation = CABasicAnimation.bma_fadeInAnimationWithDuration(0.25)
        let animationKey = "fadeIn"
        captureLayer.removeAnimationForKey(animationKey)
        captureLayer.addAnimation(animation, forKey: animationKey)
    }

    func stopCapturing() {
        guard self.isCaptureAvailable else { return }
        self.captureSession.stopCapturing() { [weak self] in
            self?.removeCaptureLayer()
        }
    }

    private func removeCaptureLayer() {
        self.captureSession.captureLayer?.removeFromSuperlayer()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if self.isCaptureAvailable {
            self.captureSession.captureLayer?.frame = self.contentView.bounds
        }

        self.iconImageView.sizeToFit()
        self.iconImageView.center = self.contentView.bounds.bma_center
    }

    override func didMoveToWindow() {
        if self.window == nil {
            self.stopCapturing()
        }
    }

    // MARK: - App Notifications
    lazy var notificationCenter = {
        return NSNotificationCenter.defaultCenter()
    }()

    private func subscribeToAppNotifications() {
        self.notificationCenter.addObserver(self, selector: "handleWillResignActiveNotification", name: UIApplicationWillResignActiveNotification, object: nil)
        self.notificationCenter.addObserver(self, selector: "handleDidBecomeActiveNotification", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    private func unsubscribeFromAppNotifications() {
        self.notificationCenter.removeObserver(self)
    }

    private var needsRestoreCaptureSession = false
    func handleWillResignActiveNotification() {
        if self.captureSession.isCapturing {
            self.needsRestoreCaptureSession = true
            self.stopCapturing()
        }
    }

    func handleDidBecomeActiveNotification() {
        if self.needsRestoreCaptureSession {
            self.needsRestoreCaptureSession = false
            self.startCapturing()
        }
    }
}

private class LiveCameraCaptureSession: LiveCameraCaptureSessionProtocol {
    init() {
        self.configureCaptureSession()
    }

    private var captureSession: AVCaptureSession!
    private (set) var captureLayer: AVCaptureVideoPreviewLayer?

    private func configureCaptureSession() {
        self.captureSession = AVCaptureSession()
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            let input = try AVCaptureDeviceInput(device: device)
            self.captureSession.addInput(input)
        } catch {

        }

        self.captureLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.captureLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
    }

    private lazy var queue: KeyedOperationQueue = {
        let queue = KeyedOperationQueue()
        queue.qualityOfService = .UserInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    func startCapturing(completion: () -> Void) {
        let operation = NSBlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let strongSelf = self, strongOperation = operation else { return }
            if !strongOperation.cancelled && !strongSelf.captureSession.running {
                strongSelf.captureSession.startRunning()
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    completion()
                })
            }
        }
        self.queue.addOperation(operation, forKey: "startCapturingOperation")
    }

    func stopCapturing(completion: () -> Void) {
        let operation = NSBlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let strongSelf = self, strongOperation = operation else { return }
            if !strongOperation.cancelled && strongSelf.captureSession.running {
                strongSelf.captureSession.stopRunning()
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    completion()
                })
            }
        }
        self.queue.addOperation(operation, forKey: "stopCapturingOperation")
    }

    var isCapturing: Bool {
        return self.captureSession.running
    }
}
