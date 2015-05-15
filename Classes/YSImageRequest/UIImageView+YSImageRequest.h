//
//  UIImageView+YSImageRequest.h
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2015/01/05.
//  Copyright (c) 2015年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/SDWebImageManager.h>
#import <YSImageFilter/UIImage+YSImageFilter.h>
#import "YSImageRequest.h"

typedef void(^YSImageRequestImageViewCompletion)(UIImage *image, NSError *error);

@interface UIImageView (YSImageRequest)

- (void)ys_setImageWithURL:(NSURL *)url
                    filter:(YSImageFilter*)filter;

- (void)ys_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholder
                    filter:(YSImageFilter*)filter;

- (void)ys_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholder
                   options:(SDWebImageOptions)options
                    filter:(YSImageFilter*)filter;

- (void)ys_setImageWithURL:(NSURL *)url
                    filter:(YSImageFilter*)filter
                completion:(YSImageRequestImageViewCompletion)completion;

- (void)ys_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholder
                    filter:(YSImageFilter*)filter
                completion:(YSImageRequestImageViewCompletion)completion;

- (void)ys_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholder
                    filter:(YSImageFilter*)filter
                  progress:(YSImageRequestProgress)progressBlock
                completion:(YSImageRequestImageViewCompletion)completion;

- (void)ys_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholder
                   options:(SDWebImageOptions)options
                    filter:(YSImageFilter*)filter completion:(YSImageRequestImageViewCompletion)completion;

- (void)ys_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholder
                   options:(SDWebImageOptions)options
                    filter:(YSImageFilter*)filter
                  progress:(YSImageRequestProgress)progressBlock
                completion:(YSImageRequestImageViewCompletion)completion;

@end
