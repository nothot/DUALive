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
#import "LFHardwareAudioEncoder.h"
#import "LFHardwareVideoEncoder.h"

/**  时间戳 */
#define NOW (CACurrentMediaTime()*1000)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface DUAAVCaptureManager () <DUAVideoCaptureDelegate, DUAAudioCaptureDelegate, LFAudioEncodingDelegate, LFVideoEncodingDelegate>

@property (nonatomic, strong) DUAVideoCapture *videoCapture;
@property (nonatomic, strong) DUAAudioCapture *audioCapture;
/// 音频编码
@property (nonatomic, strong) id<LFAudioEncoding> audioEncoder;
/// 视频编码
@property (nonatomic, strong) id<LFVideoEncoding> videoEncoder;
/// 音频配置
@property (nonatomic, strong) LFLiveAudioConfiguration *audioConfiguration;
/// 视频配置
@property (nonatomic, strong) LFLiveVideoConfiguration *videoConfiguration;

@end
@implementation DUAAVCaptureManager

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"please call initWithVideoConfig:AudioConfig:RtmpUrl to init" reason:nil userInfo:nil];
}

- (instancetype)initWithAudioConfiguration:(LFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(LFLiveVideoConfiguration *)videoConfiguration rmptUrl:(NSString *)urlString
{
    if (self = [super init]) {
        self.audioConfiguration = audioConfiguration;
        self.videoConfiguration = videoConfiguration;
        self.videoCapture = [[DUAVideoCapture alloc] init];
        self.audioCapture = [[DUAAudioCapture alloc] init];
        self.audioEncoder = [[LFHardwareAudioEncoder alloc] initWithAudioStreamConfiguration:audioConfiguration];
        self.videoEncoder = [[LFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:videoConfiguration];
        
        self.videoCapture.delegate = self;
        self.audioCapture.delegate = self;
        [self.audioEncoder setDelegate:self];
        [self.videoEncoder setDelegate:self];
    }
    
    return self;
}

- (void)startLive
{
    
    self.videoCapture.isRunning = YES;
    [self.audioCapture startAudioCapture];
    
}

- (void)stopLive
{
    self.videoCapture.isRunning = NO;
    [self.audioCapture stopAudioCapture];
//    dispatch_sync(self.sendBufferQueue, ^{
//        aw_streamer_close();
//    });
//    dispatch_sync(self.encodeBufferQueue, ^{
//        [self.encoderManager close];
//    });
}

//- (void)sendVideoPixelBuffer:(CVPixelBufferRef)pixcelBuffer
//{
//    CFRetain(pixcelBuffer);
//    dispatch_async(self.encodeBufferQueue, ^ {
//        [self.encoderManager.videoEncoder encodePixelBufferToFlvTag:pixcelBuffer];
//        //[weakSelf sendFlvVideoTag:video_tag toSendQueue:sendQueue];
//        //
//    });
//    CFRelease(pixcelBuffer);
//}
//
//- (void)sendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer
//{
//    CFRetain(sampleBuffer);
//    dispatch_async(self.encodeBufferQueue, ^ {
//        [self.encoderManager.audioEncoder encodeAudioSampleBufToFlvTag:sampleBuffer];
//        CFRelease(sampleBuffer);
//    });
//}

#pragma mark -- DUAVideoCaptureDelegate && DUAAudioCaptureDelegate && LFAudioEncodingDelegate && LFVideoEncodingDelegate

- (void)videoCaptureOutput:(CVPixelBufferRef)pixcelBuffer
{
    NSLog(@"===> test video output");
    [self.videoEncoder encodeVideoData:pixcelBuffer timeStamp:NOW];
}

- (void)audioCaptureOutput:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"===> test audio output");
    NSData *audioData;
    
    //to do
    [self.audioEncoder encodeAudioData:audioData timeStamp:NOW];
}

- (void)audioEncoder:(nullable id<LFAudioEncoding>)encoder audioFrame:(nullable LFAudioFrame *)frame
{
    NSLog(@"===> test audio encode");
    
}

- (void)videoEncoder:(nullable id<LFVideoEncoding>)encoder videoFrame:(nullable LFVideoFrame *)frame
{
    NSLog(@"===> test video encode");
}

@end
