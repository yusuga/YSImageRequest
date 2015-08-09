//
//  UIImageView+YSImageRequest.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2015/01/05.
//  Copyright (c) 2015年 Yu Sugawara. All rights reserved.
//

#import "UIImageView+YSImageRequest.h"
#import "UIView+WebCacheOperation.h"
#import "YSImageRequest.h"

static NSString * const kYSImageRequestOperationKey = @"YSImageRequest";

@implementation UIImageView (YSImageRequest)

- (void)ys_setImageWithURL:(NSURL *)url
{
    [self ys_setImageWithURL:url filter:nil];
}

- (void)ys_setImageWithURL:(NSURL *)url filter:(YSImageFilter*)filter
{
    [self ys_setImageWithURL:url filter:filter completion:nil];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder filter:(YSImageFilter*)filter
{
    [self ys_setImageWithURL:url placeholderImage:placeholder filter:filter completion:nil];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options filter:(YSImageFilter*)filter
{
    [self ys_setImageWithURL:url placeholderImage:placeholder options:options filter:filter progress:nil completion:nil];
}

- (void)ys_setImageWithURL:(NSURL *)url filter:(YSImageFilter*)filter completion:(YSImageRequestImageViewCompletion)completion
{
    [self ys_setImageWithURL:url placeholderImage:nil options:0 filter:filter progress:nil completion:completion];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder filter:(YSImageFilter*)filter completion:(YSImageRequestImageViewCompletion)completion
{
    [self ys_setImageWithURL:url placeholderImage:placeholder options:0 filter:filter progress:nil completion:completion];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder filter:(YSImageFilter*)filter progress:(YSImageRequestProgress)progressBlock completion:(YSImageRequestImageViewCompletion)completion
{
    [self ys_setImageWithURL:url placeholderImage:placeholder options:0 filter:filter progress:progressBlock completion:completion];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options filter:(YSImageFilter*)filter completion:(YSImageRequestImageViewCompletion)completion
{
    [self ys_setImageWithURL:url placeholderImage:placeholder options:options filter:filter progress:nil completion:completion];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options filter:(YSImageFilter*)filter progress:(YSImageRequestProgress)progressBlock completion:(YSImageRequestImageViewCompletion)completion
{
    NSParameterAssert([NSThread isMainThread]);
    
    if (!(options & SDWebImageDelayPlaceholder)) {
        self.image = placeholder;
    }
    
    __weak UIImageView *wself = self;
    id <SDWebImageOperation> operation;
    operation = [YSImageRequest requestImageWithURL:url
                                            options:options
                                             filter:filter
                                           progress:progressBlock
                                         completion:^(YSImageRequest *request, UIImage *image, SDImageCacheType cacheType, NSError *error)
                 {
                     NSParameterAssert([NSThread isMainThread]);
                     if (!wself || request.isCancelled) return;
                     
                     if (image) {
                         if (completion && (options & SDWebImageAvoidAutoSetImage)) {
                             completion(image, cacheType, error);
                             return;
                         } else {
                             wself.image = image;
                             [wself setNeedsLayout];
                         }
                     } else {
                         if ((options & SDWebImageDelayPlaceholder)) {
                             wself.image = placeholder;
                             [wself setNeedsLayout];
                         }
                     }
                     if (completion) {
                         completion(image, cacheType, error);
                     }
                 }];
    [self sd_setImageLoadOperation:operation forKey:kYSImageRequestOperationKey];
}

- (void)ys_cancelCurrentImageLoad
{
    [self sd_cancelImageLoadOperationWithKey:kYSImageRequestOperationKey];
}

@end
