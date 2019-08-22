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
import UIKit

enum ScreenMetrics {
    case undefined

    /// iPhone 4, 4s
    case inch3_5

    /// iPhone 5, 5s, 5c, SE
    case inch4

    /// iPhone 6, 6s, 7, 8
    case inch4_7

    /// iPhone 6+, 6s+, 7+, 8+
    case inch5_5

    /// iPhone X, XS
    case inch5_8

    /// iPhone XR
    case inch6_1

    /// iPhone XMax
    case inch6_5

    /// iPad, iPad Air, iPad Pro 9.7, iPad Pro 10.5
    case iPad

    /// iPad Pro 12.9
    case iPad_12_9
}

private extension ScreenMetrics {
    var heightInPoints: CGFloat {
        switch self {
        case .undefined: // iPhoneX
            return 812
        case .inch3_5:
            return 480
        case .inch4:
            return 568
        case .inch4_7:
            return 667
        case .inch5_5:
            return 736
        case .inch5_8:
            return 812
        case .inch6_1, .inch6_5:
            return 896
        case .iPad:
            return 1024
        case .iPad_12_9:
            return 1366
        }
    }
}

extension UIScreen {
    private var epsilon: CGFloat {
        return 1/self.scale
    }

    var pointsPerPixel: CGFloat {
        return self.epsilon
    }

    var screenMetric: ScreenMetrics {
        let screenHeight = self.fixedCoordinateSpace.bounds.height
        switch screenHeight {
        case ScreenMetrics.inch3_5.heightInPoints:
            return .inch3_5
        case ScreenMetrics.inch4.heightInPoints:
            return .inch4
        case ScreenMetrics.inch4_7.heightInPoints:
            return .inch4_7
        case ScreenMetrics.inch5_5.heightInPoints:
            return .inch5_5
        case ScreenMetrics.inch5_8.heightInPoints:
            return .inch5_8
        case ScreenMetrics.inch6_1.heightInPoints:
            return .inch6_1
        case ScreenMetrics.inch6_5.heightInPoints:
            return .inch6_5
        case ScreenMetrics.iPad.heightInPoints:
            return .iPad
        case ScreenMetrics.iPad_12_9.heightInPoints:
            return .iPad_12_9
        default:
            return .undefined
        }
    }

    var defaultPortraitKeyboardHeight: CGFloat {
        switch self.screenMetric {
        case .inch3_5, .inch4:
            return 253
        case .inch4_7:
            return 260
        case .inch5_5:
            return 271
        case .inch5_8:
            return 335
        case .inch6_1, .inch6_5:
            return 346
        case .iPad:
            return 313
        case .iPad_12_9:
            return 378
        case .undefined:
            return 335 // iPhoneX
        }
    }

    var defaultLandscapeKeyboardHeight: CGFloat {
        switch self.screenMetric {
        case .inch3_5, .inch4:
            return 199
        case .inch4_7, .inch5_5:
            return 200
        case .inch5_8, .inch6_1, .inch6_5:
            return 209
        case .iPad:
            return 398
        case .iPad_12_9:
            return 471
        case .undefined:
            return 209 // iPhone X
        }
    }

    public var defaultKeyboardHeightForCurrentOrientation: CGFloat {
        if UIDevice.current.orientation.isPortrait {
            return self.defaultPortraitKeyboardHeight
        } else {
            return self.defaultLandscapeKeyboardHeight
        }
    }
}
