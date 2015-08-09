//
//  YSImageRequest.h
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SDWebImage/SDWebImageManager.h>
#import <YSImageFilter/UIImage+YSImageFilter.h>
@class YSImageRequest;

typedef void(^YSImageRequestProgress)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress);
typedef void(^YSImageRequestCompletion)(YSImageRequest *request, UIImage *image, SDImageCacheType cacheType, NSError *error);

@interface YSImageRequest : NSObject <SDWebImageOperation>

+ (YSImageRequest <SDWebImageOperation>*)requestImageWithURL:(NSURL*)url
                                                     options:(SDWebImageOptions)options
                                                      filter:(YSImageFilter*)filter
                                                    progress:(YSImageRequestProgress)progressBlock
                                                  completion:(YSImageRequestCompletion)completion;

+ (UIImage *)cachedFilteredImageForURL:(NSURL *)url
                                filter:(YSImageFilter*)filter;

- (void)cancel;
@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;

+ (SDImageCache*)imageCache;

+ (void)storeFilteredImage:(UIImage *)image
                   withURL:(NSURL *)url
                    filter:(YSImageFilter *)filter;

@end
