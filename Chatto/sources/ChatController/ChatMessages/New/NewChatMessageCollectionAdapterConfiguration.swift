//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public extension NewChatMessageCollectionAdapter {
    struct Configuration {
        public var autoloadingFractionalThreshold: CGFloat
        public var coalesceUpdates: Bool
        public var fastUpdates: Bool
        public var isRegisteringPresentersAutomatically: Bool
        public var preferredMaxMessageCount: Int?
        public var preferredMaxMessageCountAdjustment: Int
        public var updatesAnimationDuration: TimeInterval

        public init(autoloadingFractionalThreshold: CGFloat,
                    coalesceUpdates: Bool,
                    fastUpdates: Bool,
                    isRegisteringPresentersAutomatically: Bool,
                    preferredMaxMessageCount: Int?,
                    preferredMaxMessageCountAdjustment: Int,
                    updatesAnimationDuration: TimeInterval) {
            self.autoloadingFractionalThreshold = autoloadingFractionalThreshold
            self.coalesceUpdates = coalesceUpdates
            self.fastUpdates = fastUpdates
            self.isRegisteringPresentersAutomatically = isRegisteringPresentersAutomatically
            self.preferredMaxMessageCount = preferredMaxMessageCount
            self.preferredMaxMessageCountAdjustment = preferredMaxMessageCountAdjustment
            self.updatesAnimationDuration = updatesAnimationDuration
        }
    }
}

public extension NewChatMessageCollectionAdapter.Configuration {
    static var `default`: Self {
        return .init(
            autoloadingFractionalThreshold: 0.05,
            coalesceUpdates: true,
            fastUpdates: true,
            isRegisteringPresentersAutomatically: true,
            preferredMaxMessageCount: 500,
            preferredMaxMessageCountAdjustment: 400,
            updatesAnimationDuration: 0.33
        )
    }
}

