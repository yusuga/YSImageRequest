//
//  YSImageRequest.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSImageRequest.h"
#import <MD5Digest/NSString+MD5.h>

#if DEBUG
#if 0
#define LOG_YSIMAGE_REQUEST(...) NSLog(__VA_ARGS__)
#endif
#endif

#ifndef LOG_YSIMAGE_REQUEST
#define LOG_YSIMAGE_REQUEST(...)
#endif

static inline NSString *cacheKeyFromURL(NSURL *url)
{
    return url.absoluteString.MD5Digest;
}

static inline NSString *memoryCacheKeyFromURL(NSURL *url, YSImageFilter *filter)
{
    CGSize size = filter.size;
    if (filter.mask == YSImageFilterMaskRoundedCorners) {
        return [NSString stringWithFormat:@"%@%@%.0f%.0f%.0f", cacheKeyFromURL(url), @(filter.trimToFit), size.width, size.height, filter.maskCornerRadius];
    } else {
        return [NSString stringWithFormat:@"%@%@%.0f%.0f", cacheKeyFromURL(url), @(filter.trimToFit), size.width, size.height];
    }
}

@interface YSImageRequest ()

@property (weak, nonatomic) id <SDWebImageOperation> operation;
@property (nonatomic, readwrite, getter = isCancelled) BOOL cancelled;

@end

@implementation YSImageRequest

- (void)dealloc
{
    LOG_YSIMAGE_REQUEST(@"%s, %p", __func__, self);
}

#pragma mark - Request

+ (YSImageRequest<SDWebImageOperation> *)requestImageWithURL:(NSURL *)url
                                                     options:(SDWebImageOptions)options
                                                      filter:(YSImageFilter*)filter
                                                    progress:(YSImageRequestProgress)progressBlock
                                                  completion:(YSImageRequestCompletion)completion
{
    YSImageRequest *req = [[YSImageRequest alloc] init];
    [req requestImageWithURL:url options:options filter:filter progress:progressBlock completion:completion];
    return req;
}

- (void)requestImageWithURL:(NSURL*)url
                    options:(SDWebImageOptions)options
                     filter:(YSImageFilter*)filter
                   progress:(YSImageRequestProgress)progressBlock
                 completion:(YSImageRequestCompletion)completion
{
    NSParameterAssert([NSThread isMainThread]);
    
    NSString *memoryCacheKey = memoryCacheKeyFromURL(url, filter);
    
    SDImageCache *filteredImageCache = [[self class] filteredImageCache];
    
    if (!(options & SDWebImageRefreshCached)) {
        UIImage *filteredImage = [filteredImageCache imageFromMemoryCacheForKey:memoryCacheKey];
        if (filteredImage) {
            if (completion) completion(self, filteredImage, nil);
            return;
        }
    }
    
    SDWebImageManager *imageManager = [SDWebImageManager sharedManager];
    
    __weak typeof(self) wself = self;
    self.operation = [imageManager downloadImageWithURL:url options:options progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressBlock) progressBlock(receivedSize, expectedSize, (CGFloat)receivedSize/expectedSize);
        });
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        NSParameterAssert([NSThread isMainThread]);
        if (!wself || wself.isCancelled) return ;
        
        if (image) {
            [image ys_filter:filter withCompletion:^(UIImage *filteredImage) {
                NSParameterAssert([NSThread isMainThread]);
                if (!wself || wself.isCancelled) return ;
                
                [filteredImageCache storeImage:filteredImage forKey:memoryCacheKey toDisk:NO];
                [imageManager.imageCache removeImageForKey:[imageManager cacheKeyForURL:url] fromDisk:NO];
                if (completion) completion(wself, filteredImage, nil);
            }];
        } else {
            if (completion) completion(wself, image, error);
        }
    }];
}

+ (UIImage *)cachedFilteredImageForURL:(NSURL *)url
                                filter:(YSImageFilter*)filter
{
    NSParameterAssert([NSThread isMainThread]);
    return [[self filteredImageCache] imageFromMemoryCacheForKey:memoryCacheKeyFromURL(url, filter)];
}

#pragma mark - Cache

+ (SDImageCache*)filteredImageCache
{
    static id __cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __cache = [[SDImageCache alloc] initWithNamespace:NSStringFromClass([self class])];
    });
    return __cache;
}

+ (SDImageCache*)originalImageCache
{
    return [SDWebImageManager sharedManager].imageCache;
}

#pragma mark - State

- (void)cancel
{
    self.cancelled = YES;
    [self.operation cancel];
    self.operation = nil;
}

@end
