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

- (void)ys_setImageWithURL:(NSURL *)url filter:(YSImageFilter*)filter
{
    [self ys_setImageWithURL:url placeholderImage:nil options:0 filter:filter progress:nil completion:nil];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder filter:(YSImageFilter*)filter
{
    [self ys_setImageWithURL:url placeholderImage:placeholder options:0 filter:filter progress:nil completion:nil];
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
    
    [self ys_cancelCurrentImageLoad];
    
    if (!(options & SDWebImageDelayPlaceholder)) {
        self.image = placeholder;
    }
    
    if (url) {
        __weak UIImageView *wself = self;
        id <SDWebImageOperation> operation = [YSImageRequest requestImageWithURL:url options:options filter:filter progress:progressBlock completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
            NSParameterAssert([NSThread isMainThread]);
            if (!wself || request.isCancelled) return;
            
            if (image) {
                wself.image = image;
            } else {
                if ((options & SDWebImageDelayPlaceholder)) {
                    wself.image = placeholder;
                }
            }
            if (completion) {
                completion(image, error);
            }
        }];
        [self sd_setImageLoadOperation:operation forKey:kYSImageRequestOperationKey];
    } else {
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:@"SDWebImageErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completion) completion(nil, error);
        });
    }
}

- (void)ys_cancelCurrentImageLoad
{
    [self sd_cancelImageLoadOperationWithKey:kYSImageRequestOperationKey];
}

@end
