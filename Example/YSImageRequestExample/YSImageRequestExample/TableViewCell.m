//
//  TableViewCell.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/24.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TableViewCell.h"
#import "UIImageView+YSImageRequest.h"
#import "YSImageRequest.h"

#import <YSUIKitAdditions/UIImage+YSUIKitAdditions.h>
#import <M13ProgressSuite/M13ProgressViewPie.h>

static CGFloat const kImageSize = 50.f;

@interface TableViewCell ()

@property (nonatomic) M13ProgressViewPie *progressView;

@end

@implementation TableViewCell

- (void)awakeFromNib
{
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.progressView = [[M13ProgressViewPie alloc] initWithFrame:CGRectMake(0.f, 0.f, 30.f, 30.f)];
    self.progressView.alpha = 0.f;
    [self.imageView addSubview:self.progressView];    
}

- (void)prepareForReuse
{
    [self.progressView setProgress:0.f animated:NO];
    self.progressView.alpha = 0.f;
}

- (void)setImageWithURL:(NSURL*)url
                quality:(CGInterpolationQuality)quality
{
    YSImageFilter *filter = [[YSImageFilter alloc] init];
    filter.size = CGSizeMake(kImageSize, kImageSize);
    filter.quality = quality;
    filter.trimToFit = NO;
    filter.mask = YSImageFilterMaskRoundedCorners;
    filter.borderWidth = 5.f;
    filter.borderColor = [UIColor redColor];
    filter.maskCornerRadius = 10.f;
    
    NSLog(@"filterdImage cache = %@;", [YSImageRequest cachedFilteredImageForURL:url filter:filter] ? @"OK" : @"None");
    
    __weak typeof(self) wself = self;
    [self.imageView ys_setImageWithURL:url
                      placeholderImage:[[self class] placeholderImage]
                                filter:filter
                              progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
                                  if (wself.progressView.alpha == 0.f) {
                                      wself.progressView.center = CGPointMake(kImageSize/2.f, kImageSize/2.f);
                                      
                                      [UIView animateWithDuration:0.1 animations:^{
                                          wself.progressView.alpha = 1.f;
                                      }];
                                  }
                                  NSLog(@"progress: %f", progress);
                                  [wself.progressView setProgress:progress animated:YES];
                              } completion:^(UIImage *image, NSError *error) {
                                  if (error) {
                                      NSLog(@"error = %@;", error);
                                  }
                                  [UIView animateWithDuration:0.1 animations:^{
                                      wself.progressView.alpha = 0.f;
                                  }];
                              }];
}

+ (UIImage*)placeholderImage
{
    static UIImage *__image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __image = [UIImage ys_imageFromColor:[UIColor lightGrayColor] withSize:CGSizeMake(kImageSize, kImageSize)];
    });
    return __image;
}

@end
