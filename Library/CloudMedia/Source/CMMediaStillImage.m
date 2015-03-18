//
//  CMMediaStillImage.m
//  CloudMedia
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CMMediaStillImage.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CMMediaStillImage()

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;

@end

@implementation CMMediaStillImage

- (void)splitVideoforKeyframeImage:(NSString *)videoPath
                         timeScale:(int)timeScale
                        usingBlock:(void(^)(NSString*videoPath, NSArray *imageList))block
{
    NSURL *URL = [NSURL fileURLWithPath:videoPath];
    
    AVURLAsset *sourceAsset = [[AVURLAsset alloc] initWithURL:URL options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
    
    //获取总视频时长
    double duration = CMTimeGetSeconds([sourceAsset duration]);
    
    [self splitVideoToStillImage:videoPath timeScale:timeScale startSeconds:0 duration:duration
                      usingBlock:block];
}


- (void)splitVideoToStillImage:(NSString *)videoPath
                     timeScale:(int)timeScale
                  startSeconds:(double)startSeconds
                      duration:(double)duration
                    usingBlock:(void(^)(NSString*videoPath, NSArray *imageList))block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^()
    {
        NSURL *URL = [NSURL fileURLWithPath:videoPath];
        
        AVURLAsset *sourceAsset = [[AVURLAsset alloc] initWithURL:URL options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
        
        self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:sourceAsset];
        self.imageGenerator.appliesPreferredTrackTransform = YES;
        
        //允许的误差时间
        self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        
        NSMutableArray *times = [[NSMutableArray alloc] init];
        
        int imageNumber = timeScale * duration;
        
        for (int i = 0; i < imageNumber; i++)
        {
            double seconds = startSeconds + (double)i / timeScale;
            CMTime time = CMTimeMakeWithSeconds(seconds, timeScale);
            [times addObject:[NSValue valueWithCMTime:time]];
        }
        
        __block int counter = 0;
        __block NSMutableArray *imageArray = [[NSMutableArray alloc] init];
        
        [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times
                                             completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime,AVAssetImageGeneratorResult result, NSError *error)
         {
             if (counter < imageNumber)
             {
                 counter++;
                 
                 if (result == AVAssetImageGeneratorSucceeded)
                 {
                     
                     UIImage *imageItem = [UIImage imageWithCGImage:image];
                     [imageArray addObject:imageItem];
                     
                 }
             }
             else
             {
                 dispatch_async(dispatch_get_main_queue(), ^()
                 {
                     if (block)
                     {
                         block(videoPath,imageArray);
                         self.imageGenerator = nil;
                     }
                 });
             }
         }];
    });

}

- (void)thumbnail:(NSString *)videoPath timeNode:(double)seconds timeScale:(int)timeScale
       usingBlock:(void(^)(NSString *videoPath, UIImage *image))block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^()
    {
        NSURL *URL = [NSURL fileURLWithPath:videoPath];
        
        AVURLAsset *sourceAsset = [[AVURLAsset alloc] initWithURL:URL options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
        
        self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:sourceAsset];
        self.imageGenerator.appliesPreferredTrackTransform = YES;
        
        //允许的误差时间
        self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        
        NSArray *times = [NSArray arrayWithObjects:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(seconds, timeScale)], nil];
        
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime,
                                                           CGImageRef image,
                                                           CMTime actualTime,
                                                           AVAssetImageGeneratorResult result,
                                                           NSError *error)
        {
            UIImage *imageItem = [UIImage imageWithCGImage:image];
            
            dispatch_async(dispatch_get_main_queue(), ^()
            {
                if (block)
                {
                    block(videoPath,imageItem);
                }
                self.imageGenerator = nil;
            });
        };
        
        [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:handler];
    });
}

- (void)thumbnail:(NSString *)videoPath
     timeNodeList:(NSArray *)timeList
        timeScale:(int)timeScale
       usingBlock:(void (^)(NSString *videoPath, NSArray *imageList))block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^()
    {
        NSURL *URL = [NSURL fileURLWithPath:videoPath];
                       
        AVURLAsset *sourceAsset = [[AVURLAsset alloc] initWithURL:URL options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey]];
                       
        self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:sourceAsset];
                       self.imageGenerator.appliesPreferredTrackTransform = YES;
                       
        //允许的误差时间
        //self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        //self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
                       
        NSMutableArray *times = [[NSMutableArray alloc] initWithCapacity:[timeList count]];
        
                       
        for (NSNumber *item in timeList)
        {
            double seconds = [item doubleValue];
            
            CMTime time = CMTimeMakeWithSeconds(seconds, timeScale);
            
            [times addObject:[NSValue valueWithCMTime:time]];
            
        }
        
        __block NSMutableArray *imageList = [[NSMutableArray alloc] initWithCapacity:[times count]];
        __block int counter = 0;
        [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times
                                            completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime,AVAssetImageGeneratorResult result, NSError *error)
        {
            
            if (result == AVAssetImageGeneratorSucceeded)
            {
                UIImage *imageItem = [UIImage imageWithCGImage:image];
                [imageList addObject:imageItem];
            }
            
            counter ++;
            
            if (counter >= [times count])
            {
                dispatch_async(dispatch_get_main_queue(), ^()
                               {
                                   if (block)
                                   {
                                       block(videoPath,imageList);
                                   }
                               });
            }
        }];
    });
}

@end
