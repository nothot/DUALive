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

__weak static DUAAVCaptureManager *weekAVCaptureManager;
void rtmp_state_changed_callback (aw_rtmp_state state_from, aw_rtmp_state state_to)
{
    NSLog(@"rtmp state changed from(%s), to(%s)", aw_rtmp_state_description(state_from), aw_rtmp_state_description(state_to));
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weekAVCaptureManager.stateDelegate) {
            [weekAVCaptureManager.stateDelegate rtmpStateChangedFrom:state_from To:state_to];
        }
    });
}

@interface DUAAVCaptureManager () <DUAVideoCaptureDelegate, DUAAudioCaptureDelegate>

@property (nonatomic, strong) DUAVideoCapture *videoCapture;
@property (nonatomic, strong) DUAAudioCapture *audioCapture;
@property (nonatomic, strong) AWEncoderManager *encoderManager;
@property (nonatomic, strong) dispatch_queue_t encodeBufferQueue;
@property (nonatomic, strong) dispatch_queue_t sendBufferQueue;

@end
@implementation DUAAVCaptureManager

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"please call initWithVideoConfig:AudioConfig:RtmpUrl to init" reason:nil userInfo:nil];
}

- (instancetype)initWithVideoConfig:(AWVideoConfig *)videoConfig
                        AudioConfig:(AWAudioConfig *)audioConfig
                            RtmpUrl:(NSString *)rtmpUrl
{
    if (self = [super init]) {
        self.videoCapture = [[DUAVideoCapture alloc] init];
        self.audioCapture = [[DUAAudioCapture alloc] init];
        self.videoCapture.delegate = self;
        self.audioCapture.delegate = self;
        self.encodeBufferQueue = dispatch_queue_create("dua.encode.buffer.queue", NULL);
        self.sendBufferQueue = dispatch_queue_create("dua.send.buffer.queue", NULL);
        weekAVCaptureManager = self;
        
        self.videoConfig = videoConfig;
        self.audioConfig = audioConfig;
        self.encoderManager = [[AWEncoderManager alloc] init];
        self.encoderManager.videoEncoderType = AWVideoEncoderTypeHWH264;
        self.encoderManager.audioEncoderType = AWAudioEncoderTypeHWAACLC;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8) {
            self.encoderManager.videoEncoderType = AWVideoEncoderTypeSWX264;
            self.encoderManager.audioEncoderType = AWAudioEncoderTypeSWFAAC;
        }
        
        self.rtmpUrl = rtmpUrl;
    }
    
    return self;
}

- (void)startLive
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [self.encoderManager openWithAudioConfig:self.audioConfig videoConfig:self.videoConfig];
        int isSuccess = aw_streamer_open(self.rtmpUrl.UTF8String, rtmp_state_changed_callback);
        if (isSuccess) {
            [self.videoCapture startVideoCapture];
            [self.audioCapture startAudioCapture];
        }
    });
    
}

- (void)stopLive
{
    [self.videoCapture stopVideoCapture];
    [self.audioCapture stopAudioCapture];
    dispatch_sync(self.sendBufferQueue, ^{
        aw_streamer_close();
    });
    dispatch_sync(self.encodeBufferQueue, ^{
        [self.encoderManager close];
    });
}

#pragma mark -- DUAVideoCaptureDelegate and DUAAudioCaptureDelegate

- (void)videoCaptureOutput:(CVPixelBufferRef)pixcelBuffer
{
    NSLog(@"===> test video");
}

- (void)audioCaptureOutput:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"===> test audio");
}

@end
