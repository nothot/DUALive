//
//  DUAVideoCapture.h
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^ZYSScreenRecordStop)(NSString *videoPath);

@protocol DUAVideoCaptureDelegate <NSObject>

- (void)videoCaptureOutput:(CVPixelBufferRef)pixcelBuffer;

@end
@interface DUAVideoCapture : NSObject

@property (nonatomic, weak) id<DUAVideoCaptureDelegate> delegate;

- (void)startVideoCapture;
- (void)stopVideoCapture:(ZYSScreenRecordStop)block;

@end
