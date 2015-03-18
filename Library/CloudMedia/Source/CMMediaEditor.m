//
//  CMMediaEditor.m
//  CloudMedia
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CMMediaEditor.h"

#import "CMMediaMergeEditor.h"
#import "CMMediaCropEditor.h"
#import "CMMediaStillImage.h"

@implementation CMMediaEditor

+ (void)mergeVideo:(NSArray *)assetsURL
          savePath:(NSString *)savePath
         timeScale:(int)timeScale
        renderSize:(CGSize)renderSize
        usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    CMMediaMergeEditor *mediaMerge = [[CMMediaMergeEditor alloc] init];
    [mediaMerge mergeVideo:assetsURL savePath:savePath timeScale:timeScale renderSize:renderSize usingBlock:block];
}

+ (void)mergeVideo:(NSURL *)videoURL
             audio:(NSURL *)audioURL
          savePath:(NSString *)savePath
           replace:(BOOL)replace
        usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    CMMediaMergeEditor *mediaMerge = [[CMMediaMergeEditor alloc] init];
    [mediaMerge mergeVideo:videoURL audio:audioURL savePath:savePath replace:replace usingBlock:block];
}

+ (void)mergeVideo:(NSURL *)videoURL
         imageList:(NSArray *)imageList
         imageRect:(NSArray *)imageRect
          savePath:(NSString *)savePath
         timeScale:(int)timeScale
        renderSize:(CGSize)renderSize
        usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    CMMediaMergeEditor *mediaMerge = [[CMMediaMergeEditor alloc] init];
    [mediaMerge mergeVideo:videoURL imageList:imageList imageRect:imageRect savePath:savePath timeScale:timeScale renderSize:renderSize usingBlock:block];
}


+ (void)mergeVideoList:(NSArray *)videoList
             audioList:(NSArray *)audioList
              savePath:(NSString *)savePath
             timeScale:(int)timeScale
            renderSize:(CGSize)renderSize
            usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    CMMediaMergeEditor *mediaMerge = [[CMMediaMergeEditor alloc] init];
    [mediaMerge mergeVideoList:videoList audioList:audioList savePath:savePath timeScale:timeScale renderSize:renderSize usingBlock:block];    
}

+(void)cutVideo:(NSString *)videoPath
        savePath:(NSString *)savePath
    startSeconds:(double)startSeconds
        duration:(double)duration
       timeScale:(int)timeScale
      renderSize:(CGSize)renderSize
      usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    CMMediaCropEditor *mediaCutting = [[CMMediaCropEditor alloc] init];
    [mediaCutting cutVideo:videoPath savePath:savePath startSeconds:startSeconds duration:duration timeScale:timeScale renderSize:renderSize usingBlock:block];
    
}


+ (void)splitVideoToStillImage:(NSString *)videoPath
                     timeScale:(int)timeScale
                  startSeconds:(double)startSeconds
                      duration:(double)duration
                    usingBlock:(void(^)(NSString*videoPath, NSArray *imageList))block
{
    CMMediaStillImage *mediaStillImage = [[CMMediaStillImage alloc] init];
    [mediaStillImage splitVideoToStillImage:videoPath timeScale:timeScale startSeconds:startSeconds
                                   duration:duration usingBlock:block];
}

+ (void)splitVideoforKeyframeImage:(NSString *)videoPath
                         timeScale:(int)timeScale
                        usingBlock:(void(^)(NSString*videoPath, NSArray *imageList))block
{
    CMMediaStillImage *mediaStillImage = [[CMMediaStillImage alloc] init];
    [mediaStillImage splitVideoforKeyframeImage:videoPath timeScale:timeScale usingBlock:block];
}

+ (void)thumbnail:(NSString *)videoPath timeNode:(double)seconds
       usingBlock:(void(^)(NSString *videoPath, UIImage *image))block
{
    CMMediaStillImage *mediaStillImage = [[CMMediaStillImage alloc] init];
    [mediaStillImage thumbnail:videoPath timeNode:seconds timeScale:30 usingBlock:block];
}

+ (void)thumbnail:(NSString *)videoPath
     timeNodeList:(NSArray *)timeList
        timeScale:(int)timeScale
       usingBlock:(void (^)(NSString *videoPath, NSArray *imageList))block
{
    CMMediaStillImage *mediaStillImage = [[CMMediaStillImage alloc] init];
    [mediaStillImage thumbnail:videoPath timeNodeList:timeList timeScale:timeScale usingBlock:block];
}
@end
