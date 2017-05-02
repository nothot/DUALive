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

static const int frameRate = 25;

@interface DUAVideoCapture ()

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger frameCount;
//@property (nonatomic, strong) NSString *videoPath;
//@property (nonatomic, strong) AVAssetWriter *videoWriter;
//@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
//@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic, strong) DUAQueue *frameQueue;
@end

@implementation DUAVideoCapture

- (void)startVideoCapture
{
//    [self setupVideoWriter];
    self.frameQueue = [[DUAQueue alloc] init];

    self.timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1.0/frameRate target:self selector:@selector(fetchScreenshot) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    //dispatch_queue_t fetchFrameQueue = dispatch_queue_create("fetch.frame.queue", NULL);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
//        while (self.timer) {
//            NSLog(@"exec");
//            UIImage *object = [self.frameQueue deQueue];
//            if (object) {
//                CVPixelBufferRef pixcelBuffer = [self pixcelBufferFromCGImage:object.CGImage];
//                if (self.delegate) {
//                    [self.delegate videoCaptureOutput:pixcelBuffer];
//                }
//                CVPixelBufferRelease(pixcelBuffer);
//            }
//        }
//    });
    dispatch_queue_t fetchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(fetchQueue, ^ {
        while (self.timer) {
            NSLog(@"exec");
            UIImage *object = [self.frameQueue deQueue];
            if (object) {
                CVPixelBufferRef pixcelBuffer = [self pixcelBufferFromCGImage:object.CGImage];
                if (self.delegate) {
                    [self.delegate videoCaptureOutput:pixcelBuffer];
                }
                CVPixelBufferRelease(pixcelBuffer);
            }
        }

    });
}

- (void)stopVideoCapture:(ZYSScreenRecordStop)block
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    
//    [self.videoWriterInput markAsFinished];
//    [self.videoWriter finishWritingWithCompletionHandler:^{
//        if (block) {
//            block(self.videoPath);
//        }
//
//        
//        self.adaptor = nil;
//        self.videoWriterInput = nil;
//        self.videoWriter = nil;
//    }];

}



#pragma mark -- private method
- (void)fetchScreenshot
{
//    static NSTimeInterval duration = 0;
//    duration += 1.0/frameRate;
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
    [self.frameQueue enQueue:image];
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

- (void)test
{
//    NSDate *currentDate = [NSDate date];//获取当前时间，日期
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"YYYY/MM/dd hh:mm:ss SS"];
//    NSString *dateString = [dateFormatter stringFromDate:currentDate];
//    NSLog(@"dateString:%@",dateString);
    
//    self.frameCount++;
//    NSLog(@"Processing video frame (%zd)", self.frameCount);
//    CMTime frameTime = CMTimeMake(self.frameCount, frameRate);
//    
//    static int flag = 0;
//    flag++;
//    UIImage *iamge = [self fetchScreenshot];
//    [self.frameQueue enQueue:[NSNumber numberWithInt:flag]];
//    
//    //while (YES) {
//        id object = [self.frameQueue deQueue];
//        if (object) {
//            NSLog(@"out image from queue: %@", object);
//        }
//   // }
    
//    CGImageRef imageRef = [self fetchScreenshot].CGImage;
//    CVPixelBufferRef pixelBuffer = [self pixcelBufferFromCGImage:imageRef];
    
//    if (![self.videoWriterInput isReadyForMoreMediaData]) {
//        NSLog(@"Not ready for video data");
//    } else {
//        if (self.adaptor.assetWriterInput.readyForMoreMediaData) {
//            NSLog(@"Processing video frame (%zd)", self.frameCount);
//            
//            if(![self.adaptor appendPixelBuffer:pixelBuffer withPresentationTime:frameTime]){
//                NSError *error = self.videoWriter.error;
//                if(error) {
//                    NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
//                }
//            }
//            CVPixelBufferRelease(pixelBuffer);
//        } else {
//            printf("adaptor not ready %zd\n", self.frameCount);
//        }
//        NSLog(@"**************************************************");
//    }

    
//    CVPixelBufferRelease(pixelBuffer);
}

//- (void)videoWriteInFile:(CVPixelBufferRef)pixcelBuffer
//{
//    NSString *fileUrl = [NSHomeDirectory() stringByAppendingString:@"/Documents/001.mov"];
//    unlink([fileUrl UTF8String]);
//    
//    NSError * err = nil;
//    AVAssetWriter *videoWriter = [[AVAssetWriter alloc]initWithURL:[NSURL fileURLWithPath:fileUrl] fileType:AVFileTypeQuickTimeMovie error:&err];
//    
//    NSParameterAssert(videoWriter);
//    
//    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
//    
//}

//- (BOOL)setupVideoWriter {
//    CGSize size = [[UIScreen mainScreen] bounds].size;
//    
//    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//    self.videoPath = [documents stringByAppendingPathComponent:@"video.mp4"];
//    
//    [[NSFileManager defaultManager] removeItemAtPath:self.videoPath error:nil];
//    
//    NSError *error;
//    
//    // Configure videoWriter
//    NSURL *fileUrl = [NSURL fileURLWithPath:self.videoPath];
//    self.videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeMPEG4 error:&error];
//    NSParameterAssert(self.videoWriter);
//    
//    // Configure videoWriterInput
//    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:size.width * size.height], AVVideoAverageBitRateKey, nil];
//    
//    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
//                                    AVVideoWidthKey: @(size.width),
//                                    AVVideoHeightKey: @(size.height),
//                                    AVVideoCompressionPropertiesKey: videoCompressionProps};
//    
//    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
//    
//    NSParameterAssert(self.videoWriterInput);
//    self.videoWriterInput.expectsMediaDataInRealTime = YES;
//    NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
//    
//    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
//    
//    // add input
//    [self.videoWriter addInput:self.videoWriterInput];
//    [self.videoWriter startWriting];
//    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
//    
//    return YES;
//}


@end
