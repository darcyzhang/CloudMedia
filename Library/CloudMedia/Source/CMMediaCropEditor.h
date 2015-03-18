//
//  CMMediaCropEditor.h
//  CloudMedia
//
//  Created by zhangyun on 15-3-18.
//  Copyright (c) 2015年 zhangyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CMMediaCropEditor : NSObject

- (void)cutVideo:(NSString *)videoPath
        savePath:(NSString *)savePath
    startSeconds:(double)startSeconds
        duration:(double)duration
       timeScale:(int)timeScale
      renderSize:(CGSize)renderSize
      usingBlock:(void(^)(NSString *savePath, NSError *error))block;

@end
