//
//  DUAAudioCapture.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "DUAAudioCapture.h"

@interface DUAAudioCapture () <AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutPut;

@end
@implementation DUAAudioCapture

- (void)startAudioCapture
{
    [self audioCaptureInit];
    [self.captureSession startRunning];
}

- (void)stopAudioCapture
{
    if (self.captureSession && [self.captureSession isRunning]) {
        [self.captureSession stopRunning];
    }
}

- (void)audioCaptureInit
{
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    dispatch_queue_t captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.audioDataOutPut = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutPut setSampleBufferDelegate:self queue:captureQueue];
    
    self.captureSession = [AVCaptureSession new];
    if ([self.captureSession canAddInput:self.audioInputDevice]) {
        [self.captureSession addInput:self.audioInputDevice];
    }
    if ([self.captureSession canAddOutput:self.audioDataOutPut]) {
        [self.captureSession addOutput:self.audioDataOutPut];
    }
}

#pragma mark --AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.delegate) {
        [self.delegate audioCaptureOutput:sampleBuffer];
    }
}

@end
