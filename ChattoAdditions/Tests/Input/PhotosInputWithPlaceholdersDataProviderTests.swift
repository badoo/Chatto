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

class PhotosInputWithPlaceholderDataProviderTests: XCTestCase {

    func testThat_GivenProviderWithNumberOfPlaceholdersGreaterThenNumberOfPhotos_ThenCountReturnsGreaterNumber() {
        let numberOfPhotos = 1
        let photosDataProvider = PhotosInputPlaceholderDataProvider(numberOfPlaceholders: numberOfPhotos)
        let numberOfPlaceholders = 10
        let placeholdersDataProvider = PhotosInputPlaceholderDataProvider(numberOfPlaceholders: numberOfPlaceholders)
        let dataProvider = PhotosInputWithPlaceholdersDataProvider(photosDataProvider: photosDataProvider, placeholdersDataProvider: placeholdersDataProvider)
        XCTAssertEqual(numberOfPlaceholders, dataProvider.count)
    }

    func testThat_GivenProviderWithNumberOfPhotosGreaterThenNumberOfPlaceholders_ThenCountReturnsGreaterNumber() {
        let numberOfPhotos = 10
        let photosDataProvider = PhotosInputPlaceholderDataProvider(numberOfPlaceholders: numberOfPhotos)
        let numberOfPlaceholders = 1
        let placeholdersDataProvider = PhotosInputPlaceholderDataProvider(numberOfPlaceholders: numberOfPlaceholders)
        let dataProvider = PhotosInputWithPlaceholdersDataProvider(photosDataProvider: photosDataProvider, placeholdersDataProvider: placeholdersDataProvider)
        XCTAssertEqual(numberOfPhotos, dataProvider.count)
    }
}
