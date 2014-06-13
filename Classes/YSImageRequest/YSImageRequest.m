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
#import <FastImageCache/FICImageCache.h>
#import <YSFileManager/YSFileManager.h>

#if DEBUG
    #if 0
        #define LOG_YSIMAGE_REQUEST(...) NSLog(__VA_ARGS__)
    #endif
#endif

#ifndef LOG_YSIMAGE_REQUEST
    #define LOG_YSIMAGE_REQUEST(...)
#endif

NSString * const YSImageRequestErrorDomain = @"YSImageRequestErrorDomain";

static NSString * const kDefultDiskCacheName = @"Default";

static NSString * const YSImageFormatNameUserThumbnailSmall = @"jp.YuSugawara.YSImageRequest.YSImageFormatNameUserThumbnailSmall";
static NSString * const YSImageFormatFamilyUserThumbnails = @"jp.YuSugawara.YSImageRequest.YSImageFormatFamilyUserThumbnails";
typedef void(^YSImageRequestFastImageCacheCompletion)(UIImage *image, NSError *error);

static inline NSString *cacheKeyFromURL(NSURL *url)
{
    return url.absoluteString.MD5Digest;
}

static inline NSString *memoryCacheKeyFromURL(NSURL *url, BOOL trimToFit, CGSize size, YSImageFilterMask mask, CGFloat maskCornerRadius)
{
    if (mask == YSImageFilterMaskRoundedCorners) {
        return [NSString stringWithFormat:@"%@%@%.0f%.0f%.0f", cacheKeyFromURL(url), @(trimToFit), size.width, size.height, maskCornerRadius];
    } else {
        return [NSString stringWithFormat:@"%@%@%.0f%.0f", cacheKeyFromURL(url), @(trimToFit), size.width, size.height];
    }
}

@interface YSImageRequest ()

@property (nonatomic) AFHTTPRequestOperation *imageRequestOperation;
@property (nonatomic) FICImage *imageEntity;

@end

@implementation YSImageRequest
@synthesize cancelled = _cancelled;
@synthesize requested = _requested;
@synthesize completed = _completed;

+ (NSMutableDictionary*)diskCaches
{
    static NSMutableDictionary *__caches;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __caches = [NSMutableDictionary dictionary];
    });
    return __caches;
}

+ (TMDiskCache*)originalImageDiskCacheWithName:(NSString*)name
{
    NSString *cacheName = name == nil ? kDefultDiskCacheName : name;
    
    TMDiskCache *cache = [self diskCaches][cacheName];
    if (cache == nil) {
        cache = [[TMDiskCache alloc] initWithName:cacheName];
        [[self diskCaches] setObject:cache forKey:cacheName];
    }
    return cache;
}

+ (NSCache*)filteredImageMemoryCache
{
    static NSCache *s_cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_cache = [[NSCache alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarningNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:[UIApplication sharedApplication]];
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

+ (void)setupFICImageFormats
{
    FICImageFormat *smallUserThumbnailImageFormat = [[FICImageFormat alloc] init];
    smallUserThumbnailImageFormat.name = YSImageFormatNameUserThumbnailSmall;
    smallUserThumbnailImageFormat.family = YSImageFormatFamilyUserThumbnails;
    smallUserThumbnailImageFormat.style = FICImageFormatStyle16BitBGR;
    smallUserThumbnailImageFormat.imageSize = CGSizeMake(50, 50);
    smallUserThumbnailImageFormat.maximumCount = 250;
    smallUserThumbnailImageFormat.devices = FICImageFormatDevicePhone;
    smallUserThumbnailImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    NSArray *imageFormats = @[smallUserThumbnailImageFormat];
    
    FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
    //    sharedImageCache.delegate = self;
    sharedImageCache.formats = imageFormats;
}

- (void)dealloc
{
    LOG_YSIMAGE_REQUEST(@"%s, %p", __func__, self);
}

+ (void)didReceiveMemoryWarningNotification:(NSNotification*)notification
{
    LOG_YSIMAGE_REQUEST(@"%s, %p", __func__, self);
    [[self filteredImageMemoryCache] removeAllObjects];
}

- (id)init
{
    if (self = [super init]) {
        self.quality = kCGInterpolationHigh;
        self.mask = YSImageFilterMaskNone;
    }
    return self;
}

#pragma mark - request

- (void)requestOriginalImageWithURL:(NSURL *)url completion:(YSImageRequestCompletion)completion
{
    [self setCompleted:NO];
    [self setRequested:NO];
    [self.imageRequestOperation cancel];
    self.imageRequestOperation = nil;
    
    _url = url;
    
    __strong typeof(self) strongSelf = self;
    NSString *cacheKey = cacheKeyFromURL(url);
    TMDiskCache *cache = [[self class] originalImageDiskCacheWithName:self.diskCacheName];
    [cache objectForKey:cacheKey block:^(TMDiskCache *cache, NSString *key, UIImage<NSCoding> *cachedImage, NSURL *fileURL) {
        if (strongSelf.isCancelled) {
            LOG_YSIMAGE_REQUEST(@"cancel: before request %p", strongSelf);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
            });
            return ;
        }
        if (cachedImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                LOG_YSIMAGE_REQUEST(@"[Success] Cached image, key: %@", cacheKey);
                [strongSelf setCompleted:YES];
                if (completion) completion(strongSelf, cachedImage, nil);
            });
            return;
        }
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        
        [strongSelf setRequested:YES];
        AFHTTPRequestOperation *ope = [[AFHTTPRequestOperationManager manager] HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, UIImage *responseImage)
                                       {
                                           if (strongSelf.isCancelled) {
                                               LOG_YSIMAGE_REQUEST(@"cancel: success request %p", strongSelf);
                                               if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
                                               return ;
                                           }
                                           LOG_YSIMAGE_REQUEST(@"[Success] request url: %@", req.URL.absoluteString);
                                           [strongSelf setCompleted:YES];
                                           if (completion) completion(strongSelf, responseImage, nil);
                                           [cache setObject:responseImage forKey:cacheKey block:nil];
                                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                           LOG_YSIMAGE_REQUEST(@"[Failure] operation: %@, error: %@", operation, error);
                                           if (strongSelf.isCancelled) {
                                               LOG_YSIMAGE_REQUEST(@"cancel: failure request %p", strongSelf);
                                               if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
                                               return ;
                                           }
                                           if (completion) completion(strongSelf, nil, error);
                                       }];
        ope.responseSerializer = [AFImageResponseSerializer serializer];
        
        [[[strongSelf class] imageRequestOperationQueue] addOperation:ope];
        strongSelf.imageRequestOperation = ope;
    }];
}

- (void)requestFilteredImageWithURL:(NSURL *)url
                  size:(CGSize)size
      willRequestImage:(YSImageRequestWillRequestImage)willRequestImage
            completion:(YSImageRequestCompletion)completion
{
    [self cancel];
    [self setCancelled:NO];
    
    _url = url;
    
    NSString *cacheKey = memoryCacheKeyFromURL(url, self.trimToFit, size, self.mask, self.maskCornerRadius);
    NSCache *cache = [[self class] filteredImageMemoryCache];
    UIImage *cachedImage = [cache objectForKey:cacheKey];
    if (cachedImage) {
        LOG_YSIMAGE_REQUEST(@"[Success] Cached filtered image, key: %@", cacheKey);
        [self setCompleted:YES];
        if (completion) completion(self, cachedImage, nil);
        return;
    }
    
    if (willRequestImage) willRequestImage(self);
    
    __strong typeof(self) strongSelf = self;
    [self requestOriginalImageWithURL:url completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        if (error) {
            if (completion) completion(request, nil, error);
            return ;
        }
        dispatch_async([YSImageRequest filterDispatchQueue], ^{
            [YSImageFilter resizeWithImage:image size:size quality:strongSelf.quality trimToFit:strongSelf.trimToFit mask:strongSelf.mask borderWidth:strongSelf.borderWidth borderColor:strongSelf.borderColor maskCornerRadius:strongSelf.maskCornerRadius completion:^(UIImage *filterdImage)
             {
                 if (strongSelf.isCancelled) {
                     LOG_YSIMAGE_REQUEST(@"cancel: filtered %p", strongSelf);
                     [strongSelf setCompleted:NO];
                     if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
                     return ;
                 }
                 LOG_YSIMAGE_REQUEST(@"size %@", NSStringFromCGSize(filterdImage.size));
                 [strongSelf setCompleted:YES];
                 if (completion) completion(strongSelf, filterdImage, nil);
                 if (filterdImage && cacheKey) [cache setObject:filterdImage forKey:cacheKey];
             }];
        });
    }];
}

#pragma mark - FastImageCache

- (void)requestWithFICImage:(FICImage *)imageEntitiy
                 completion:(YSImageRequestCompletion)completion
{
    [self setCompleted:NO];
    [self setRequested:NO];
    [self.imageRequestOperation cancel];
    self.imageRequestOperation = nil;
    
    NSURL *url = imageEntitiy.sourceImageURL;
    
    __strong typeof(self) strongSelf = self;
    NSString *cacheKey = cacheKeyFromURL(url);
    TMDiskCache *cache = [[self class] originalImageDiskCacheWithName:self.diskCacheName];
    [cache objectForKey:cacheKey block:^(TMDiskCache *cache, NSString *key, UIImage<NSCoding> *cachedImage, NSURL *fileURL) {
        if (strongSelf.isCancelled) {
            LOG_YSIMAGE_REQUEST(@"cancel: before request %p", strongSelf);
            if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
            return ;
        }
        void(^DidReciveImage)(UIImage *recivedImage) = ^(UIImage *recivedImage){
            [[FICImageCache sharedImageCache] setImage:recivedImage forEntity:imageEntitiy withFormatName:YSImageFormatNameUserThumbnailSmall completionBlock:^(id <FICEntity> entity, NSString *formatName, UIImage *image)
             {
                 NSLog(@"Processed and stored image for entity: %@", entity);
                 [strongSelf setCompleted:YES];
                 if (completion) completion(strongSelf, image, nil);
             }];
        };
        
        if (cachedImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DidReciveImage(cachedImage);
            });
            return;
        }
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        
        [strongSelf setRequested:YES];
        AFHTTPRequestOperation *ope = [[AFHTTPRequestOperationManager manager] HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, UIImage *responseImage)
                                       {
                                           if (strongSelf.isCancelled) {
                                               LOG_YSIMAGE_REQUEST(@"cancel: success request %p", strongSelf);
                                               if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
                                               return ;
                                           }
                                           LOG_YSIMAGE_REQUEST(@"[Success] request url: %@", req.URL.absoluteString);
                                           
                                           DidReciveImage(responseImage);
                                           [cache setObject:responseImage forKey:cacheKey block:nil];
                                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                           LOG_YSIMAGE_REQUEST(@"[Failure] operation: %@, error: %@", operation, error);
                                           if (strongSelf.isCancelled) {
                                               LOG_YSIMAGE_REQUEST(@"cancel: failure request %p", strongSelf);
                                               if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
                                               return ;
                                           }
                                           if (completion) completion(strongSelf, nil, error);
                                       }];
        ope.responseSerializer = [AFImageResponseSerializer serializer];
        
        [[[strongSelf class] imageRequestOperationQueue] addOperation:ope];
        strongSelf.imageRequestOperation = ope;
    }];
}

- (void)requestWithFICImage:(FICImage *)imageEntitiy
                       size:(CGSize)size
           willRequestImage:(void (^)(void))willRequestImage
                 completion:(YSImageRequestCompletion)completion
{
    [self cancel];
    [self setCancelled:NO];
    self.imageEntity = imageEntitiy;
    
    NSLog(@"[FICImage] size, quality, trimToFit, mask, borderWidth, boorderColor, maskCornerRadius does not yet work");
    
    __strong typeof(self) strongSelf = self;
    if (![[FICImageCache sharedImageCache] retrieveImageForEntity:imageEntitiy withFormatName:YSImageFormatNameUserThumbnailSmall completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image)
         {
             if (strongSelf.isCancelled) {
                 LOG_YSIMAGE_REQUEST(@"cancel: filtered %p", strongSelf);
                 if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
                 return ;
             }
             if (completion) completion(strongSelf, image, nil);
         }]) {
             if (willRequestImage) willRequestImage();
             
             [strongSelf requestWithFICImage:imageEntitiy completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
                 if (request.isCancelled) {
                     LOG_YSIMAGE_REQUEST(@"cancel: filtered %p", request);
                     if (completion) completion(strongSelf, nil, [[strongSelf class] cancelError]);
                     return ;
                 }
                 if (error) {
                     if (completion) completion(request, nil, error);
                     return ;
                 }
                 [request requestWithFICImage:imageEntitiy size:size willRequestImage:willRequestImage completion:completion];
             }];
         }
}

#pragma mark - remove

+ (void)removeCachedOriginalImagesWithDiskCacheName:(NSString*)name completion:(void(^)(void))completion
{
    LOG_YSIMAGE_REQUEST(@"%s", __func__);
    [[self originalImageDiskCacheWithName:name] removeAllObjects:^(TMDiskCache *cache) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    }];
}

+ (void)removeAllCachedOriginalImagesWithCompletion:(void(^)(void))completion
{
    NSArray *fileNames = [YSFileManager fileNamesAtDirectoryPath:[YSFileManager cachesDirectory]];
    NSMutableArray *cacheNames = [NSMutableArray array];
    for (NSString *fileName in fileNames) {
        if ([fileName hasPrefix:TMDiskCachePrefix]) {
            [cacheNames addObject:[fileName pathExtension]];
        }
    }
    if ([cacheNames count] == 0) {
        if (completion) completion();
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *name in cacheNames) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [self removeCachedOriginalImagesWithDiskCacheName:name completion:^{
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
#if !OS_OBJECT_USE_OBJC
            dispatch_release(semaphore);
#endif
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    });
}

+ (void)removeAllCachedFilteringImageWithCompletion:(void(^)(void))completion
{
    LOG_YSIMAGE_REQUEST(@"%s", __func__);
    [[self filteredImageMemoryCache] removeAllObjects];
    if (completion) completion();
}

#pragma mark - state
     
- (void)cancel
{
    LOG_YSIMAGE_REQUEST(@"[Cancel] image request url: %@", self.imageRequestOperation.request.URL.absoluteString);
    [self setCancelled:YES];
    [self.imageRequestOperation cancel];
    self.imageRequestOperation = nil;
    _url = nil;
    
    [[FICImageCache sharedImageCache] cancelImageRetrievalForEntity:self.imageEntity
                                                     withFormatName:YSImageFormatNameUserThumbnailSmall];
    self.imageEntity = nil;
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

- (void)setRequested:(BOOL)requested
{
    @synchronized(self) {
        _requested = requested;
    }
}

- (BOOL)isRequested
{
    @synchronized(self) {
        return _requested;
    }
}

- (void)setCompleted:(BOOL)completed
{
    @synchronized(self) {
        _completed = completed;
    }
}

- (BOOL)isCompleted
{
    @synchronized(self) {
        return _completed;
    }
}

#pragma mark - error

+ (NSError*)cancelError
{
    return [NSError errorWithDomain:YSImageRequestErrorDomain code:YSImageRequestErrorCodeCancel userInfo:nil];
}

@end
