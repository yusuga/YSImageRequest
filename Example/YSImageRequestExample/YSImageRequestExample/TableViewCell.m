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

static CGFloat const kImageSize = 50.f;

@interface TableViewCell ()

@property (nonatomic) YSImageRequest *imageRequest;

@end

@implementation TableViewCell

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

- (void)setImageWithURL:(NSURL*)url quality:(CGInterpolationQuality)quality
{
    [self cancelImageRequest];
    
    self.imageView.image = [[self class] placeholderImage];

    YSImageRequest *req = [[YSImageRequest alloc] init];
    __weak typeof(self) wself = self;
#if 0
    [req requestWithURL:url completion:^(UIImage *image, NSError *error) {
        if (error) {
            return ;
        }
        wself.imageView.image = image;
    }];
#else
    [req requestWithURL:url
                   size:CGSizeMake(kImageSize, kImageSize)
                quality:quality
              trimToFit:NO
//                   mask:YSImageFilterMaskCircle
                   mask:YSImageFilterMaskRoundedCorners
            borderWidth:1.f
            borderColor:[UIColor blackColor]
             completion:^(UIImage *image, NSError *error) {
                 if (error) {
                     return ;
                 }
                 wself.imageView.image = image;
             }];
#endif
    self.imageRequest = req;
}

@end
