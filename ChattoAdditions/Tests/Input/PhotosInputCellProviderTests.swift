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

import XCTest
@testable import ChattoAdditions

class PhotosInputCellProviderTests: XCTestCase, UICollectionViewDataSource {
    var collectionView: UICollectionView!
    var fakePhotosProvider: FakePhotosInputDataProvider!
    var sut: PhotosInputCellProvider!

    override func setUp() {
        super.setUp()
        self.collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView.dataSource = self
        self.fakePhotosProvider = FakePhotosInputDataProvider()
        self.fakePhotosProvider.count = 10
        self.sut = PhotosInputCellProvider(collectionView: collectionView, dataProvider: self.fakePhotosProvider)
    }

    override func tearDown() {
        self.sut = nil
        self.fakePhotosProvider = nil
        self.collectionView = nil
        super.tearDown()
    }

    func testThat_WhenRequestCell_ThenPhotoProviderReceivedPreviewPhotoRequest() {
        // Given
        let indexToRequest = 5
        var photoProviderRequested = false
        self.fakePhotosProvider.onRequestPreviewImage = { (_, _, _) in
            photoProviderRequested = true
            return FakePhotosInputDataProviderImageRequest()
        }
        // When
        _ = self.sut.cellForItem(at: IndexPath(row: indexToRequest, section: 0))
        // Then
        XCTAssertTrue(photoProviderRequested)
    }

    func testThat_WhenRequestCell_ThenCellProviderRequestPhotoWithCameraShiftAppliedToIndex() {
        // Given
        let indexToRequest = 5
        var requestedPhotoIndex = NSNotFound
        self.fakePhotosProvider.onRequestPreviewImage = { (index, _, _) in
            requestedPhotoIndex = index
            return FakePhotosInputDataProviderImageRequest()
        }
        // When
        _ = self.sut.cellForItem(at: IndexPath(row: indexToRequest, section: 0))
        // Then
        XCTAssertTrue(requestedPhotoIndex == indexToRequest - 1)
    }

    func testThat_WhenRequestCell_ThenCellProviderCheckExistenceOfFullImageRequest() {
        // Given
        let indexToRequest = 5
        var fullImageRequestRequested = false
        self.fakePhotosProvider.onFullImageRequest = { _ in
            fullImageRequestRequested = true
            return nil
        }
        // When
        _ = self.sut.cellForItem(at: IndexPath(row: indexToRequest, section: 0))
        // Then
        XCTAssertTrue(fullImageRequestRequested)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fakePhotosProvider.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}
