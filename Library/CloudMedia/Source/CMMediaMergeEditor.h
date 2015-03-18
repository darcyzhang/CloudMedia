//
//  CMMediaMergeEditor.h
//  CloudMedia
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CMMediaMergeEditor : NSObject

- (void)mergeVideo:(NSArray *)assetsURL
          savePath:(NSString *)savePath
         timeScale:(int)timeScale
        renderSize:(CGSize)renderSize
        usingBlock:(void(^)(NSString *savePath, NSError *error))block;

- (void)mergeVideo:(NSURL *)videoURL
             audio:(NSURL *)audioURL
          savePath:(NSString *)savePath
           replace:(BOOL)replace
        usingBlock:(void(^)(NSString *savePath, NSError *error))block;

- (void)mergeVideo:(NSURL *)videoURL
         imageList:(NSArray *)imageList
         imageRect:(NSArray *)imageRect
          savePath:(NSString *)savePath
         timeScale:(int)timeScale
        renderSize:(CGSize)renderSize
        usingBlock:(void(^)(NSString *savePath, NSError *error))block;

- (void)mergeVideoList:(NSArray *)videoList
             audioList:(NSArray *)audioList
              savePath:(NSString *)savePath
             timeScale:(int)timeScale
            renderSize:(CGSize)renderSize
            usingBlock:(void(^)(NSString *savePath, NSError *error))block;
@end
