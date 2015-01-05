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

NSString * const YSImageRequestErrorDomain = @"YSImageRequestErrorDomain";
NSString * const kYSImageRequestDefultDiskCacheName = @"Cache";

static NSString * const YSImageFormatNameUserThumbnailSmall = @"jp.YuSugawara.YSImageRequest.YSImageFormatNameUserThumbnailSmall";
static NSString * const YSImageFormatFamilyUserThumbnails = @"jp.YuSugawara.YSImageRequest.YSImageFormatFamilyUserThumbnails";
typedef void(^YSImageRequestFastImageCacheCompletion)(UIImage *image, NSError *error);

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

@property (nonatomic) id <SDWebImageOperation> operation;

@end

@implementation YSImageRequest
@synthesize cancelled = _cancelled;

- (void)dealloc
{
    LOG_YSIMAGE_REQUEST(@"%s, %p", __func__, self);
}

#pragma mark - Request

+ (YSImageRequest<SDWebImageOperation> *)requestImageWithURL:(NSURL *)url
                                                     options:(SDWebImageOptions)options
                                                      filter:(YSImageFilter*)filter
                                                    progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                                  completion:(YSImageRequestCompletion)completion
{
    YSImageRequest *req = [[YSImageRequest alloc] init];
    [req requestImageWithURL:url options:options filter:filter progress:progressBlock completion:completion];
    return req;
}

- (void)requestImageWithURL:(NSURL*)url
                    options:(SDWebImageOptions)options
                     filter:(YSImageFilter*)filter
                   progress:(SDWebImageDownloaderProgressBlock)progressBlock
                 completion:(YSImageRequestCompletion)completion
{
    NSString *memoryCacheKey = memoryCacheKeyFromURL(url, filter);
    
    SDImageCache *filterdImageCache = [[self class] filterdImageCache];
    
    if (!(options & SDWebImageRefreshCached)) {
        UIImage *filterdImage = [filterdImageCache imageFromMemoryCacheForKey:memoryCacheKey];
        if (filterdImage) {
            if (completion) completion(self, filterdImage, nil);
            return;
        }
    }
    
    SDWebImageManager *imageManager = [SDWebImageManager sharedManager];
    
    __weak typeof(self) wself = self;
    self.operation = [imageManager downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        if (!wself) return ;
        
        if (image) {
            [image ys_filter:filter withCompletion:^(UIImage *filterdImage) {
                if (!wself) return ;
                
                [filterdImageCache storeImage:filterdImage forKey:memoryCacheKey toDisk:NO];
                [imageManager.imageCache removeImageForKey:[imageManager cacheKeyForURL:url] fromDisk:NO];
                if (completion) completion(wself, filterdImage, nil);
            }];
        } else {
            if (completion) completion(wself, image, error);
        }
    }];
}

#pragma mark - Cache

+ (SDImageCache*)filterdImageCache
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
    [self.operation cancel];
    self.operation = nil;
    [self setCancelled:YES];
}

- (void)setCancelled:(BOOL)cancelled
{
    @synchronized(self) {
        _cancelled = cancelled;
    }
}

- (BOOL)isCancelled
{
    @synchronized(self) {
        return _cancelled;
    }
}

@end
