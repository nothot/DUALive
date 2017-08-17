//
//  DUAAVCaptureManager.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "DUALiveManager.h"
#import "DUAVideoCapture.h"
#import "DUAAudioCapture.h"
#import "LFHardwareAudioEncoder.h"
#import "LFHardwareVideoEncoder.h"
#import "LFStreamRTMPSocket.h"

#define NOW (CACurrentMediaTime()*1000)

@interface DUALiveManager () <DUAVideoCaptureDelegate, DUAAudioCaptureDelegate, LFAudioEncodingDelegate, LFVideoEncodingDelegate, LFStreamSocketDelegate>
// 捕获类型
@property (nonatomic, assign) DUALiveCaptureType cType;
// 视频捕获
@property (nonatomic, strong) DUAVideoCapture *videoCapture;
// 音频捕获
@property (nonatomic, strong) DUAAudioCapture *audioCapture;
// 音频编码
@property (nonatomic, strong) id<LFAudioEncoding> audioEncoder;
// 视频编码
@property (nonatomic, strong) id<LFVideoEncoding> videoEncoder;
// 音频配置
@property (nonatomic, strong) LFLiveAudioConfiguration *audioConfiguration;
// 视频配置
@property (nonatomic, strong) LFLiveVideoConfiguration *videoConfiguration;
// 推流端
@property (nonatomic, strong) id<LFStreamSocket> streamSocket;
// 推流信息配置
@property (nonatomic, strong) LFLiveStreamInfo *streamInfo;
// 当前是否在推流
@property (nonatomic, assign) BOOL pushing;
// 时间戳锁
@property (nonatomic, strong) dispatch_semaphore_t lock;
// 相对时间戳
@property (nonatomic, assign) uint64_t relativeTimestamps;
// 音视频是否对齐
@property (nonatomic, assign) BOOL avAlignment;
// 是否捕获到音频帧
@property (nonatomic, assign) BOOL hasAudioCapture;
// 是否捕获到视频关键帧
@property (nonatomic, assign) BOOL hasKeyFrameCapture;

@end
@implementation DUALiveManager

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"please call initWithVideoConfig:AudioConfig:RtmpUrl to init" reason:nil userInfo:nil];
}

- (instancetype)initWithAudioConfiguration:(LFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(LFLiveVideoConfiguration *)videoConfiguration rmptUrl:(NSString *)urlString
{
    return [self initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration rmptUrl:urlString captureType:DUALiveDafaultAll];
}

- (instancetype)initWithAudioConfiguration:(LFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(LFLiveVideoConfiguration *)videoConfiguration rmptUrl:(NSString *)urlString captureType:(DUALiveCaptureType)captureType
{
    if (self = [super init]) {
        self.audioConfiguration = audioConfiguration;
        self.videoConfiguration = videoConfiguration;
        self.cType = captureType;
        
        if (captureType & DUALiveDefaultAudio) {
            self.audioCapture = [[DUAAudioCapture alloc] init];
            self.audioCapture.delegate = self;
        }
        if (captureType & DUALiveDefaultVideo) {
            self.videoCapture = [[DUAVideoCapture alloc] init];
            self.videoCapture.delegate = self;
        }
        
        self.audioEncoder = [[LFHardwareAudioEncoder alloc] initWithAudioStreamConfiguration:audioConfiguration];
        self.videoEncoder = [[LFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:videoConfiguration];
        
        self.streamInfo = [[LFLiveStreamInfo alloc] init];
        self.streamInfo.url = urlString;
        self.streamInfo.audioConfiguration = self.audioConfiguration;
        self.streamInfo.videoConfiguration = self.videoConfiguration;
        self.streamSocket = [[LFStreamRTMPSocket alloc] initWithStream:self.streamInfo reconnectInterval:0 reconnectCount:0];
        
        [self.audioEncoder setDelegate:self];
        [self.videoEncoder setDelegate:self];
        [self.streamSocket setDelegate:self];
        
    }
    
    return self;
}

- (void)startLive
{
    self.videoCapture.isRunning = YES;
    self.audioCapture.isRunning = YES;
    
    [self.streamSocket start];
}

- (void)stopLive
{
    [self.streamSocket stop];
    self.streamSocket = nil;
    NSLog(@"====== test");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.videoCapture.isRunning = NO;
        self.audioCapture.isRunning = NO;
    });
    

}

- (void)pushAudioData:(NSData *)audioData
{
    NSLog(@"push audio from outside...");
    if (self.cType & DUALiveInputAudio) {
        if (self.pushing) {
            [self.audioEncoder encodeAudioData:audioData timeStamp:NOW];
        }
    }
}

- (void)pushVideoData:(CVPixelBufferRef)pixelBuffer
{
    NSLog(@"push video from outside...");
    if (self.cType & DUALiveInputVideo) {
        if (self.pushing) {
            [self.videoEncoder encodeVideoData:pixelBuffer timeStamp:NOW];
        }
    }
}


- (void)pushEncodedBuffer:(LFFrame *)frame
{
    NSLog(@"push encoded buffer...");
    if (self.relativeTimestamps == 0) {
        self.relativeTimestamps = frame.timestamp;
    }
    frame.timestamp = [self caculateTimestamp:frame.timestamp];
    [self.streamSocket sendFrame:frame];
}

- (uint64_t)caculateTimestamp:(uint64_t)timestamp
{
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    uint64_t newTimestamp = timestamp - self.relativeTimestamps;
    dispatch_semaphore_signal(self.lock);
    
    return newTimestamp;
}

- (dispatch_semaphore_t)lock{
    if(!_lock){
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

- (BOOL)avAlignment
{
    if (self.hasAudioCapture && self.hasKeyFrameCapture) {
        return YES;
    }
    
    return NO;
}

#pragma mark -- DUAVideoCaptureDelegate && DUAAudioCaptureDelegate

- (void)videoCaptureOutput:(CVPixelBufferRef)pixcelBuffer
{
    if (self.pushing) {
        NSLog(@"video capture output...");
        [self.videoEncoder encodeVideoData:pixcelBuffer timeStamp:NOW];
    }
    
}

- (void)audioCaptureOutput:(CMSampleBufferRef)sampleBuffer
{
    if (self.pushing) {
        NSLog(@"audio capture output...");
        CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t length = CMBlockBufferGetDataLength(blockBufferRef);
        Byte buffer[length];
        CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
        NSData *audioData = [NSData dataWithBytes:buffer length:length];
        
        [self.audioEncoder encodeAudioData:audioData timeStamp:NOW];
    }

}


#pragma mark -- LFAudioEncodingDelegate && LFVideoEncodingDelegate

- (void)audioEncoder:(nullable id<LFAudioEncoding>)encoder audioFrame:(nullable LFAudioFrame *)frame
{
    if (self.pushing) {
        NSLog(@"audio encoding...");
        self.hasAudioCapture = YES;
        if (self.avAlignment)
            [self pushEncodedBuffer:frame];
    }
}

- (void)videoEncoder:(nullable id<LFVideoEncoding>)encoder videoFrame:(nullable LFVideoFrame *)frame
{
    if (self.pushing) {
        NSLog(@"video encoding...");
        if (frame.isKeyFrame && self.hasAudioCapture) {
            self.hasKeyFrameCapture = YES;
        }
        if (self.avAlignment)
            [self pushEncodedBuffer:frame];
    }
}

#pragma mark -- LFStreamSocketDelegate

- (void)socketStatus:(id<LFStreamSocket>)socket status:(LFLiveState)status
{
    NSLog(@"live state: %lu", (unsigned long)status);
    if (status == LFLiveStart) {
        
        if (!self.pushing) {
            self.pushing = YES;
            self.hasAudioCapture = NO;
            self.hasKeyFrameCapture = NO;
            self.avAlignment = NO;
            self.relativeTimestamps = 0;
        }
    }else if (status == LFLiveStop || status == LFLiveError) {
        self.pushing = NO;
    }

    dispatch_async(dispatch_get_main_queue(), ^ {
        if (self.liveDelegate && [self.liveDelegate respondsToSelector:@selector(liveManager:liveState:)]) {
            [self.liveDelegate liveManager:self liveState:(int)status];
        }
    });
}

- (void)socketDebug:(id<LFStreamSocket>)socket debugInfo:(LFLiveDebug *)debugInfo
{
    NSLog(@"live debug: %@", debugInfo.description);
    dispatch_async(dispatch_get_main_queue(), ^ {
        if (self.liveDelegate && [self.liveDelegate respondsToSelector:@selector(liveManager:liveDebugInfo:)]) {
            [self.liveDelegate liveManager:self liveDebugInfo:[debugInfo description]];
        }
    });
}

- (void)socketDidError:(id<LFStreamSocket>)socket errorCode:(LFLiveSocketErrorCode)errorCode
{
    NSLog(@"live error: %lu", (unsigned long)errorCode);
    dispatch_async(dispatch_get_main_queue(), ^ {
        if (self.liveDelegate && [self.liveDelegate respondsToSelector:@selector(liveManager:liveErrorCode:)]) {
            [self.liveDelegate liveManager:self liveErrorCode:(int)errorCode];
        }
    });
}

- (void)socketBufferStatus:(id<LFStreamSocket>)socket status:(LFLiveBuffferState)status
{
    
}

@end

