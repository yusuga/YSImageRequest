//
//  YSImageRequest.h
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YSImageFilter/YSImageFilter.h>
#import "FICImage.h"
@class YSImageRequest;

typedef void(^YSImageRequestWillRequestImage)(YSImageRequest *request);
typedef void(^YSImageRequestCompletion)(YSImageRequest *request, UIImage *image, NSError *error);

extern NSString * const TMDiskCachePrefix;

extern NSString * const YSImageRequestErrorDomain;
typedef NS_ENUM(NSUInteger, YSImageRequestErrorCode) {
    YSImageRequestErrorCodeCancel,
};

@interface YSImageRequest : NSObject

@property (nonatomic) NSString *diskCacheName;        // Defualt: nil

- (void)requestOriginalImageWithURL:(NSURL *)url
                         completion:(YSImageRequestCompletion)completion;

- (void)requestFilteredImageWithURL:(NSURL *)url
                               size:(CGSize)size
                   willRequestImage:(YSImageRequestWillRequestImage)willRequestImage
                         completion:(YSImageRequestCompletion)completion;

@property (nonatomic, readonly) NSURL *url;

@property (nonatomic) CGInterpolationQuality quality; // Defualt: kCGInterpolationHigh
@property (nonatomic) BOOL trimToFit;                 // Defualt: NO
@property (nonatomic) YSImageFilterMask mask;         // Defualt: YSImageFilterMaskNone
@property (nonatomic) CGFloat borderWidth;            // Defualt: 0.f;
@property (nonatomic) UIColor *borderColor;           // Defualt: nil
@property (nonatomic) CGFloat maskCornerRadius;       // Defualt: 0.f

- (void)cancel;
@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;
@property (nonatomic, readonly, getter = isRequested) BOOL requested;
@property (nonatomic, readonly, getter = isCompleted) BOOL completed;

+ (void)removeCachedOriginalImagesWithDiskCacheName:(NSString*)name completion:(void(^)(void))completion;
+ (void)removeAllCachedOriginalImagesWithCompletion:(void(^)(void))completion;
+ (void)removeAllCachedFilteringImageWithCompletion:(void(^)(void))completion;

#pragma mark - FICImage request(β)
// FICImage: size, quality, trimToFit, mask, borderWidth, boorderColor, maskCornerRadius does not yet work.
+ (void)setupFICImageFormats;
- (void)requestWithFICImage:(FICImage *)imageEntitiy
                       size:(CGSize)size
           willRequestImage:(void (^)(void))willRequestImage
                 completion:(YSImageRequestCompletion)completion;

@end
