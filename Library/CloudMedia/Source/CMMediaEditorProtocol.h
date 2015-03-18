//
//  CMMediaEditorProtocol.h
//  CloudMedia
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CMMediaEditorProtocol <NSObject>

/*
 合并多个视频
 
 */
+ (void)mergeVideo:(NSArray *)assetsURL
          savePath:(NSString *)savePath
         timeScale:(int)timeScale
        renderSize:(CGSize)renderSize
        usingBlock:(void(^)(NSString *savePath, NSError *error))block;

/*
 合并视频和音频
 */
+ (void)mergeVideo:(NSURL *)videoURL
             audio:(NSURL *)audioURL
          savePath:(NSString *)savePath
           replace:(BOOL)replace
        usingBlock:(void(^)(NSString *savePath, NSError *error))block;

/*
 合并一组音视频
 */
+ (void)mergeVideoList:(NSArray *)videoList
             audioList:(NSArray *)audioList
              savePath:(NSString *)savePath
             timeScale:(int)timeScale
            renderSize:(CGSize)renderSize
            usingBlock:(void(^)(NSString *savePath, NSError *error))block;

/*
 视频添加图片
 */
+ (void)mergeVideo:(NSURL *)videoURL
         imageList:(NSArray *)imageList
         imageRect:(NSArray *)imageRect
          savePath:(NSString *)savePath
         timeScale:(int)timeScale
        renderSize:(CGSize)renderSize
        usingBlock:(void(^)(NSString *savePath, NSError *error))block;
/*
 视频裁剪
 */
+(void)cutVideo:(NSString *)videoPath
       savePath:(NSString *)savePath
   startSeconds:(double)startSeconds
       duration:(double)duration
      timeScale:(int)timeScale
     renderSize:(CGSize)renderSize
     usingBlock:(void(^)(NSString *savePath, NSError *error))block;
/*
 取视频指定时间区域的图片
 */

+ (void)splitVideoToStillImage:(NSString *)videoPath
                     timeScale:(int)timeScale
                  startSeconds:(double)startSeconds
                      duration:(double)duration
                    usingBlock:(void(^)(NSString*videoPath, NSArray *imageList))block;

/*
 取视频关键帧图片
 */

+ (void)splitVideoforKeyframeImage:(NSString *)videoPath
                         timeScale:(int)timeScale
                        usingBlock:(void(^)(NSString*videoPath, NSArray *imageList))block;

/*
 取视频指定时间点的缩略图
 */

+ (void)thumbnail:(NSString *)videoPath timeNode:(double)seconds
       usingBlock:(void(^)(NSString *videoPath, UIImage *image))block;

/*
 取视频指定一组时间点的缩略图
 */
+ (void)thumbnail:(NSString *)videoPath
     timeNodeList:(NSArray *)timeList
        timeScale:(int)timeScale
       usingBlock:(void (^)(NSString *videoPath, NSArray *imageList))block;



@end
