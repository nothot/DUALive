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
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES2/gl.h>


static const int frameRate = 20;

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
    
        self.timerInput = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(self.timerInput, DISPATCH_TIME_NOW, 1.0/frameRate * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.timerInput, ^{
            [self executeScreenShot];
        });
        
        self.timerOutput = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.fetchFrameQueue);
        dispatch_source_set_timer(self.timerOutput, DISPATCH_TIME_NOW, 1.0/frameRate * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
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
        
        //dispatch_resume(self.timerOutput);
    }else {
        if (!self.timerInput || !self.timerOutput) {
            return;
        }
        dispatch_sync(self.screenShotQueue, ^{
            dispatch_source_cancel(self.timerInput);
            self.timerInput = nil;
        });

//        dispatch_sync(self.fetchFrameQueue, ^{
//            dispatch_source_cancel(self.timerOutput);
//            self.timerOutput = nil;
//        });
    }
}


#pragma mark -- private logic
- (void)executeScreenShot
{
    static int frameCount = 0;
    static BOOL flag = NO;
    frameCount++;
    NSLog(@"screen shot: => %d", frameCount);
    
    UIImage *image = nil;
    UIWindow *window = [[UIApplication sharedApplication].delegate window];

    image = [self coreGraphicsScreenShot:window];
//    image = [self openGLScreenShot:window];
    
    if (!flag) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        flag = YES;
    }
    
//    [self.framePool enQueue:image];
//    test
//    UIImage *object = [self.framePool deQueue];
//    if (object) {
//        CGImageRef objectImage = object.CGImage;
//        CVPixelBufferRef pixcelBuffer = [self pixcelBufferFromCGImage:objectImage];
//        if (self.delegate && [self.delegate respondsToSelector:@selector(videoCaptureOutput:)]) {
//            [self.delegate videoCaptureOutput:pixcelBuffer];
//        }
//        CVPixelBufferRelease(pixcelBuffer);
//    }
//    
//    NSLog(@"frame buffer queue count: %lu", (unsigned long)self.framePool.currentCount);
    
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

- (UIImage*)openGLScreenShot:(UIView*)eaglview
{
//    GLint backingWidth, backingHeight;
//
//    // Bind the color renderbuffer used to render the OpenGL ES view
//    // If your application only creates a single color renderbuffer which is already bound at this point,
//    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
//    // Note, replace "_colorRenderbuffer" with the actual name of the renderbuffer object defined in your class.
//    GLuint viewRenderBuffer;
//    glGenRenderbuffersOES(1, &viewRenderBuffer);
//    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderBuffer);
//    
//    // Get the size of the backing CAEAGLLayer
//    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
//    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    
    int width0 = viewport[2];
    int height0 = viewport[3];
    
//    NSInteger x = 0, y = 0, width = eaglview.frame.size.width, height = eaglview.frame.size.height;
////    NSInteger x = 0, y = 0, width = backingWidth, height = backingHeight;
    NSInteger x = 0, y = 0, width = width0, height = height0;

    NSLog(@"========== width: %ld, height: %ld", (long)width, (long)height);
    NSInteger dataLength = width * height * 4;
    
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    // Read pixel data from the framebuffer
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    
    // Create a CGImage with the pixel data
    
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    
    // otherwise, use kCGImageAlphaPremultipliedLast
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    
    // OpenGL ES measures data in PIXELS
    
    // Create a graphics context with the target size measured in POINTS
    
    NSInteger widthInPoints, heightInPoints;
    

    CGFloat scale = eaglview.contentScaleFactor;
    NSLog(@"==== scale: %f", scale);
    widthInPoints = width / scale;
    
    heightInPoints = height / scale;
        
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    
    // Flip the CGImage by rendering it to the flipped bitmap context
    
    // The size of the destination area is measured in POINTS
    
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    
    
    // Retrieve the UIImage from the current context
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"opengl: %@", image);
    
    
    UIGraphicsEndImageContext();
    
    // Clean up
    
    free(data);
    
    CFRelease(ref);
    
    CFRelease(colorspace);
    
    CGImageRelease(iref);
    
    return image;
}

- (UIImage *)coreGraphicsScreenShot:(UIView *)view
{
    UIImage *image = nil;
    if (view) {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 0.9);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [view.layer renderInContext:context];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

@end
