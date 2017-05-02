//
//  DUAAVCaptureManager.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "DUAAVCaptureManager.h"
#import "DUAVideoCapture.h"
#import "DUAAudioCapture.h"

@interface DUAAVCaptureManager () <DUAVideoCaptureDelegate, DUAAudioCaptureDelegate>

@property (nonatomic, strong) DUAVideoCapture *videoCapture;
@property (nonatomic, strong) DUAAudioCapture *audioCapture;

@end
@implementation DUAAVCaptureManager

- (void)startLive
{
    self.videoCapture.delegate = self;
    self.audioCapture.delegate = self;
    [self.videoCapture startVideoCapture];
    [self.audioCapture startAudioCapture];
}

- (void)stopLive
{
    //[self.videoCapture stopVideoCapture];
    [self.audioCapture stopAudioCapture];
}

#pragma mark -- DUAVideoCaptureDelegate and DUAAudioCaptureDelegate

- (void)videoCaptureOutput:(CVPixelBufferRef)pixcelBuffer
{
    
}

- (void)audioCaptureOutput:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"===> test2333");
}

@end
