//
//  YSImageRequest.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "YSImageRequest.h"

#import <AFNetworking/AFNetworking.h>
#import <TMCache/TMCache.h>
#import <MD5Digest/NSString+MD5.h>

#if DEBUG
    #if 0
        #define LOG_YSIMAGE_REQUEST(...) NSLog(__VA_ARGS__)
    #endif
#endif

#ifndef LOG_YSIMAGE_REQUEST
    #define LOG_YSIMAGE_REQUEST(...)
#endif

static NSString * const kRequestImageCacheName = @"YSImageRequest";
static NSString * const kFilterImageCacheName = @"YSImageRequest-Filter";

static inline NSString *cacheKeyFromURL(NSURL *url)
{
    return url.absoluteString.MD5Digest;
}

@interface YSImageRequest ()

@property (nonatomic) AFHTTPRequestOperation *imageRequestOperation;
@property (nonatomic, getter = isCancelled) BOOL cancelled;

@end

@implementation YSImageRequest

+ (TMDiskCache*)requestImageDiskCache
{
    static TMDiskCache *s_cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_cache = [[TMDiskCache alloc] initWithName:kRequestImageCacheName];
    });
    return s_cache;
}

+ (NSCache*)filterImageMemoryCache
{
    static NSCache *s_cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_cache = [[NSCache alloc] init];
    });
    return s_cache;
}

+ (NSOperationQueue*)imageRequestOperationQueue
{
    static NSOperationQueue *s_operationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_operationQueue = [[NSOperationQueue alloc] init];
        [s_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });
    return s_operationQueue;
}

+ (dispatch_queue_t)filterDispatchQueue
{
    static dispatch_queue_t s_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_queue = dispatch_queue_create("jp.YuSugawara.YSImageRequest.filter.queue", NULL);
    });
    return s_queue;
}

- (id)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarningNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];
    }
    return self;
}

- (void)dealloc
{
    LOG_YSIMAGE_REQUEST(@"%s, %p", __func__, self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarningNotification:(NSNotification*)notification
{
    LOG_YSIMAGE_REQUEST(@"%s, %p", __func__, self);
    [[[self class] filterImageMemoryCache] removeAllObjects];
}

- (void)requestWithURL:(NSURL *)url completion:(YSImageRequestCompletion)completion
{
    [self.imageRequestOperation cancel];
    self.imageRequestOperation = nil;
    
    __weak typeof(self) wself = self;
    __strong typeof(self) strongSelf = self;
    NSString *cacheKey = cacheKeyFromURL(url);
    TMDiskCache *cache = [[self class] requestImageDiskCache];
    [cache objectForKey:cacheKey block:^(TMDiskCache *cache, NSString *key, UIImage<NSCoding> *cachedImage, NSURL *fileURL) {
        if (strongSelf.isCancelled) {
            LOG_YSIMAGE_REQUEST(@"cancel: before request %p", strongSelf);
            return ;
        }
        if (cachedImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LOG_YSIMAGE_REQUEST(@"[Success] Cached image, key: %@", cacheKey);
                if (completion) completion(cachedImage, nil);
            });
            return;
        }
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        
        AFHTTPRequestOperation *ope = [[AFHTTPRequestOperationManager manager] HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, UIImage *responseImage)
                                       {
                                           if (strongSelf.isCancelled) {
                                               LOG_YSIMAGE_REQUEST(@"cancel: success request %p", strongSelf);
                                               return ;
                                           }
                                           LOG_YSIMAGE_REQUEST(@"[Success] request url: %@", req.URL.absoluteString);
                                           if (completion) completion(responseImage, nil);
                                           [cache setObject:responseImage forKey:cacheKey block:nil];
                                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                           LOG_YSIMAGE_REQUEST(@"[Failure] operation: %@, error: %@", operation, error);
                                           if (strongSelf.isCancelled) {
                                               LOG_YSIMAGE_REQUEST(@"cancel: failure request %p", strongSelf);
                                               return ;
                                           }
                                           if (completion) completion(nil, error);
                                       }];
        ope.responseSerializer = [AFImageResponseSerializer serializer];
        
        [[[wself class] imageRequestOperationQueue] addOperation:ope];
        wself.imageRequestOperation = ope;
    }];
}

- (void)requestWithURL:(NSURL *)url
                  size:(CGSize)size
               quality:(CGInterpolationQuality)quality
             trimToFit:(BOOL)trimToFit
                  mask:(YSImageFilterMask)mask
           borderWidth:(CGFloat)borderWidth
           borderColor:(UIColor*)borderColor
      willRequestImage:(void (^)(void))willRequestImage
            completion:(YSImageRequestCompletion)completion
{
    [self cancel];
    self.cancelled = NO;
    
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%.0f-%.0f", cacheKeyFromURL(url), size.width, size.height];
    NSCache *cache = [[self class] filterImageMemoryCache];
    UIImage *cachedImage = [cache objectForKey:cacheKey];
    if (cachedImage) {
        LOG_YSIMAGE_REQUEST(@"[Success] Cached filtered image, key: %@", cacheKey);
        if (completion) completion(cachedImage, nil);
        return;
    }
    
    if (willRequestImage) willRequestImage();
    
    __strong typeof(self) strongSelf = self;
    [self requestWithURL:url completion:^(UIImage *image, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return ;
        }
        dispatch_async([YSImageRequest filterDispatchQueue], ^{
            [YSImageFilter resizeWithImage:image size:size quality:quality trimToFit:trimToFit mask:mask borderWidth:borderWidth borderColor:borderColor completion:^(UIImage *filterdImage)
             {
                 if (strongSelf.isCancelled) {
                     LOG_YSIMAGE_REQUEST(@"cancel: filtered %p", strongSelf);
                     return ;
                 }
                 LOG_YSIMAGE_REQUEST(@"size %@", NSStringFromCGSize(filterdImage.size));
                 if (completion) completion(filterdImage, nil);
                 [cache setObject:filterdImage forKey:cacheKey];
             }];
        });
    }];
}

- (void)cancel
{
    LOG_YSIMAGE_REQUEST(@"[Cancel] image request url: %@", self.imageRequestOperation.request.URL.absoluteString);
    self.cancelled = YES;
    [self.imageRequestOperation cancel];
    self.imageRequestOperation = nil;
}

+ (void)removeAllRequestCacheWithCompletion:(void(^)(void))completion
{
    LOG_YSIMAGE_REQUEST(@"%s", __func__);
    [[self requestImageDiskCache] removeAllObjects:^(TMDiskCache *cache) {
        if (completion) completion();
    }];
}

+ (void)removeAllFilterCacheWithCompletion:(void(^)(void))completion
{
    LOG_YSIMAGE_REQUEST(@"%s", __func__);
    [[self filterImageMemoryCache] removeAllObjects];
    if (completion) completion();
}

@end
