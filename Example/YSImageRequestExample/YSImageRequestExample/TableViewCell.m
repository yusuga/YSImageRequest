//
//  TableViewCell.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/24.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TableViewCell.h"
#import "UIImageView+YSImageRequest.h"

#import <YSUIKitAdditions/UIImage+YSUIKitAdditions.h>

static CGFloat const kImageSize = 50.f;

@interface TableViewCell ()

@end

@implementation TableViewCell

- (void)awakeFromNib
{
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
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
    filter.maskCornerRadius = 0.f;
    
    __block UIActivityIndicatorView *activityIndicator;
    __weak UIImageView *weakImageView = self.imageView;
    
    [self.imageView ys_setImageWithURL:url
                      placeholderImage:[[self class] placeholderImage]
                                filter:filter
                              progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                  if (!activityIndicator) {
                                      [weakImageView addSubview:activityIndicator = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
                                      activityIndicator.center = CGPointMake(kImageSize/2.f, kImageSize/2.f);
                                      [activityIndicator startAnimating];
                                  }
                              } completion:^(UIImage *image, NSError *error) {
                                  if (error) {
                                      NSLog(@"error = %@;", error);
                                  }
                                  [activityIndicator removeFromSuperview];
                                  activityIndicator = nil;
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
