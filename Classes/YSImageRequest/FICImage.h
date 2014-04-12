//
//  FICImage.h
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/04/11.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "FICEntity.h"

@interface FICImage : NSObject <FICEntity>

- (instancetype)initWithSourceImageURL:(NSURL*)sourceImageURL;
@property (nonatomic, readonly) NSURL *sourceImageURL;

@end
