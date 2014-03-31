//
//  YSImageRequest.h
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^YSImageRequestCompletion)(UIImage *image, NSError *error);

@interface YSImageRequest : NSObject

- (void)requestWithURL:(NSURL *)url completion:(YSImageRequestCompletion)completion;
- (void)cancel;

+ (void)removeAllCache;

@end
