//
//  YSImageRequestTests.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2015/01/05.
//  Copyright (c) 2015年 Yu Sugawara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "YSImageRequest.h"

@interface YSImageRequestTests : XCTestCase

@end

@implementation YSImageRequestTests

- (void)setUp
{
    [super setUp];
    
    [[YSImageRequest filteredImageCache] clearMemory];
    [[YSImageRequest filteredImageCache] clearDisk];
    [[YSImageRequest originalImageCache] clearMemory];
    [[YSImageRequest originalImageCache] clearDisk];
}

#pragma mark - State

- (void)testState
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    
    YSImageRequest *req = [YSImageRequest requestImageWithURL:[self sampleImageURL] options:0 filter:nil progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        XCTAssertFalse([NSThread isMainThread]);
    } completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertNotNil(image);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    XCTAssertNotNil(req);
    
    [self waitForExpectationsWithTimeout:10. handler:^(NSError *error) {
        XCTAssertNil(error, @"error: %@", error);
    }];
}

#pragma mark - Utility

- (NSString*)sampleImageURLString
{
    return @"http://pbs.twimg.com/profile_images/378800000787543122/5effc306aa47d2016d27d4f24da80416_normal.png";
}

- (NSURL*)sampleImageURL
{
    return [NSURL URLWithString:[self sampleImageURLString]];
}

@end
