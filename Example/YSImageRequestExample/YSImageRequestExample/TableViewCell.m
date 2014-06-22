//
//  TableViewCell.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/24.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TableViewCell.h"
#import "YSImageRequest.h"

#import <YSUIKitAdditions/UIImage+YSUIKitAdditions.h>

#define kUseFICImage 0

static CGFloat const kImageSize = 50.f;

@interface TableViewCell ()

@property (nonatomic) YSImageRequest *imageRequest;

@end

@implementation TableViewCell

+ (void)initialize
{
#if kUseFICImage
    [YSImageRequest setupFICImageFormats];
#endif
}

+ (UIImage*)placeholderImage
{
    static UIImage *s_image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_image = [UIImage ys_imageFromColor:[UIColor lightGrayColor] withSize:CGSizeMake(kImageSize, kImageSize)];
    });
    return s_image;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{

    // Initialization code
}

- (void)prepareForReuse
{
    [self cancelImageRequest];
}

- (NSString *)reuseIdentifier
{
    return @"Cell";
}

- (void)cancelImageRequest
{
    [self.imageRequest cancel];
    self.imageRequest = nil;
}

- (void)setImageWithURL:(NSURL*)url quality:(CGInterpolationQuality)quality diskCacheName:(NSString *)diskCacheName
{
    [self cancelImageRequest];
    
    YSImageFilter *filter = [[YSImageFilter alloc] init];
    filter.size = CGSizeMake(kImageSize, kImageSize);
    filter.quality = quality;
    filter.trimToFit = NO;
    filter.mask = YSImageFilterMaskRoundedCorners;
    filter.borderWidth = 5.f;
    filter.borderColor = [UIColor redColor];
    filter.maskCornerRadius = 0.f;

    YSImageRequest *req = [[YSImageRequest alloc] initWithDiskCacheName:diskCacheName];
    
    __weak typeof(self) wself = self;
#if kUseFICImage
    [req requestWithFICImage:[[FICImage alloc] initWithSourceImageURL:url]
                        size:CGSizeMake(kImageSize, kImageSize)
            willRequestImage:^{
                wself.imageView.image = [[wself class] placeholderImage];
            }
                  completion:^(UIImage *image, NSError *error) {
                      if (error) {
                          return ;
                      }
                      wself.imageView.image = image;
                  }];
#else
    [req requestFilteredImageWithURL:url
                              filter:filter
                    willRequestImage:^(YSImageRequest *request) {
                        wself.imageView.image = [[wself class] placeholderImage];
                    } completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
                        if (error) {
                            return ;
                        }
                        wself.imageView.image = image;
                    }];
#endif
    self.imageRequest = req;
}

@end
