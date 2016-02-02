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

#import "CircleProgressIndicatorView.h"
#import "CircleProgressView.h"

@interface CircleProgressIndicatorView ()
@property(nonatomic, assign) BOOL supportsCancel;
@property(nonatomic, strong) UIGestureRecognizer *stopLoadingTap;

@property(nonatomic, assign) CGFloat progress;

@property(nonatomic, strong) CircleProgressView *progressView;
@property(nonatomic, strong) CircleIconView *circleIconView;
@end

@implementation CircleProgressIndicatorView

+ (instancetype)defaultProgressIndicatorView {
  CircleProgressIndicatorView *view = [[CircleProgressIndicatorView alloc]
      initWithFrame:CGRectMake(.0f, .0f, 28.0f, 28.0f)];
  view.backgroundColor = [UIColor clearColor];
  return view;
}

+ (instancetype)progressIndicatorViewWithSize:(CGSize)size {
  CircleProgressIndicatorView *view = [[CircleProgressIndicatorView alloc]
      initWithFrame:CGRectMake(.0f, .0f, size.width, size.height)];
  view.backgroundColor = [UIColor clearColor];
  return view;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  _progressLineColor = [self defaultLineColor];
  _progressLineWidth = [self defaultLineWidth];

  _progressView = [[CircleProgressView alloc] initWithFrame:self.bounds];
  [_progressView setLineColor:[self defaultLineColor]];
  [_progressView setLineWidth:[self defaultLineWidth]];
  [self addSubview:_progressView];

  _circleIconView = [[CircleIconView alloc] initWithFrame:self.bounds];
  [_circleIconView setLineColor:[self defaultLineColor]];
  [_circleIconView setLineWidth:[self defaultLineWidth]];
  [self addSubview:_circleIconView];
}

#pragma mark - stop gesture recognizer

- (void)addStopGestureRecognizer {
  if (self.stopLoadingTap) {
    return;
  }

  self.stopLoadingTap = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(stopLoadingTapped)];
  [self addGestureRecognizer:self.stopLoadingTap];
}

- (void)removeStopGestureRecognizer {
  if (self.stopLoadingTap) {
    [self removeGestureRecognizer:self.stopLoadingTap];
    self.stopLoadingTap = nil;
  }
}

- (void)stopLoadingTapped {
  [self removeStopGestureRecognizer];
}

#pragma mark - Animations

- (void)prepareForLoading {
  [self removeStopGestureRecognizer];
  [self.progressView prepareForLoading];
}

#pragma mark - Setters

- (void)setProgressType:(CircleProgressType)progressType {
  _progressType = progressType;
  [self updateIconViewType];
}

- (void)setProgressStatus:(CircleProgressStatus)progressStatus {
  _progressStatus = progressStatus;

  [self.progressView finishPrepareForLoading];
  [self.progressView setLineColor:self.progressLineColor];
  [self setProgressType:_progressType];

  switch (_progressStatus) {
  case CircleProgressStatusFailed:
    [self.progressView setLineColor:[UIColor clearColor]];
    break;
  case CircleProgressStatusStarting:
    [self prepareForLoading];
    break;
  case CircleProgressStatusInProgress:
    if (self.supportsCancel) {
      [self addStopGestureRecognizer];
    }
    break;
  case CircleProgressStatusCompleted:
    break;
  default:
    break;
  }
}

- (void)updateIconViewType {
  switch (_progressType) {
  case CircleProgressTypeUndefined:
  case CircleProgressTypeIcon:
  case CircleProgressTypeTimer:
    [self.circleIconView setType:CircleIconTypeText];
    break;
  case CircleProgressTypeUpload:
    [self.circleIconView setType:CircleIconTypeArrowUp];
    break;
  case CircleProgressTypeDownload:
    [self.circleIconView setType:CircleIconTypeArrowDown];
    break;
  }

  switch (_progressStatus) {
  case CircleProgressStatusFailed:
    [self.circleIconView setType:CircleIconTypeExclamation];
    break;
  case CircleProgressStatusInProgress:
    if (self.supportsCancel) {
      [self.circleIconView setType:CircleIconTypeStop];
    }
    break;
  case CircleProgressStatusCompleted:
    [self.circleIconView setType:CircleIconTypeCheck];
    break;
  default:
    break;
  }
}

#pragma mark - Setters

- (void)setProgress:(CGFloat)progress {
  if (progress > 1.0) {
    progress = 1.0;
  }

  if (_progress != progress) {
    _progress = progress;
    [self.progressView setProgress:progress];
  }
}

- (void)setTimerTitle:(NSAttributedString *)title {
  [self setProgressType:CircleProgressTypeTimer];
  [self.circleIconView setTitle:title];
}

- (void)setTextTitle:(NSAttributedString *)title {
  [self setProgressType:CircleProgressTypeIcon];
  [self.circleIconView setTitle:title];
}

- (void)setIconType:(CircleIconType)type {
  [self.circleIconView setType:type];
}

#pragma mark - Default Settings

- (UIColor *)defaultLineColor {
  return [UIColor colorWithRed:0 green:0.47 blue:1 alpha:1.0];
}

- (UIColor *)defaultRedLineColor {
  return [UIColor colorWithRed:0.92 green:0.18 blue:0.18 alpha:1.0];
}

- (CGFloat)defaultLineWidth {
  return fmaxf(self.frame.size.width * 0.01, 1.02f);
}

- (void)setProgressLineColor:(UIColor *)color {
  _progressLineColor = color;
  [self.progressView setLineColor:color];
  [self updateViews];
}
- (void)setProgressLineWidth:(CGFloat)width {
  _progressLineWidth = width;
  [self.progressView setLineWidth:width];
  [self updateViews];
}

- (void)updateViews {
  [self setProgressStatus:self.progressStatus];
  [self setProgressType:self.progressType];
}

@end
