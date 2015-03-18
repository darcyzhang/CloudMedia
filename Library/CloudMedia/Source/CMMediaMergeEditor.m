//
//  CMMediaMergeEditor.m
//  CloudMedia
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CMMediaMergeEditor.h"
#import <AVFoundation/AVFoundation.h>

#define kKeyFrameOffset 5

@interface CMMediaMergeEditor ()


@end


@implementation CMMediaMergeEditor

//多个视频合并成一个视频

- (void)mergeVideo:(NSArray *)assetsURL
          savePath:(NSString *)savePath
         timeScale:(int)timeScale
        renderSize:(CGSize)renderSize
        usingBlock:(void(^)(NSString *savePath, NSError *error))block
{

    if (![assetsURL count])
    {
        NSError *error = [NSError errorWithDomain:@"QVMVFoundation" code:1001 userInfo:nil];
        block(savePath,error);
        return ;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^()
    {
        if ([assetsURL count] == 1) //只有一个视频
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSURL *atPath = [assetsURL objectAtIndex:0];
            
            NSError *error = nil;
            if ([fileManager fileExistsAtPath:savePath])
            {
                [fileManager removeItemAtPath:savePath error:&error];
            }
            
            if ([fileManager copyItemAtPath:[atPath path] toPath:savePath error:&error])
            {
                dispatch_async(dispatch_get_main_queue(), ^()
                {
                    block(savePath,nil);
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^()
                {
                    block(savePath,error);
                });
            }
            return;
        }
        
        //多视频合成

        AVMutableComposition *saveComposition = [AVMutableComposition composition];
        
        NSMutableArray *instructionList = [[NSMutableArray alloc] init];
        
        CMTime totalDuration = kCMTimeZero;
        
        for (NSURL *assetURL in assetsURL)
        {
            AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
            
            //视频合成
            AVAssetTrack *sourceVideoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            
            AVMutableCompositionTrack *compositionVideoTrack = [saveComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            
            
            CMTime start = CMTimeMake(kKeyFrameOffset, timeScale);
            CMTime duration = CMTimeSubtract(sourceAsset.duration, start);
            
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(start, duration) ofTrack:sourceVideoTrack atTime:totalDuration error:nil];
            
            //音频合成
            AVAssetTrack *sourceAudioTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            AVMutableCompositionTrack *compositionAudioTrack = [saveComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(start, duration) ofTrack:sourceAudioTrack atTime:totalDuration error:nil];
            
            AVMutableVideoCompositionLayerInstruction *layerInstruction =[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
            
            [layerInstruction setTransform:sourceVideoTrack.preferredTransform atTime:totalDuration];
            
            totalDuration = CMTimeAdd(totalDuration, duration);
            
            [layerInstruction setOpacity:0.0 atTime:totalDuration];
            
            [instructionList addObject:layerInstruction];
            
            /*
            NSLog(@"\n source asset duration is %f \n source vid track timerange is %f %f \n composition duration is %f \n composition vid track time range is %f %f",
                  CMTimeGetSeconds([sourceAsset duration]),
                  CMTimeGetSeconds(sourceVideoTrack.timeRange.start),
                  CMTimeGetSeconds(sourceVideoTrack.timeRange.duration),
                  CMTimeGetSeconds([saveComposition duration]),
                  CMTimeGetSeconds(compositionVideoTrack.timeRange.start),
                  CMTimeGetSeconds(compositionVideoTrack.timeRange.duration));
             */
        }
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.frameDuration = CMTimeMake(1,timeScale);
        videoComposition.renderScale = 1.0;
        videoComposition.renderSize = renderSize;
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.layerInstructions = instructionList;
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
        videoComposition.instructions = [NSArray arrayWithObject:instruction];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:savePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];
        }
        
        NSURL *url = [[NSURL alloc] initFileURLWithPath:savePath];
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:saveComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.videoComposition = videoComposition;
        exporter.outputURL = url;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        //[exporter setOutputFileType:AVFileTypeMPEG4];
        [exporter exportAsynchronouslyWithCompletionHandler:^
        {
            switch (exporter.status)
            {
                case AVAssetExportSessionStatusFailed:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                        if (block)
                        {
                            block(savePath,[exporter error]);
                        }
                    });
                    break;
                }
                case AVAssetExportSessionStatusCompleted:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                        if (block)
                        {
                            block(savePath,nil);
                        }
                    });
                    break;
                }
                default:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                        if (block)
                        {
                            block(savePath,[exporter error]);
                        }
                    });
                    break;
                }
            }
        }];

    });
}

- (void)mergeVideo:(NSURL *)videoURL
             audio:(NSURL *)audioURL
          savePath:(NSString *)savePath
           replace:(BOOL)replace
        usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    dispatch_async(dispatch_get_current_queue(), ^()
    {
        AVMutableComposition *mutableComposition = [AVMutableComposition composition];
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil];
        
        //视频轨道
        AVURLAsset *movieURLAsset = [[AVURLAsset alloc] initWithURL:videoURL options:options];
        
        AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSArray *videoTrackArray = [movieURLAsset tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTrackArray count])
        {
            AVAssetTrack *videoTrack = [videoTrackArray objectAtIndex:0];
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, movieURLAsset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
        }
        
        //影片原本的音频轨道
        if (!replace)
        {
        }
        
        //合成的声音轨道
        AVURLAsset *soundURLAsset = [[AVURLAsset alloc] initWithURL:audioURL options:options];

        NSArray *soundTrackArray = [soundURLAsset tracksWithMediaType:AVMediaTypeAudio];
        
        if ([soundTrackArray count])
        {
            AVAssetTrack *soundTrack = [soundTrackArray objectAtIndex:0];
            
            AVMutableCompositionTrack *compositionSoundTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionSoundTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, movieURLAsset.duration) ofTrack:soundTrack atTime:kCMTimeZero error:nil];
        }
        
        //输出合成后的音视频
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetPassthrough];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:savePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];
        }
        
        exporter.outputURL = [NSURL fileURLWithPath:savePath];
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        [exporter exportAsynchronouslyWithCompletionHandler:^
         {
             switch (exporter.status)
             {
                 case AVAssetExportSessionStatusFailed:
                 {
                     dispatch_async(dispatch_get_main_queue(), ^()
                     {
                         if (block)
                         {
                             block(savePath,[exporter error]);
                         }
                     });
                     break;
                 }
                 case AVAssetExportSessionStatusCompleted:
                 {
                     dispatch_async(dispatch_get_main_queue(), ^()
                     {
                         if (block)
                         {
                             block(savePath,nil);
                         }
                     });
                     break;
                 }
                 default:
                 {
                     dispatch_async(dispatch_get_main_queue(), ^()
                     {
                         if (block)
                         {
                             block(savePath,[exporter error]);
                         }
                     });
                     break;
                 }
             };
         }];
    });
}

//加水印
- (void)mergeVideo:(NSURL *)videoURL
         imageList:(NSArray *)imageList
         imageRect:(NSArray *)imageRect
          savePath:(NSString *)savePath
         timeScale:(int)timeScale
        renderSize:(CGSize)renderSize
        usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    
    if ([imageList count] == 0 || [imageRect count] == 0 || [imageList count] != [imageRect count])
    {
        if (block)
        {
            NSError *error = [NSError errorWithDomain:@"QVMVFoundation" code:1000 userInfo:nil];
            block(nil,error);
        }
    }
    
    dispatch_async(dispatch_get_current_queue(), ^()
    {
        AVMutableComposition *saveComposition = [AVMutableComposition composition];
        
        //视频轨道
        AVAsset *sourceAsset = [AVAsset assetWithURL:videoURL];

        AVMutableCompositionTrack *compositionVideoTrack = [saveComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAssetTrack *videoTrack = nil;
        if ([[sourceAsset tracksWithMediaType:AVMediaTypeVideo] count])
        {
            videoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, sourceAsset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
        }
        
        //音频轨道

        if ([[sourceAsset tracksWithMediaType:AVMediaTypeAudio] count])
        {
            AVAssetTrack *audioTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            AVMutableCompositionTrack *compositionAudioTrack = [saveComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, sourceAsset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
        }
        
        CALayer *parentLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
        
        CALayer *videoLayer = [CALayer layer];
        videoLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
        [parentLayer addSublayer:videoLayer];

        for (UIImage *image in imageList)
        {
            NSUInteger index = [imageList indexOfObject:image];
            CGRect rect = [[imageRect objectAtIndex:index] CGRectValue];
            
            CALayer *imageLayer = [CALayer layer];
            imageLayer.frame = rect;
            imageLayer.contents = (id)image.CGImage;
            [parentLayer addSublayer:imageLayer];
        }

        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        [layerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        [instruction setTimeRange:CMTimeRangeMake(kCMTimeZero, sourceAsset.duration)];
        instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.renderSize = renderSize;
        videoComposition.renderScale = 1.0;
        videoComposition.frameDuration = CMTimeMake(1, timeScale);
        videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
        videoComposition.instructions = [NSArray arrayWithObject:instruction];
        
        
        if([[NSFileManager defaultManager] fileExistsAtPath:savePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];
        }
        
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:saveComposition presetName:AVAssetExportPresetHighestQuality];
        
        [exporter setVideoComposition:videoComposition];
        [exporter setOutputURL:[NSURL fileURLWithPath:savePath]];
        [exporter setOutputFileType:AVFileTypeQuickTimeMovie];
        //[exporter setOutputFileType:AVFileTypeMPEG4];
        [exporter exportAsynchronouslyWithCompletionHandler:^(void)
        {
            switch (exporter.status)
            {
                case AVAssetExportSessionStatusFailed:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                        if (block)
                        {
                            block(savePath,[exporter error]);
                        }
                    });
                    break;
                }
                case AVAssetExportSessionStatusCompleted:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                        if (block)
                        {
                            block(savePath,nil);
                        }
                    });
                    break;
                }
                default:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                        if (block)
                        {
                            block(savePath,[exporter error]);
                        }
                    });
                    break;
                }
            }
        }];
    });
}


- (void)mergeVideoList:(NSArray *)videoList
             audioList:(NSArray *)audioList
              savePath:(NSString *)savePath
             timeScale:(int)timeScale
            renderSize:(CGSize)renderSize
            usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    if (![videoList count] || ![audioList count] || [videoList count] != [audioList count])
    {
        NSError *error = [NSError errorWithDomain:@"QVMVFoundation" code:1001 userInfo:nil];
        block(savePath,error);
        return ;
    }
    
    if ([videoList count] == 1) //只有一个视频
    {
        
        [self mergeVideo:[videoList objectAtIndex:0] audio:[audioList objectAtIndex:0] savePath:savePath replace:YES usingBlock:^(NSString *path, NSError *error)
        {
             if (block)
             {
                 block(path,error);
             }
        }];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^()
    {
       //多视频合成
       
       AVMutableComposition *saveComposition = [AVMutableComposition composition];
       
       NSMutableArray *instructionList = [[NSMutableArray alloc] init];
       
       CMTime totalDuration = kCMTimeZero;
       CMTime start = CMTimeMake(kKeyFrameOffset, timeScale);
       
       for (int i = 0; i < [videoList count]; i++)
       {
           //视频合成
           NSURL *assetURL = [videoList objectAtIndex:i];
           AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
           AVAssetTrack *sourceVideoTrack = nil;
           CMTime duration = CMTimeSubtract(sourceAsset.duration, start);
           
           if ([[sourceAsset tracksWithMediaType:AVMediaTypeVideo] count])
           {
               sourceVideoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
           }
           AVMutableCompositionTrack *compositionVideoTrack = [saveComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
           
           [compositionVideoTrack insertTimeRange:CMTimeRangeMake(start, duration) ofTrack:sourceVideoTrack atTime:totalDuration error:nil];
           
           AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
           
           [layerInstruction setTransform:sourceVideoTrack.preferredTransform atTime:totalDuration];
           
           [instructionList addObject:layerInstruction];
           
           
           //音频合成
           NSURL *audioURL = [audioList objectAtIndex:i];
           AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:audioURL options:nil];
           
           AVAssetTrack *sourceAudioTrack = nil;
           
           if ([[audioAsset tracksWithMediaType:AVMediaTypeAudio] count])
           {
               sourceAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
           }
           
           AVMutableCompositionTrack *compositionAudioTrack = [saveComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
           
           [compositionAudioTrack insertTimeRange:CMTimeRangeMake(start, duration) ofTrack:sourceAudioTrack atTime:totalDuration error:nil];
           
           totalDuration = CMTimeAdd(totalDuration, duration);
           
           [layerInstruction setOpacity:0.0 atTime:totalDuration];
           
           //Log
           NSLog(@"\n source asset duration is %f \n source vid track timerange is %f %f \n composition duration is %f \n composition vid track time range is %f %f",
                 CMTimeGetSeconds([sourceAsset duration]),
                 CMTimeGetSeconds(sourceVideoTrack.timeRange.start),
                 CMTimeGetSeconds(sourceVideoTrack.timeRange.duration),
                 CMTimeGetSeconds([saveComposition duration]),
                 CMTimeGetSeconds(compositionVideoTrack.timeRange.start),
                 CMTimeGetSeconds(compositionVideoTrack.timeRange.duration));
       }
       
       AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
       videoComposition.frameDuration = CMTimeMake(1,timeScale);
       videoComposition.renderScale = 1.0;
       videoComposition.renderSize = renderSize;
       
       AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
       instruction.layerInstructions = instructionList;
       instruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
       videoComposition.instructions = [NSArray arrayWithObject:instruction];
       
       if([[NSFileManager defaultManager] fileExistsAtPath:savePath])
       {
           [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];
       }
       
       NSURL *url = [[NSURL alloc] initFileURLWithPath:savePath];
       
       AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:saveComposition presetName:AVAssetExportPresetHighestQuality];
       exporter.videoComposition = videoComposition;
       exporter.outputURL = url;
       exporter.outputFileType = AVFileTypeQuickTimeMovie;
       [exporter exportAsynchronouslyWithCompletionHandler:^
        {
            switch (exporter.status)
            {
                case AVAssetExportSessionStatusFailed:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                        if (block)
                        {
                            block(savePath,[exporter error]);
                        }
                    });
                    break;
                }
                case AVAssetExportSessionStatusCompleted:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                       if (block)
                       {
                           block(savePath,nil);
                       }
                    });
                    break;
                }
                default:
                {
                    dispatch_async(dispatch_get_main_queue(), ^()
                    {
                       if (block)
                       {
                           block(savePath,[exporter error]);
                       }
                    });
                    break;
                }
            }
        }];
    });
}


@end

