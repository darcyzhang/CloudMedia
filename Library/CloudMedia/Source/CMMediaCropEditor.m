//
//  CMMediaCropEditor.m
//  CloudMedia
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import "CMMediaCropEditor.h"
#import <AVFoundation/AVFoundation.h>

@implementation CMMediaCropEditor

- (void)cutVideo:(NSString *)videoPath
        savePath:(NSString *)savePath
    startSeconds:(double)startSeconds
        duration:(double)duration
       timeScale:(int)timeScale
      renderSize:(CGSize)renderSize
      usingBlock:(void(^)(NSString *savePath, NSError *error))block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^()
    {
        AVMutableComposition *saveComposition = [AVMutableComposition composition];
        
        AVMutableCompositionTrack *compositionVideoTrack = [saveComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        //设置裁剪的时间区域
        AVAsset *sourceAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
        AVAssetTrack *sourceVideoTrack = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        NSError *error = nil;
        CMTimeRange range = CMTimeRangeMake(CMTimeMakeWithSeconds(startSeconds, timeScale), CMTimeMakeWithSeconds(duration, timeScale));
        
        [compositionVideoTrack insertTimeRange:range ofTrack:sourceVideoTrack atTime:kCMTimeZero error:&error];
        
        
        //设置视频的开始、播放时间和视频层
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        [instruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [saveComposition duration])];
        
        //设置默认视频层的方向和开始时间
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        
        [layerInstruction setTransform:sourceVideoTrack.preferredTransform atTime:kCMTimeZero];
        
        instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition] ;
        
        videoComposition.renderSize = renderSize;
        videoComposition.frameDuration = CMTimeMake(1, timeScale);
        videoComposition.instructions = [NSArray arrayWithObject:instruction];
        
        
        if([[NSFileManager defaultManager] fileExistsAtPath:savePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:savePath error:nil];
        }
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:saveComposition presetName:AVAssetExportPresetHighestQuality];
        
        //[exporter setVideoComposition:videoComposition];
        
        [exporter setOutputURL:[NSURL fileURLWithPath:savePath]];
        [exporter setOutputFileType:AVFileTypeQuickTimeMovie];
        //[exporter setOutputFileType:AVFileTypeMPEG4];
        [exporter setShouldOptimizeForNetworkUse:YES];
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

@end
