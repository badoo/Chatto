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

class LiveCameraCaptureSession: LiveCameraCaptureSessionProtocol {

    private enum OperationType: String {
        case start
        case stop
    }

    var isInitialized: Bool = false

    var isCapturing: Bool {
        return self.isInitialized && self.captureSession.running
    }

    deinit {
        var layer = self.captureLayer
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
            guard let strongSelf = self, strongOperation = operation else { return }
            if !strongOperation.cancelled && !strongSelf.captureSession.running {
                strongSelf.captureSession.startRunning()
                dispatch_async(dispatch_get_main_queue(), completion)
            }
        }
        self.queue.cancelOperation(forKey: OperationType.stop.rawValue)
        self.queue.addOperation(operation, forKey: OperationType.start.rawValue)
    }

    func stopCapturing(completion: () -> Void) {
        let operation = NSBlockOperation()
        operation.addExecutionBlock { [weak operation, weak self] in
            guard let strongSelf = self, strongOperation = operation else { return }
            if !strongOperation.cancelled && strongSelf.captureSession.running {
                strongSelf.captureSession.stopRunning()
                dispatch_async(dispatch_get_main_queue(), completion)
            }
        }
        self.queue.cancelOperation(forKey: OperationType.start.rawValue)
        self.queue.addOperation(operation, forKey: OperationType.stop.rawValue)
    }

    private (set) var captureLayer: AVCaptureVideoPreviewLayer?

    private lazy var queue: KeyedOperationQueue = {
        let queue = KeyedOperationQueue()
        queue.qualityOfService = .UserInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private lazy var captureSession: AVCaptureSession = {
        assert(!NSThread.isMainThread(), "This can be very slow, make sure it happens in a background thread")

        let session = AVCaptureSession()
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
        } catch {

        }
        self.captureLayer = AVCaptureVideoPreviewLayer(session: session)
        self.captureLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.isInitialized = true
        return session
    }()
}
