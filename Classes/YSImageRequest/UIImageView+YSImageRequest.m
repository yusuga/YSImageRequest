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

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder filter:(YSImageFilter*)filter progress:(SDWebImageDownloaderProgressBlock)progressBlock completion:(YSImageRequestImageViewCompletion)completion
{
    [self ys_setImageWithURL:url placeholderImage:placeholder options:0 filter:filter progress:progressBlock completion:completion];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options filter:(YSImageFilter*)filter completion:(YSImageRequestImageViewCompletion)completion
{
    [self ys_setImageWithURL:url placeholderImage:placeholder options:options filter:filter progress:nil completion:completion];
}

- (void)ys_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options filter:(YSImageFilter*)filter progress:(SDWebImageDownloaderProgressBlock)progressBlock completion:(YSImageRequestImageViewCompletion)completion
{
    [self ys_cancelCurrentImageLoad];
    
    if (!(options & SDWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            self.image = placeholder;
        });
    }
    
    if (url) {
        __weak UIImageView *wself = self;
        id <SDWebImageOperation> operation = [YSImageRequest requestImageWithURL:url options:options filter:filter progress:progressBlock completion:^(YSImageRequest *request, UIImage *image, NSError *error) {            
            if (!wself) return;            
            dispatch_main_sync_safe(^{
                if (!wself) return;
                if (image) {
                    wself.image = image;
                    [wself setNeedsLayout];
                } else {
                    if ((options & SDWebImageDelayPlaceholder)) {
                        wself.image = placeholder;
                        [wself setNeedsLayout];
                    }
                }
                if (completion) {
                    completion(image, error);
                }
            });
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
