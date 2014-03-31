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
    
    [YSImageRequest removeAllCache];
    
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
        __block NSUInteger requestNum = [tags count];
        NSLog(@"[Start request] requestNum: %@", @(requestNum));
        for (NSString *tag in tags) {
            NSString *urlStr = [NSString stringWithFormat:@"http://api.twitpic.com/2/tags/show.json?tag=%@", tag];
            NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
            __weak typeof(self) wself = self;
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperationManager manager] HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, id json)
                                                 {
//                                                     NSLog(@"Success: json: %@", json);
                                                     for (NSDictionary *imageDict in [json objectForKey:@"images"]) {
                                                         TwitPicImage *img = [[TwitPicImage alloc] initWithDictonary:imageDict];
                                                         img.tag = tag;
                                                         [wself.twitPicImages addObject:img];
                                                     }
                                                     NSLog(@"Success %@", @(requestNum));
                                                     requestNum--;
                                                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     NSLog(@"Failure: operation: %@, error: %@", operation, error);
                                                     requestNum--;
                                                 }];

            [[[self class] imageJsonsOperationQueue] addOperation:operation];
            self.requestOperation = operation;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            while (requestNum != 0) {
                NSLog(@"Wait...");
                [NSThread sleepForTimeInterval:1.];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
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
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", @(indexPath.row)];
    cell.detailTextLabel.text = twitPicImage.tag;
    
    NSString *urlStr = [NSString stringWithFormat:@"http://twitpic.com/show/thumb/%@", twitPicImage.short_id];
    
    [cell setImageWithURL:[NSURL URLWithString:urlStr]];
    
//    [cell.imageView setImageWithURL:[NSURL URLWithString:urlStr]
//                   placeholderImage:];
    
//    [cell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]
//                          placeholderImage:nil
//                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                       NSLog(@"image %@", NSStringFromCGSize(image.size));
//                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
//                                       NSLog(@"failure %@", response);
//                                   }];
    
    return cell;
}

@end
