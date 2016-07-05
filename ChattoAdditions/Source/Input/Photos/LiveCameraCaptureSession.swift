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
    func startCapturing(completion: () -> Void)
    func stopCapturing(completion: () -> Void)
}

class LiveCameraCaptureSession: LiveCameraCaptureSessionProtocol {

    var isInitialized: Bool = false

    var isCapturing: Bool {
        return self.isInitialized && self.captureSession.running
    }

    deinit {
        var layer = self.captureLayer
        layer?.removeFromSuperlayer()
        var session: AVCaptureSession? = self.isInitialized ? self.captureSession : nil
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // Analogously to AVCaptureSession creation, dealloc can take very long, so let's do it out of the main thread
            if layer != nil { layer = nil }
            if session != nil { session = nil }
        }
    }

    func startCapturing(completion: () -> Void) {
        let operation = NSBlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let sSelf = self, strongOperation = operation where !strongOperation.cancelled else { return }
            sSelf.addInputDevicesIfNeeded()
            sSelf.captureSession.startRunning()
            dispatch_async(dispatch_get_main_queue(), completion)
        }
        self.queue.cancelAllOperations()
        self.queue.addOperation(operation)
    }

    func stopCapturing(completion: () -> Void) {
        let operation = NSBlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let sSelf = self, strongOperation = operation where !strongOperation.cancelled else { return }
            sSelf.captureSession.stopRunning()
            sSelf.removeInputDevices()
            dispatch_async(dispatch_get_main_queue(), completion)
        }
        self.queue.cancelAllOperations()
        self.queue.addOperation(operation)
    }

    private (set) var captureLayer: AVCaptureVideoPreviewLayer?

    private lazy var queue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = .UserInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private lazy var captureSession: AVCaptureSession = {
        assert(!NSThread.isMainThread(), "This can be very slow, make sure it happens in a background thread")

        let session = AVCaptureSession()
        self.captureLayer = AVCaptureVideoPreviewLayer(session: session)
        self.captureLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.isInitialized = true
        return session
    }()

    private func addInputDevicesIfNeeded() {
        assert(!NSThread.isMainThread(), "This can be very slow, make sure it happens in a background thread")
        if self.captureSession.inputs?.count == 0 {
            let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            do {
                let input = try AVCaptureDeviceInput(device: device)
                self.captureSession.addInput(input)
            } catch {

            }
        }
    }

    private func removeInputDevices() {
        assert(!NSThread.isMainThread(), "This can be very slow, make sure it happens in a background thread")
        self.captureSession.inputs?.forEach { (input) in
            self.captureSession.removeInput(input as! AVCaptureInput)
        }
    }
}
