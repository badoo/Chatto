//
//  CGRect+AdditionsTests.swift
//  ChattoAdditionsTests
//
//  Created by Anton Schukin on 23/11/2017.
//  Copyright © 2017 Badoo. All rights reserved.
//

import XCTest

class CGRect_AdditionsTests: XCTestCase {
    func testThat_ItReturnsCorrectBoundsRect() {
        let rect = CGRect(x: 10, y: 10, width: 10, height: 10)
        let resultRect = rect.bma_bounds
        let expectedRect = CGRect(x: 0, y: 0, width: 10, height: 10)
        XCTAssertEqual(resultRect, expectedRect)
    }

    func testThat_ItReturnsCorrectCenter() {
        let rect = CGRect(x: 10, y: 10, width: 10, height: 10)
        let resultCenter = rect.bma_center
        let expectedCenter = CGPoint(x: 15, y: 15)
        XCTAssertEqual(resultCenter, expectedCenter)
    }

    func testThat_WhenMaxYIsSet_ThenOriginChangedCorrectly() {
        var rect = CGRect(x: 10, y: 10, width: 10, height: 10)
        let newMaxY: CGFloat = 10
        rect.bma_maxY = newMaxY
        XCTAssertEqual(rect.origin, CGPoint(x: 10, y: 0))
    }

    func testThat_ItRoundsCorrectly() {
        let rect = CGRect(x: 0.25, y: 0.25, width: 0.25, height: 0.25)
        let x1Scale: CGFloat = 1
        XCTAssertEqual(rect.bma_round(scale: x1Scale), CGRect(x: 1, y: 1, width: 1, height: 1))

        let x2Scale: CGFloat = 2
        XCTAssertEqual(rect.bma_round(scale: x2Scale), CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))

        let x3Scale: CGFloat = 3
        XCTAssertEqual(rect.bma_round(scale: x3Scale), CGRect(x: 1/x3Scale, y: 1/x3Scale, width: 1/x3Scale, height: 1/x3Scale))
    }
}
