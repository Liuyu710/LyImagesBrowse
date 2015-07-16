//
//  LYImagesBrowseView.m
//  ImagesBrowseDemo
//
//  Created by LiuYu on 14-9-29.
//  Copyright (c) 2014年 Liuyu. All rights reserved.
//

#import "LYImagesBrowseView.h"

#ifndef kPathCaches
#define kPathCaches [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#endif

// 图片缓存路径
#define kPathImagesBrowseCacheDirectory     [kPathCaches stringByAppendingPathComponent:kImagesBrowseCacheDirectoryName]
#define kPathImagesBrowseCache(fileName)    [kPathImagesBrowseCacheDirectory stringByAppendingPathComponent:fileName]
// 图片缓存管理文件路径
#define kPathCacheManagerFile               [kPathImagesBrowseCacheDirectory stringByAppendingPathComponent:@"manager.plist"]


#define kCollectionViewCellIdentifier @"LYImagesBrowseView"

@interface LYImagesBrowseView () <UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSFileManager *fileManager;
@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableDictionary *downloadingImageURLs; // 保存正在下载的image，避免重复下载的问题
@property (strong, nonatomic) NSMutableDictionary *manager;

@end


@implementation LYImagesBrowseView

+ (void)removeAllCacheImage
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 删除文件夹
    [fileManager removeItemAtPath:kPathImagesBrowseCacheDirectory error:nil];
    // 创建文件夹
    [fileManager createDirectoryAtPath:kPathImagesBrowseCacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
}

- (instancetype)initWithFrame:(CGRect)frame imageURLs:(NSArray *)imageURLs
{
    self = [self initWithFrame:frame];
    if (self) {
        // Custom initialization
        self.imageURLs = imageURLs;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    // 如果没有缓存文件夹，则创建
    if (![self.fileManager fileExistsAtPath:kPathImagesBrowseCacheDirectory]) {
        [self.fileManager createDirectoryAtPath:kPathImagesBrowseCacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    self = [super initWithFrame:frame];
    if (self) {
        // Custom initialization
        
        // 创建一个滚动显示的容器
        do {
            UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
            flowLayout.itemSize = frame.size;
            flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            flowLayout.minimumLineSpacing = 0;
            
            UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
            collectionView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            collectionView.pagingEnabled = YES;
            [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCollectionViewCellIdentifier];
            collectionView.delegate = self;
            collectionView.dataSource = self;
            [self addSubview:collectionView];
            self.collectionView = collectionView;
        } while (0);
    }
    return self;
}

#pragma mark - Setter
- (void)setImageURLs:(NSArray *)imageURLs
{
    _imageURLs = imageURLs;
    [self.collectionView reloadData];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).itemSize = frame.size;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    
    self.collectionView.backgroundColor = backgroundColor;
}

- (void)setImageData:(NSData *)imageData forImageURL:(NSString *)imageURL
{
    // 先删除老的文件
    NSString *fileNameOld = [self.manager objectForKey:imageURL];
    if (fileNameOld) {
        [self.fileManager removeItemAtPath:kPathImagesBrowseCache(fileNameOld) error:nil];
    }
    
    // 保存imageData到本地
    NSString *fileNameNew = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    [imageData writeToFile:kPathImagesBrowseCache(fileNameNew) atomically:YES];
    
    // 保存配置文件
    [self.manager setValue:fileNameNew forKey:imageURL];
    [self.manager writeToFile:kPathCacheManagerFile atomically:YES];
}

#pragma mark - Getter
- (NSFileManager *)fileManager
{
    if (!_fileManager) _fileManager = [NSFileManager defaultManager];
    return _fileManager;
}

- (NSMutableDictionary *)manager
{
    // 先从文件初始化
    if (!_manager) {
        _manager = [NSMutableDictionary dictionaryWithContentsOfFile:kPathCacheManagerFile];
    }

    if (!_manager) {
        _manager = [NSMutableDictionary dictionary];
    }
    
    return _manager;
}
        
- (NSInteger)currentIndex
{
    CGFloat pageWidth = self.collectionView.frame.size.width;
    return (NSInteger) (floor((self.collectionView.contentOffset.x - pageWidth/2.0)/pageWidth) + 1);
}

- (UIImage *)imageForImageURL:(NSString *)imageURL
{
    NSString *fileName = [self.manager objectForKey:imageURL];
    if (fileName) {
        NSData *imageData = [NSData dataWithContentsOfFile:kPathImagesBrowseCache(fileName)];
        if (imageData) {
            UIImage *image = [UIImage imageWithData:imageData];
            return image;
        }
    }
    
    return nil;
}

- (NSMutableDictionary *)downloadingImageURLs
{
    if (!_downloadingImageURLs) _downloadingImageURLs = [NSMutableDictionary dictionary];
    return _downloadingImageURLs;
}

#pragma mark - 获取Image，缓存Image
// 获取imageURLs数组中的图片，如果没有则通过SD库进行缓存（下载）
- (UIImage *)imageAtImageURLsWithIndex:(NSInteger)index
{
    if (index < 0 || index >= self.imageURLs.count) return nil;// 越界
    
    NSURL *imageURL = [NSURL URLWithString:self.imageURLs[index]];
    if ([self.downloadingImageURLs objectForKey:imageURL.absoluteString]) {
        // 正在下载
        return nil;
    }
    
    // 获取本地缓存图片
    UIImage *image = [self imageForImageURL:imageURL.absoluteString];
    
    // 本地没有该图片，则进行图片缓存
    if (!image && imageURL) {
        [self.downloadingImageURLs setValue:[NSNull null] forKey:imageURL.absoluteString];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:imageURL] delegate:self];
        [connection start];
    }
    
    return image;
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.downloadingImageURLs removeObjectForKey:connection.currentRequest.URL.absoluteString];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.downloadingImageURLs removeObjectForKey:connection.currentRequest.URL.absoluteString];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    // 缓存图片到本地
    if ([UIImage imageWithData:cachedResponse.data]) {
        NSString *imageURL = connection.currentRequest.URL.absoluteString;
        [self.downloadingImageURLs removeObjectForKey:imageURL];
        [self setImageData:cachedResponse.data forImageURL:imageURL];
        
        // 如果是当前显示的图片更新，则需要刷新UI
        if ((self.currentIndex >= 0) && (self.currentIndex < self.imageURLs.count)) {
            NSString *currentImageURL = [NSURL URLWithString:self.imageURLs[self.currentIndex]].absoluteString;
            if ([imageURL isEqual:currentImageURL]) {
                [self.collectionView reloadData];
            }
        }
    }
    
    return nil; // 不使用NSURLCache的缓存
}

#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource
#define kTagScrollView      10011
#define kTagImageView       10012
#define kTagActivityView    10013
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return self.imageURLs.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString *cellId = kCollectionViewCellIdentifier;
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    cell.contentView.layer.cornerRadius = 2;
    cell.contentView.layer.masksToBounds = YES;
    
    UIScrollView *scrollView = (UIScrollView *)[cell.contentView viewWithTag:kTagScrollView];
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] initWithFrame:cell.bounds];
        scrollView.backgroundColor = self.backgroundColor;
        scrollView.tag = kTagScrollView;
        scrollView.delegate = self;
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 2.0;
        scrollView.showsVerticalScrollIndicator = scrollView.showsHorizontalScrollIndicator = NO;

        [cell.contentView addSubview:scrollView];
    }
    
    UIImageView *imageView = (UIImageView *)[scrollView viewWithTag:kTagImageView];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:scrollView.bounds];
        imageView.backgroundColor = scrollView.backgroundColor;
        imageView.tag = kTagImageView;
        imageView.contentMode = UIViewContentModeScaleAspectFit;

        [scrollView addSubview:imageView];
    }
    
    // 更新图片数据
    imageView.image = [self imageAtImageURLsWithIndex:indexPath.item];
    scrollView.zoomScale = 1.0;
    scrollView.scrollEnabled = (imageView.image != nil);
    
    // 如果本张图片缓存好了，则去缓存下一张图片（可设置多张缓存）
    if (imageView.image) {
        [self imageAtImageURLsWithIndex:(indexPath.item + 1)];
//        [self imageAtImageURLsWithIndex:(indexPath.item + 2)];
//        [self imageAtImageURLsWithIndex:(indexPath.item + 3)];
//        [self imageAtImageURLsWithIndex:(indexPath.item + 4)];
    }
    
    // 下载中的转圈圈提示框
    UIActivityIndicatorView *activityView = (UIActivityIndicatorView *)[imageView viewWithTag:kTagActivityView];
    if (imageView.image && activityView) {
        [activityView stopAnimating];
        [activityView removeFromSuperview];
    }
    else if (!imageView.image && !activityView) {
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.tag = kTagActivityView;
        activityView.center = CGPointMake(imageView.bounds.size.width/2.0, imageView.bounds.size.height/2.0);
        [activityView startAnimating];
        [imageView addSubview:activityView];
    }
    
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return [scrollView viewWithTag:kTagImageView];
}

@end
