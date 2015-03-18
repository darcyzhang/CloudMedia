//
//  CMMediaStillImage.h
//  CloudMedia
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CMMediaStillImage : NSObject

- (void)splitVideoToStillImage:(NSString *)videoPath
                     timeScale:(int)timeScale
                  startSeconds:(double)startSeconds
                      duration:(double)duration
                    usingBlock:(void(^)(NSString*videoPath, NSArray *imageList))block;

- (void)splitVideoforKeyframeImage:(NSString *)videoPath
                         timeScale:(int)timeScale
                        usingBlock:(void(^)(NSString*videoPath, NSArray *imageList))block;

- (void)thumbnail:(NSString *)videoPath
         timeNode:(double)seconds
        timeScale:(int)timeScale
       usingBlock:(void(^)(NSString *videoPath, UIImage *image))block;

- (void)thumbnail:(NSString *)videoPath
     timeNodeList:(NSArray *)timeList
        timeScale:(int)timeScale
       usingBlock:(void (^)(NSString *videoPath, NSArray *imageList))block;
@end
