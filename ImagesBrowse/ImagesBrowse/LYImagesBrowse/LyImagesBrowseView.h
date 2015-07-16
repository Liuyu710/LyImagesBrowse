//
//  LYImagesBrowseView.h
//  ImagesBrowseDemo
//
//  Created by LiuYu on 14-9-29.
//  Copyright (c) 2014年 Liuyu. All rights reserved.
//

#import <UIKit/UIKit.h>

// 缓存在Cache目录下
#define kImagesBrowseCacheDirectoryName @"ImageBrowseCache"

/*!
 *  图片浏览的View，图片缓存（下载）使用的是NSURLCache，
 *  1. 目前支持 iOS6.0+
 *  2. 使用 NSURLConnection 下载图片
 *  3. 采用文件缓存
 */
@interface LYImagesBrowseView : UIView

@property (nonatomic, strong) NSArray *imageURLs;
@property (nonatomic, assign) NSInteger currentIndex;   // 从 0 开始

/*!
 *  创建方法
 *
 *  @param frame     
 *  @param imageURLs 必须传入，如 @[@"http:www.baidu.com/.../x1.jpg", @"http:www.baidu.com/.../x2.jpg"]
 *
 *  @return self
 */
- (instancetype)initWithFrame:(CGRect)frame imageURLs:(NSArray *)imageURLs;

/*!
 *  删除所有的图片缓存
 */
+ (void)removeAllCacheImage;

@end
