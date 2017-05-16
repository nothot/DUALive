//
//  DUAVideoCapture.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "DUAVideoCapture.h"
#import <AVFoundation/AVFoundation.h>
#import "DUAQueue.h"

static const int frameRate = 20;
static const int fetchFrame = 10;

@interface DUAVideoCapture ()

@property (nonatomic, strong) dispatch_source_t timerInput;
@property (nonatomic, strong) dispatch_source_t timerOutput;

@property (nonatomic, strong) DUAQueue *framePool;
@property (nonatomic, strong) dispatch_queue_t screenShotQueue;
@property (nonatomic, strong) dispatch_queue_t fetchFrameQueue;
@property (nonatomic, assign) BOOL framePoolCapabilityWarning;

@end
@implementation DUAVideoCapture


- (instancetype)init
{
    if (self = [super init]) {
        self.framePool = [[DUAQueue alloc] init];
        self.screenShotQueue = dispatch_queue_create("dua.screenshot.queue", NULL);
        self.fetchFrameQueue = dispatch_queue_create("dua.fetchframe.queue", NULL);
    
        self.timerInput = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.screenShotQueue);
        dispatch_source_set_timer(self.timerInput, DISPATCH_TIME_NOW, 1.0/frameRate * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.timerInput, ^{
            [self executeScreenShot];
        });
        
        self.timerOutput = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.fetchFrameQueue);
        dispatch_source_set_timer(self.timerOutput, DISPATCH_TIME_NOW, 1.0/fetchFrame * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.timerOutput, ^{
            [self executeFetchFrame];
        });
    }
    
    return self;
}

- (void)setIsRunning:(BOOL)isRunning
{
    _isRunning = isRunning;
    
    if (_isRunning) {
        dispatch_resume(self.timerInput);
        
        dispatch_resume(self.timerOutput);
    }else {
        dispatch_sync(self.screenShotQueue, ^{
            dispatch_source_cancel(self.timerInput);
            self.timerInput = nil;
        });

        dispatch_sync(self.fetchFrameQueue, ^{
            dispatch_source_cancel(self.timerOutput);
            self.timerOutput = nil;
        });
    }
}


#pragma mark -- private logic
- (void)executeScreenShot
{
    static int frameCount = 0;
    //static BOOL flag = NO;
    frameCount++;
    NSLog(@"screen shot => %d", frameCount);
    
    UIImage *image = nil;
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    if (window) {
        CGSize imageSize = window.bounds.size;
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [window.layer renderInContext:context];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    [self.framePool enQueue:image];

    NSLog(@"frame buffer queue count: %lu", (unsigned long)self.framePool.currentCount);
    
//    if (!flag) {
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
//        flag = YES;
//    }
    
    //[self executeFetchFrame];
}

- (void)executeFetchFrame
{
    @autoreleasepool {
        if (self.framePool.currentCount >= 100 || self.framePoolCapabilityWarning) {
            [self.framePool deQueue];
            self.framePoolCapabilityWarning?(self.framePoolCapabilityWarning = NO):(self.framePoolCapabilityWarning = YES);
        }
        if (self.framePool.currentCount <= 80) {
            self.framePoolCapabilityWarning = NO;
        }
        
        if (!self.framePoolCapabilityWarning) {
            UIImage *object = [self.framePool deQueue];
            if (object) {
                CGImageRef objectImage = object.CGImage;
                CVPixelBufferRef pixcelBuffer = [self pixcelBufferFromCGImage:objectImage];
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoCaptureOutput:)]) {
                    [self.delegate videoCaptureOutput:pixcelBuffer];
                }
                CVPixelBufferRelease(pixcelBuffer);
            }
        }
    }
}

- (CVPixelBufferRef)pixcelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,frameWidth,frameHeight,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameWidth, frameHeight, 8,CVPixelBufferGetBytesPerRow(pxbuffer),rgbColorSpace,(CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0,frameWidth,frameHeight),  image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (CMSampleBufferRef)sampleBufferFromCGImage:(CGImageRef)image
{
    CVPixelBufferRef pixelBuffer = [self pixcelBufferFromCGImage:image];
    CMSampleBufferRef newSampleBuffer = NULL;
    CMSampleTimingInfo timimgInfo = kCMTimingInfoInvalid;
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(
                                                 NULL, pixelBuffer, &videoInfo);
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                       pixelBuffer,
                                       true,
                                       NULL,
                                       NULL,
                                       videoInfo,
                                       &timimgInfo,
                                       &newSampleBuffer);
    
    return newSampleBuffer;
}

@end
