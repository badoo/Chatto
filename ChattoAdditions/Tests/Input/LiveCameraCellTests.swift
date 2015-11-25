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
import XCTest
@testable import ChattoAdditions

class LiveCameraCellTests: XCTestCase {
    private var cell: LiveCameraCell!
    override func setUp() {
        super.setUp()
        self.cell = LiveCameraCell(frame: CGRect.zero)
        self.cell.notificationCenter = NSNotificationCenter()
    }

    // MARK: - Capture Session
    func testThat_WhenAuthorizationStatusIsNotDetermined_CaptureDoesntStart() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.cell.captureSession = mockCaptureSession
        self.cell.updateWithAuthorizationStatus(.NotDetermined)

        self.cell.startCapturing()

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_WhenAuthorizationStatusIsRestricted_CaptureDoesntStart() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.cell.captureSession = mockCaptureSession
        self.cell.updateWithAuthorizationStatus(.Restricted)

        self.cell.startCapturing()

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_WhenAuthorizationStatusIsDenied_CaptureDoesntStart() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.cell.captureSession = mockCaptureSession
        self.cell.updateWithAuthorizationStatus(.Denied)

        self.cell.startCapturing()

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_WhenAuthorizationStatusIsAuthorized_CaptureStarts() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        self.cell.captureSession = mockCaptureSession
        self.cell.updateWithAuthorizationStatus(.Authorized)

        self.cell.startCapturing()

        XCTAssertTrue(mockCaptureSession.isCapturing)
    }

    func testThat_GivenCaptureSessionIsCapturing_WhenStopCapturingCalled_ThenCaptureSessionStopsCapturing() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        mockCaptureSession.isCapturing = true
        self.cell.captureSession = mockCaptureSession
        self.cell.updateWithAuthorizationStatus(.Authorized)

        self.cell.stopCapturing()

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    // MARK: - App Notifications
    func testThat_GivenCaptureSessionIsCapturingAndAppDidLostFocus_ThenCaptureIsStopped() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        mockCaptureSession.isCapturing = true
        self.cell.captureSession = mockCaptureSession

        self.cell.updateWithAuthorizationStatus(.Authorized)
        self.cell.notificationCenter.postNotificationName(UIApplicationWillResignActiveNotification, object: nil)

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }

    func testThat_GivenCaptureSessionIsCapturingAndAppDidLostFocus_WhenAppReceivesFocus_ThenCaptureIsRestored() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        mockCaptureSession.isCapturing = true
        self.cell.captureSession = mockCaptureSession

        self.cell.updateWithAuthorizationStatus(.Authorized)
        self.cell.notificationCenter.postNotificationName(UIApplicationWillResignActiveNotification, object: nil)
        self.cell.notificationCenter.postNotificationName(UIApplicationDidBecomeActiveNotification, object: nil)

        XCTAssertTrue(mockCaptureSession.isCapturing)
    }

    func testThat_GivenCaptureSessionIsNotCapturingAndAppDidLostFocus_WhenAppReceivesFocus_ThenCaptureIsNotRestored() {
        let mockCaptureSession = MockLiveCameraCaptureSession()
        mockCaptureSession.isCapturing = false
        self.cell.captureSession = mockCaptureSession

        self.cell.updateWithAuthorizationStatus(.Authorized)
        self.cell.notificationCenter.postNotificationName(UIApplicationWillResignActiveNotification, object: nil)
        self.cell.notificationCenter.postNotificationName(UIApplicationDidBecomeActiveNotification, object: nil)

        XCTAssertFalse(mockCaptureSession.isCapturing)
    }
}

private class MockLiveCameraCaptureSession: LiveCameraCaptureSessionProtocol {
    var captureLayer: AVCaptureVideoPreviewLayer? {
        return nil
    }

    var isCapturing: Bool = false
    func startCapturing(completion: () -> Void) {
        self.isCapturing = true
        completion()
    }
    func stopCapturing(completion: () -> Void) {
        self.isCapturing = false
        completion()
    }
}
