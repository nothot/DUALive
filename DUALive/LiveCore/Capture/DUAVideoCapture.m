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

@interface DUAVideoCapture ()

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, strong) DUAQueue *frameBufferQueue;
@property (nonatomic, strong) dispatch_queue_t screenshotQueue;
@property (nonatomic, strong) dispatch_queue_t fetchFrameQueue;


@end
@implementation DUAVideoCapture


- (instancetype)init
{
    if (self = [super init]) {
        self.frameBufferQueue = [[DUAQueue alloc] init];
        self.screenshotQueue = dispatch_queue_create("dua.screenshot.queue", NULL);
        self.fetchFrameQueue = dispatch_queue_create("dua.fetchframe.queue", NULL);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.screenshotQueue);
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1.0/frameRate * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.timer, ^{
            [self fetchScreenshot];
        });
    }
    
    return self;
}

- (void)setIsRunning:(BOOL)isRunning
{
    _isRunning = isRunning;
    
    if (_isRunning) {
        dispatch_resume(self.timer);
        
        dispatch_async(self.fetchFrameQueue, ^ {
            while (self.timer || (!self.timer && [self.frameBufferQueue deQueue])) {
                @autoreleasepool {
                    UIImage *object = [self.frameBufferQueue deQueue];
                    if (object) {
                        CGImageRef objectImage = object.CGImage;
                        CVPixelBufferRef pixcelBuffer = [self pixcelBufferFromCGImage:objectImage];
                        if (self.delegate) {
                            [self.delegate videoCaptureOutput:pixcelBuffer];
                        }
                        CVPixelBufferRelease(pixcelBuffer);
                    }
                }
            }
        });
        
    }else {
        dispatch_sync(self.screenshotQueue, ^{
            dispatch_source_cancel(self.timer);
            self.timer = nil;
        });

    }
}

//- (void)startVideoCapture
//{
//    dispatch_queue_t screenshotQueue = dispatch_queue_create("dua.screenshot.queue", NULL);
//    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, screenshotQueue);
//    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0/frameRate * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
//    dispatch_source_set_event_handler(timer, ^{
//        [self fetchScreenshot];
//    });
//    dispatch_resume(timer);
//    
//    dispatch_queue_t fetchQueue = dispatch_queue_create("dua.fetchframe.queue", NULL);;
//    dispatch_async(fetchQueue, ^ {
//        while (timer || (!timer && [self.frameQueue deQueue])) {
//            @autoreleasepool {
//                UIImage *object = [self.frameQueue deQueue];
//                if (object) {
//                    CGImageRef objectImage = object.CGImage;
//                    CVPixelBufferRef pixcelBuffer = [self pixcelBufferFromCGImage:objectImage];
//                    if (self.delegate) {
//                        [self.delegate videoCaptureOutput:pixcelBuffer];
//                    }
//                    CVPixelBufferRelease(pixcelBuffer);
//                }
//            }
//        }
//    });
//}
//
//- (void)stopVideoCapture
//{
//    if (timer) {
//        dispatch_source_cancel(timer);
//        timer = nil;
//    }
//}


#pragma mark -- private logic
- (void)fetchScreenshot
{
    static int frameCount = 0;
    frameCount++;
    
    UIImage *image = nil;
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    if (window) {
        CGSize imageSize = window.bounds.size;
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [window.layer renderInContext:context];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    NSLog(@"===> fetch frame %d", frameCount);
    [self.frameBufferQueue enQueue:image];

//    UIImage *object = [self.frameQueue deQueue];
//    if (object) {
//        CGImageRef objectImage = image.CGImage;
//        CVPixelBufferRef pixcelBuffer = [self pixcelBufferFromCGImage:objectImage];
//        if (self.delegate) {
//            [self.delegate videoCaptureOutput:pixcelBuffer];
//        }
//        CVPixelBufferRelease(pixcelBuffer);
//    }
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
