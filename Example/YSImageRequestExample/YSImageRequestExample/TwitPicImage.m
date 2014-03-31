//
//  TwitPicImage.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "TwitPicImage.h"

@implementation TwitPicImage

- (id)initWithDictonary:(NSDictionary*)dict
{
    if (self = [super init]) {
        self.dictionary = dict;
    }
    return self;
}

- (NSNumber*)short_id
{
    return [self.dictionary objectForKey:@"short_id"];
}

@end
