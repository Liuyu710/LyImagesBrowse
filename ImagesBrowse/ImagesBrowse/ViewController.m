//
//  ViewController.m
//  ImagesBrowse
//
//  Created by LiuYu on 14-9-29.
//  Copyright (c) 2014年 Liuyu. All rights reserved.
//

#import "ViewController.h"
#import "LYImagesBrowseView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 每次启动的时候都删除
    [LYImagesBrowseView removeAllCacheImage];
    
    // 测试Demo
    LYImagesBrowseView *imagesBrowseView = [[LYImagesBrowseView alloc] initWithFrame:self.view.bounds];
    imagesBrowseView.backgroundColor = [UIColor blueColor];
    imagesBrowseView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imagesBrowseView.imageURLs = @[@"http://www.iyi8.com/uploadfile/2014/0814/20140814114439495.jpg",
                                   @"http://www.iyi8.com/uploadfile/2014/0814/20140814114440676.jpg",
                                   @"http://www.iyi8.com/uploadfile/2014/0814/20140814114437377.jpg",
                                   @"http://www.iyi8.com/uploadfile/2014/0814/20140814114441985.jpg",
                                   @"http://www.iyi8.com/uploadfile/2014/0814/20140814114439495.jpg",
                                   @"http://www.iyi8.com/uploadfile/2014/0814/20140814114440676.jpg",
                                   @"http://www.iyi8.com/uploadfile/2014/0814/20140814114437377.jpg",
                                   @"http://www.iyi8.com/uploadfile/2014/0814/20140814114441985.jpg",];
    
    [self.view addSubview:imagesBrowseView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
