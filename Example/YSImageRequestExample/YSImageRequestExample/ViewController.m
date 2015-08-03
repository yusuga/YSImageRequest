//
//  ViewController.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "ViewController.h"
#import "YSImageRequest.h"
#import "TableViewCell.h"

static NSString * const kCellIdentifier = @"Cell";

@interface ViewController ()

@property (nonatomic) NSArray *urlStrings;

@end

@implementation ViewController

- (void)awakeFromNib
{
    self.urlStrings = [[self class] urlStrings];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.urlStrings count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    NSString *urlStr = [self.urlStrings objectAtIndex:indexPath.row];
    
    CGInterpolationQuality quality = (indexPath.row%4) + 1;
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", @(indexPath.row), [self stringFromQuality:quality]];
    [cell setImageWithURL:[NSURL URLWithString:urlStr] quality:quality];
    
    return cell;
}

#pragma mark - Button action

- (IBAction)removeFilteredImageCacheButtonDidPush:(id)sender
{
    [[YSImageRequest filteredImageCache] clearMemory];
    [[[UIAlertView alloc] initWithTitle:@"Completion" message:@"Remove all filtered image cache." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (IBAction)removeOriginalImageMemoryCacheButtonDidPush:(id)sender
{
    [[YSImageRequest originalImageCache] clearMemory];
    [[[UIAlertView alloc] initWithTitle:@"Completion" message:@"Remove all original image memory cache." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}
- (IBAction)removeOriginalImageDiskCacheButtonDidPush:(id)sender
{
    [[YSImageRequest originalImageCache] clearDiskOnCompletion:^{
        [[[UIAlertView alloc] initWithTitle:@"Completion" message:@"Remove all original image disk cache." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }];
}

#pragma mark - Utility

- (NSString*)stringFromQuality:(CGInterpolationQuality)quality
{
    switch (quality) {
        case kCGInterpolationDefault:
            return @"Quality-default";
        case kCGInterpolationHigh:
            return @"Quality-high";
        case kCGInterpolationLow:
            return @"Quality-low";
        case kCGInterpolationMedium:
            return @"Quality-medium";
        case kCGInterpolationNone:
            return @"Quality-none";
        default:
            return nil;
    }
}

+ (NSArray*)urlStrings
{
    static NSArray *__urlStrings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUInteger count = 102;
        NSMutableArray *strings = [NSMutableArray arrayWithCapacity:count + 2];
        [strings addObject:@"http://assets.sbnation.com/assets/2512203/dogflops.gif"];
//        [strings addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
//        [strings addObject:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"];
        
        for (NSUInteger i = 0; i < count; i++) {
            [strings addObject:[NSString stringWithFormat:@"http://placehold.it/300x300&text=image%zd", i + 1]];
//            [strings addObject:[NSString stringWithFormat:@"http://placehold.it/500x500&text=image%zd", i + 1]];
//            [strings addObject:[NSString stringWithFormat:@"http://placehold.it/1000x1000&text=image%zd", i + 1]];
//            [strings addObject:[NSString stringWithFormat:@"http://placehold.it/1500x1500&text=image%zd", i + 1]];
//            [strings addObject:[NSString stringWithFormat:@"http://placehold.it/2000x2000&text=image%zd", i + 1]];
        }
        
        __urlStrings = [NSArray arrayWithArray:strings];
    });
    return __urlStrings;
}

@end
