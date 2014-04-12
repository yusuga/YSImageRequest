//
//  FICImage.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/04/11.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "FICImage.h"
#import <FastImageCache/FICUtilities.h>
#import <YSImageFilter/YSImageFilter.h>

@interface FICImage ()

@property (copy, nonatomic) NSString *UUID;

@end

@implementation FICImage

- (instancetype)initWithSourceImageURL:(NSURL *)sourceImageURL
{
    if (self = [super init]) {
        _sourceImageURL = [sourceImageURL copy];
    }
    return self;
}

- (NSString *)UUID
{
    if (_UUID == nil) {
        // MD5 hashing is expensive enough that we only want to do it once
        CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString([_sourceImageURL absoluteString]);
        _UUID = FICStringWithUUIDBytes(UUIDBytes);
    }
    return _UUID;
}

- (NSString *)sourceImageUUID
{
    return [self UUID];
}

- (NSURL *)sourceImageURLWithFormatName:(NSString *)formatName
{
    return _sourceImageURL;
}

- (FICEntityImageDrawingBlock)drawingBlockForImage:(UIImage *)image withFormatName:(NSString *)formatName
{
    return ^(CGContextRef context, CGSize contextSize) {
        CGRect contextBounds = CGRectZero;
        contextBounds.size = contextSize;
        CGContextClearRect(context, contextBounds);
        
        // Clip medium thumbnails so they have rounded corners
        //        if ([formatName isEqualToString:XXImageFormatNameUserThumbnailMedium]) {
        //            UIBezierPath clippingPath = [self _clippingPath];
        //            [clippingPath addClip];
        //        }
        
        UIGraphicsPushContext(context);
        [image drawInRect:contextBounds];
        UIGraphicsPopContext();
    };
}

@end
