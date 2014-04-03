//
//  ViewController.m
//  YSImageRequestExample
//
//  Created by Yu Sugawara on 2014/03/23.
//  Copyright (c) 2014年 Yu Sugawara. All rights reserved.
//

#import "ViewController.h"
#import "TwitPicImage.h"
#import "YSImageRequest.h"
#import "TableViewCell.h"

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <YSUIKitAdditions/UIImage+YSUIKitAdditions.h>

static NSString * const kCellIdentifier = @"Cell";

@interface ViewController ()

@property (nonatomic) AFHTTPRequestOperation *requestOperation;
@property (nonatomic) NSMutableArray *twitPicImages;

@end

@implementation ViewController

+ (NSOperationQueue*)imageJsonsOperationQueue
{
    static NSOperationQueue *s_operationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_operationQueue = [[NSOperationQueue alloc] init];
        [s_operationQueue setMaxConcurrentOperationCount:1];
    });
    return s_operationQueue;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [YSImageRequest removeAllRequestCacheWithCompletion:nil];
    [YSImageRequest removeAllFilterCacheWithCompletion:nil];
    
    self.twitPicImages = @[].mutableCopy;    
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    __weak typeof(self) wself = self;
    NSArray *tags;
//    tags = @[@"cat"];
//    tags = @[@"cat", @"dog"];
    tags = @[@"cat", @"dog", @"iphone", @"tbt", @"bff", @"like4like", @"StarbucksFail"];
    [self requestWithTags:tags completion:^{
        NSLog(@"request completion");
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [wself.tableView reloadData];
    }];
}

- (void)requestWithTags:(NSArray*)tags completion:(void(^)(void))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[Start request] requestNum: %@", @([tags count]));
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        for (NSString *tag in tags) {
            __weak typeof(self) wself = self;
            
            void(^setTwitPicImages)(NSString* tag, NSDictionary *json) = ^(NSString *tag, NSDictionary *json){
                // NSLog(@"Success: json: %@", json);
                for (NSDictionary *imageDict in [json objectForKey:@"images"]) {
                    TwitPicImage *img = [[TwitPicImage alloc] initWithDictonary:imageDict];
                    img.tag = tag;
                    [wself.twitPicImages addObject:img];
                }
            };
            
            NSData *jsonData = [ud objectForKey:tag];
            if (jsonData) {
                NSDictionary *json = [NSKeyedUnarchiver unarchiveObjectWithData:jsonData];
                NSLog(@"cached json, tag: %@", tag);
                setTwitPicImages(tag, json);
                continue;
            }
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

            NSString *urlStr = [NSString stringWithFormat:@"http://api.twitpic.com/2/tags/show.json?tag=%@", tag];
            NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperationManager manager] HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, id json)
                                                 {
                                                     NSLog(@"Success");
                                                     setTwitPicImages(tag, json);
                                                     [ud setObject:[NSKeyedArchiver archivedDataWithRootObject:json] forKey:tag];
                                                     dispatch_semaphore_signal(semaphore);
                                                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     NSLog(@"Failure: operation: %@, error: %@", operation, error);
                                                     dispatch_semaphore_signal(semaphore);
                                                 }];
            
            [[[self class] imageJsonsOperationQueue] addOperation:operation];
            self.requestOperation = operation;
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.twitPicImages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    TwitPicImage *twitPicImage = [self.twitPicImages objectAtIndex:indexPath.row];
    
    NSString *urlStr = [NSString stringWithFormat:@"http://twitpic.com/show/thumb/%@", twitPicImage.short_id];
    
    CGInterpolationQuality quality = (indexPath.row%4) + 1;
    [cell setImageWithURL:[NSURL URLWithString:urlStr] quality:quality];
    
    NSString *qualityStr;
    switch (quality) {
        case kCGInterpolationNone:
            qualityStr = @"None";
            break;
        case kCGInterpolationLow:
            qualityStr = @"Low";
            break;
        case kCGInterpolationMedium:
            qualityStr = @"Medium";
            break;
        case kCGInterpolationHigh:
            qualityStr = @"High";
            break;
        default:
            break;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", @(indexPath.row), qualityStr];
    cell.detailTextLabel.text = twitPicImage.tag;
    
    return cell;
}

@end
