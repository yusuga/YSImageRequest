//
//  TwitPicImage.h
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitPicImage : NSObject

- (id)initWithDictonary:(NSDictionary*)dict;
@property (nonatomic) NSDictionary *dictionary;

- (NSNumber*)short_id;

@property (nonatomic) NSString *tag;

@end
