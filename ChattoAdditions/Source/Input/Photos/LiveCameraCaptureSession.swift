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

protocol LiveCameraCaptureSessionProtocol {
    var captureLayer: AVCaptureVideoPreviewLayer? { get }
    var isInitialized: Bool { get }
    var isCapturing: Bool { get }
    func startCapturing(_ completion: () -> Void)
    func stopCapturing(_ completion: () -> Void)
}

class LiveCameraCaptureSession: LiveCameraCaptureSessionProtocol {

    var isInitialized: Bool = false

    var isCapturing: Bool {
        return self.isInitialized && self.captureSession.isRunning
    }

    deinit {
        var layer = self.captureLayer
        layer?.removeFromSuperlayer()
        var session: AVCaptureSession? = self.isInitialized ? self.captureSession : nil
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            // Analogously to AVCaptureSession creation, dealloc can take very long, so let's do it out of the main thread
            if layer != nil { layer = nil }
            if session != nil { session = nil }
        }
    }

    func startCapturing(_ completion: @escaping () -> Void) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let sSelf = self, let strongOperation = operation , !strongOperation.isCancelled else { return }
            sSelf.addInputDevicesIfNeeded()
            sSelf.captureSession.startRunning()
            DispatchQueue.main.async(execute: completion)
        }
        self.queue.cancelAllOperations()
        self.queue.addOperation(operation)
    }

    func stopCapturing(_ completion: @escaping () -> Void) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let sSelf = self, let strongOperation = operation , !strongOperation.isCancelled else { return }
            sSelf.captureSession.stopRunning()
            sSelf.removeInputDevices()
            DispatchQueue.main.async(execute: completion)
        }
        self.queue.cancelAllOperations()
        self.queue.addOperation(operation)
    }

    fileprivate (set) var captureLayer: AVCaptureVideoPreviewLayer?

    fileprivate lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    fileprivate lazy var captureSession: AVCaptureSession = {
        assert(!Thread.isMainThread, "This can be very slow, make sure it happens in a background thread")

        let session = AVCaptureSession()
        self.captureLayer = AVCaptureVideoPreviewLayer(session: session)
        self.captureLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.isInitialized = true
        return session
    }()

    fileprivate func addInputDevicesIfNeeded() {
        assert(!Thread.isMainThread, "This can be very slow, make sure it happens in a background thread")
        if self.captureSession.inputs?.count == 0 {
            let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            do {
                let input = try AVCaptureDeviceInput(device: device)
                self.captureSession.addInput(input)
            } catch {

            }
        }
    }

    fileprivate func removeInputDevices() {
        assert(!Thread.isMainThread, "This can be very slow, make sure it happens in a background thread")
        self.captureSession.inputs?.forEach { (input) in
            self.captureSession.removeInput(input as! AVCaptureInput)
        }
    }
}
