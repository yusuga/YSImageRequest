//
//  YSImageRequestExampleTests.m
//  YSImageRequestExampleTests
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YSImageRequest.h"
#import <YSFileManager/YSFileManager.h>
#import <TKRGuard/TKRGuard.h>

@interface YSImageRequestExampleTests : XCTestCase

@end

@implementation YSImageRequestExampleTests

- (void)setUp
{
    [super setUp];
    
    [TKRGuard setDefaultTimeoutInterval:10.];
    
    for (NSString *dirName in [YSFileManager fileNamesAtDirectoryPath:[YSFileManager cachesDirectory]]) {
        if ([dirName hasPrefix:TMDiskCachePrefix]) {
            NSString *path = [YSFileManager cachesDirectoryWithAppendingPathComponent:dirName];
            for (NSString *fileName in [YSFileManager fileNamesAtDirectoryPath:path]) {
                [YSFileManager removeAtPath:[path stringByAppendingPathComponent:fileName]];
            }
        }
    }
    for (NSString *dirName in [YSFileManager fileNamesAtDirectoryPath:[YSFileManager cachesDirectory]]) {
        if ([dirName hasPrefix:TMDiskCachePrefix]) {
            NSString *path = [YSFileManager cachesDirectoryWithAppendingPathComponent:dirName];
            XCTAssertTrue([[YSFileManager fileNamesAtDirectoryPath:path] count] == 0, @"path: %@", path);
        }
    }
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSString*)cacheDirctoryNameWithCacheName:(NSString*)cacheName
{
    return [NSString stringWithFormat:@"%@.%@", TMDiskCachePrefix, cacheName];
}

- (NSString*)cacheDirctoryPathWithCacheName:(NSString*)cacheName
{
    return [YSFileManager cachesDirectoryWithAppendingPathComponent:[self cacheDirctoryNameWithCacheName:cacheName]];
}

- (void)createDummyFileWithCacheName:(NSString*)cacheName
{
    NSUInteger dummyFileCount = 10;
    for (NSUInteger i = 0; i < dummyFileCount; i++) {
        NSString *fileName = [NSString stringWithFormat:@"testFile%zd.txt", i];
        NSString *path = [self cacheDirctoryPathWithCacheName:cacheName];
        if (![YSFileManager fileExistsAtPath:path]) {
            [YSFileManager createDirectoryAtPath:path];
        }
        NSURL *url = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:fileName]];
        NSError *error = nil;
        [@"test" writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
        XCTAssertNil(error, @"error: %@", error);
    }
    NSArray *files = [YSFileManager fileNamesAtDirectoryPath:[self cacheDirctoryPathWithCacheName:cacheName] extension:@"txt"];
    XCTAssertTrue([files count] == dummyFileCount, @"count: %zd", [files count]);
}

- (NSURL*)imageURL
{
    return [NSURL URLWithString:@"http://www.google.com/favicon.ico"];
}

#pragma mark - remove

- (void)testRemoveDiskCache
{
    NSString *cacheName = @"removeDiskCache";
    [self createDummyFileWithCacheName:cacheName];
    [YSImageRequest removeCachedOriginalImagesWithDiskCacheName:cacheName completion:^{
        RESUME;
    }];
    WAIT;
    NSString *path = [self cacheDirctoryPathWithCacheName:cacheName];
    NSArray *files = [YSFileManager fileNamesAtDirectoryPath:path];
    XCTAssertTrue([files count] == 0, @"files: %@", files);
}

- (void)testRemoveAllDiskCache
{
    NSMutableArray *cacheFileNames = @[].mutableCopy;
    for (NSUInteger i = 0; i < 5; i++) {
        NSString *cacheName = [NSString stringWithFormat:@"allRemoveDiskCache%zd", i];
        [cacheFileNames addObject:cacheName];
        [self createDummyFileWithCacheName:cacheName];
    }
    
    [YSImageRequest removeAllCachedOriginalImagesWithCompletion:^{
        RESUME;
    }];
    WAIT;
    
    for (NSString *cacheName in cacheFileNames) {
        NSString *path = [self cacheDirctoryPathWithCacheName:cacheName];
        NSArray *files = [YSFileManager fileNamesAtDirectoryPath:path];
        XCTAssertTrue([files count] == 0, @"files: %@", files);
    }
}

#pragma mark - cancel

- (void)testCancelReqeustOriginalImage
{
    NSURL *url = [self imageURL];
    
    YSImageRequest *req = [[YSImageRequest alloc] init];
    [req requestOriginalImageWithURL:url completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertNil(image);
        XCTAssertNotNil(error, @"error: %@", error);
        XCTAssertTrue([error.domain isEqualToString:YSImageRequestErrorDomain], @"domain: %@", error.domain);
        XCTAssertTrue(error.code == YSImageRequestErrorCodeCancel, @"code: %zd", error.code);
        XCTAssertTrue(request.isCancelled);
        XCTAssertFalse(request.isRequested);
        XCTAssertFalse(request.isCompleted);
        RESUME;
    }];
    [req cancel];
    WAIT;
}

- (void)testCancelRequestFilterdlImage
{
    NSURL *url = [self imageURL];
    
    YSImageRequest *req = [[YSImageRequest alloc] init];
    [req requestFilteredImageWithURL:url size:CGSizeMake(30, 30) willRequestImage:^(YSImageRequest *request) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertFalse(request.isCancelled);
        XCTAssertFalse(request.isCompleted);
    } completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertNil(image);
        XCTAssertNotNil(error, @"error: %@", error);
        XCTAssertTrue([error.domain isEqualToString:YSImageRequestErrorDomain], @"domain: %@", error.domain);
        XCTAssertTrue(error.code == YSImageRequestErrorCodeCancel, @"code: %zd", error.code);
        XCTAssertTrue(request.isCancelled);
        XCTAssertFalse(request.isRequested);
        XCTAssertFalse(request.isCompleted);
        RESUME;
    }];
    [req cancel];
    WAIT;
}

#pragma mark - request

- (void)testRequestOriginalImage
{
    NSURL *url = [self imageURL];
    YSImageRequest *req = [[YSImageRequest alloc] init];
    [req requestOriginalImageWithURL:url completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertNotNil(image);
        XCTAssertNil(error, @"error: %@", error);
        XCTAssertFalse(request.isCancelled);
        XCTAssertTrue(request.isRequested);
        XCTAssertTrue(request.isCompleted);
        RESUME;
    }];
    WAIT;
    
    YSImageRequest *req2 = [[YSImageRequest alloc] init];
    [req2 requestOriginalImageWithURL:url completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertNotNil(image);
        XCTAssertNil(error, @"error: %@", error);
        XCTAssertFalse(request.isCancelled);
        XCTAssertFalse(request.isRequested);
        XCTAssertTrue(request.isCompleted);
        RESUME;
    }];
    WAIT;
}

- (void)testRequestFilterdImage
{
    NSURL *url = [self imageURL];
    
    /* first requst */
    YSImageRequest *req = [[YSImageRequest alloc] init];
    CGSize resize = CGSizeMake(30, 30);
    [req requestFilteredImageWithURL:url size:resize willRequestImage:^(YSImageRequest *request) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertFalse(request.isCancelled);
        XCTAssertFalse(request.isRequested);
        XCTAssertFalse(request.isCompleted);
    } completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertNotNil(image);
        XCTAssertTrue(CGSizeEqualToSize(image.size, resize), @"image.size: %@, resize: %@", NSStringFromCGSize(image.size), NSStringFromCGSize(resize));
        XCTAssertNil(error, @"error: %@", error);
        XCTAssertFalse(request.isCancelled);
        XCTAssertTrue(request.isRequested);
        XCTAssertTrue(request.isCompleted);
        RESUME;
    }];
    WAIT;
    
    /* get cached image */
    YSImageRequest *req2 = [[YSImageRequest alloc] init];
    [req2 requestFilteredImageWithURL:url size:resize willRequestImage:^(YSImageRequest *request) {
        XCTFail();
    } completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertNotNil(image);
        XCTAssertTrue(CGSizeEqualToSize(image.size, resize), @"image.size: %@, resize: %@", NSStringFromCGSize(image.size), NSStringFromCGSize(resize));
        XCTAssertNil(error, @"error: %@", error);
        XCTAssertFalse(request.isCancelled);
        XCTAssertFalse(request.isRequested);
        XCTAssertTrue(request.isCompleted);
        RESUME;
    }];
    WAIT;
    
    /* get other resize image */
    CGSize resize2 = CGSizeMake(50, 50);
    YSImageRequest *req3 = [[YSImageRequest alloc] init];
    [req3 requestFilteredImageWithURL:url size:resize2 willRequestImage:^(YSImageRequest *request) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertFalse(request.isCancelled);
        XCTAssertFalse(request.isRequested);
        XCTAssertFalse(request.isCompleted);
    } completion:^(YSImageRequest *request, UIImage *image, NSError *error) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqual:url], @"request.url: %@, url: %@", request.url, url);
        XCTAssertNotNil(image);
        XCTAssertTrue(CGSizeEqualToSize(image.size, resize2), @"image.size: %@, resize2: %@", NSStringFromCGSize(image.size), NSStringFromCGSize(resize2));
        XCTAssertNil(error, @"error: %@", error);
        XCTAssertFalse(request.isCancelled);
        XCTAssertFalse(request.isRequested);
        XCTAssertTrue(request.isCompleted);
        RESUME;
    }];
    WAIT;
}

@end
