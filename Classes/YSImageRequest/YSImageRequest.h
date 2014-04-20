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

typedef void(^YSImageRequestCompletion)(UIImage *image, NSError *error);

@interface YSImageRequest : NSObject

- (void)requestWithURL:(NSURL *)url
            completion:(YSImageRequestCompletion)completion;

- (void)requestWithURL:(NSURL *)url
                  size:(CGSize)size
               quality:(CGInterpolationQuality)quality
             trimToFit:(BOOL)trimToFit
                  mask:(YSImageFilterMask)mask
           borderWidth:(CGFloat)borderWidth
           borderColor:(UIColor*)borderColor
      willRequestImage:(void(^)(void))willRequestImage
            completion:(YSImageRequestCompletion)completion;

+ (void)setupFICImageFormats;
- (void)requestWithFICImage:(FICImage *)imageEntitiy
                       size:(CGSize)size
                    quality:(CGInterpolationQuality)quality
                  trimToFit:(BOOL)trimToFit
                       mask:(YSImageFilterMask)mask
                borderWidth:(CGFloat)borderWidth
                borderColor:(UIColor*)borderColor
           willRequestImage:(void (^)(void))willRequestImage
                 completion:(YSImageRequestCompletion)completion;

- (void)cancel;

+ (void)removeAllRequestCacheWithCompletion:(void(^)(void))completion;
+ (void)removeAllFilterCacheWithCompletion:(void(^)(void))completion;

@end
