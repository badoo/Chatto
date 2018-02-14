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

#import <UIKit/UIKit.h>
#import "CircleIconView.h"

typedef NS_ENUM(NSUInteger, CircleProgressType) {
  CircleProgressTypeUndefined,
  CircleProgressTypeIcon,
  CircleProgressTypeTimer,
  CircleProgressTypeUpload,
  CircleProgressTypeDownload,
};

typedef NS_ENUM(NSUInteger, CircleProgressStatus) {
  CircleProgressStatusUndefined,
  CircleProgressStatusStarting,
  CircleProgressStatusInProgress,
  CircleProgressStatusCompleted,
  CircleProgressStatusFailed,
};

typedef void(^CircleProgressActionBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@interface CircleProgressIndicatorView : UIView

@property(nonatomic) CircleProgressType progressType;
@property(nonatomic) CircleProgressStatus progressStatus;
@property(nonatomic, strong) UIColor *progressLineColor;
@property(nonatomic, assign) CGFloat progressLineWidth;
@property(nonatomic, copy, nullable) CircleProgressActionBlock actionBlock;

+ (instancetype)defaultProgressIndicatorView;
+ (instancetype)progressIndicatorViewWithSize:(CGSize)size;

- (void)setProgress:(CGFloat)progress;
- (void)setTimerTitle:(nullable NSAttributedString *)title;
- (void)setTextTitle:(nullable NSAttributedString *)title;
- (void)setIconType:(CircleIconType)type;

@end

NS_ASSUME_NONNULL_END
