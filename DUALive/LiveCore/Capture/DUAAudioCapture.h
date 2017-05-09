//
//  DUAAudioCapture.h
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol DUAAudioCaptureDelegate <NSObject>
@required
- (void)audioCaptureOutput:(CMSampleBufferRef)sampleBuffer;

@end
@interface DUAAudioCapture : NSObject

@property (nonatomic, weak) id<DUAAudioCaptureDelegate> delegate;
@property (nonatomic, assign) BOOL isRunning;

//- (void)startAudioCapture;
//- (void)stopAudioCapture;

@end
