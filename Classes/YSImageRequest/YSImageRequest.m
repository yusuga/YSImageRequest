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
    #define DEBUG_CACHE_DISABLE 1
#endif

#if DEBUG
    #if 1
        #define LOG_YSIMAGE_REQUEST(...) NSLog(__VA_ARGS__)
    #endif
#endif

#ifndef LOG_YSIMAGE_REQUEST
    #define LOG_YSIMAGE_REQUEST(...)
#endif

static NSString * const kCacheName = @"YSImageRequest";

static inline NSString *cacheKeyFromURL(NSURL *url)
{
    return url.absoluteString.MD5Digest;
}

@interface YSImageRequest ()

@property (nonatomic) AFHTTPRequestOperation *imageRequestOperation;

@end

@implementation YSImageRequest

+ (TMCache*)sharedCache
{
    static TMCache *s_cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_cache = [[TMCache alloc] initWithName:kCacheName];
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

- (void)requestWithURL:(NSURL *)url completion:(YSImageRequestCompletion)completion
{
    NSString *cacheKey = cacheKeyFromURL(url);
    TMCache *cache = [[self class] sharedCache];
    UIImage *cachedImg = [cache objectForKey:cacheKey];
    if (cachedImg) {
        LOG_YSIMAGE_REQUEST(@"[Success] Cached image, key: %@", cacheKey);
        if (completion) completion(cachedImg, nil);
        return;
    }
    
    NSURLRequest *req = [NSURLRequest requestWithURL:url];

    AFHTTPRequestOperation *ope = [[AFHTTPRequestOperationManager manager] HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, UIImage *responseImage)
                                         {
                                             LOG_YSIMAGE_REQUEST(@"[Success] request url: %@", req.URL.absoluteString);
                                             [cache setObject:responseImage forKey:cacheKey];
                                             if (completion) completion(responseImage, nil);
                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             LOG_YSIMAGE_REQUEST(@"[Failure] operation: %@, error: %@", operation, error);
                                             if (completion) completion(nil, error);
                                         }];
    ope.responseSerializer = [AFImageResponseSerializer serializer];
    
    [[[self class] imageRequestOperationQueue] addOperation:ope];
    self.imageRequestOperation = ope;
}

- (void)cancel
{
#if DEBUG
    if (self.imageRequestOperation) {
        LOG_YSIMAGE_REQUEST(@"[Cancel] image request url: %@", self.imageRequestOperation.request.URL.absoluteString);
    }
#endif
    [self.imageRequestOperation cancel];
    self.imageRequestOperation = nil;
}

+ (void)removeAllCache
{
    LOG_YSIMAGE_REQUEST(@"%s", __func__);
    [[TMCache sharedCache] removeAllObjects];
}

@end
