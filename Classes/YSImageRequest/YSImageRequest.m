//
//  YSImageRequest.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSImageRequest.h"
#import <NSString-Hash/NSString+Hash.h>

static inline NSString *cacheKeyFromURL(NSURL *url)
{
    return url.absoluteString.md5String;
}

static inline NSString *memoryCacheKeyFromURL(NSURL *url, YSImageFilter *filter)
{
    if (filter.maxResolution > 0.) {
        return [NSString stringWithFormat:@"%@,%.0f,%d,%d,%zd,%.0f", cacheKeyFromURL(url), filter.maxResolution, filter.quality, filter.trimToFit ? 1 : 0, filter.mask, filter.maskCornerRadius];
    } else {
        return [NSString stringWithFormat:@"%@,%.0f,%.0f,%d,%d,%zd,%.0f", cacheKeyFromURL(url), filter.size.width, filter.size.height, filter.quality, filter.trimToFit ? 1 : 0, filter.mask, filter.maskCornerRadius];
    }
}

@interface YSImageRequest ()

@property (weak, nonatomic) id <SDWebImageOperation> operation;
@property (nonatomic, readwrite, getter = isCancelled) BOOL cancelled;

@end

@implementation YSImageRequest

+ (instancetype)sharedInstance
{
    static id __instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance =  [[self alloc] init];
    });
    return __instance;
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
    
    SDWebImageManager *imageManager = [SDWebImageManager sharedManager];
    NSString *cacheKey = memoryCacheKeyFromURL(url, filter);
    
    if (!(options & SDWebImageRefreshCached)) {
        UIImage *filteredImage = [imageManager.imageCache imageFromMemoryCacheForKey:cacheKey];
        if (filteredImage) {
            if (completion) completion(self, filteredImage, SDImageCacheTypeMemory, nil);
            return;
        }
    }
    
    self.operation = [imageManager downloadImageWithURL:url options:options progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressBlock) progressBlock(receivedSize, expectedSize, (CGFloat)receivedSize/expectedSize);
        });
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        NSParameterAssert([NSThread isMainThread]);
        if (self.isCancelled) return ;
        
        if (image && filter) {
            [image ys_filter:filter withCompletion:^(UIImage *filteredImage) {
                NSParameterAssert([NSThread isMainThread]);
                if (self.isCancelled) return ;
                
                [imageManager.imageCache removeImageForKey:[imageManager cacheKeyForURL:url] fromDisk:NO];
                [imageManager.imageCache storeImage:filteredImage forKey:cacheKey toDisk:NO];
                
                if (completion) completion(self, filteredImage, cacheType, nil);
            }];
        } else {
            if (completion) completion(self, image, cacheType, error);
        }
    }];
}

+ (UIImage *)cachedFilteredImageForURL:(NSURL *)url
                                filter:(YSImageFilter*)filter
{
    NSParameterAssert([NSThread isMainThread]);
    return [[self imageCache] imageFromMemoryCacheForKey:memoryCacheKeyFromURL(url, filter)];
}

+ (void)storeFilteredImage:(UIImage *)image
                   withURL:(NSURL *)url
                    filter:(YSImageFilter *)filter
{
    NSParameterAssert([NSThread isMainThread]);
    [[self imageCache] storeImage:image forKey:memoryCacheKeyFromURL(url, filter) toDisk:NO];
}

#pragma mark - Cache

+ (SDImageCache*)imageCache
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
