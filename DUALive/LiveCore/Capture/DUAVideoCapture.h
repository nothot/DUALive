//
//  DUAVideoCapture.h
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DUAVideoCaptureDelegate <NSObject>
@required
- (void)videoCaptureOutput:(CVPixelBufferRef)pixcelBuffer;

@end
@interface DUAVideoCapture : NSObject

@property (nonatomic, weak) id<DUAVideoCaptureDelegate> delegate;
@property (nonatomic, assign) BOOL isRunning;

//- (void)startVideoCapture;
//- (void)stopVideoCapture;

//144P  （192×144，20帧/秒），4：3，录制一分钟大约1MB；
//240p（320×240，20帧/秒），4：3，录制一分钟大约3MB；
//360P （480×360，20帧/秒） ，4：3，录制一分钟大约7MB；
//480P （640×480，20帧/秒），4：3，录制一分钟大约12MB；
//720P （1280×720，30帧/秒）  ， 16:9，录制一分钟大约35MB；
//1080P （1920×1080，30帧/秒） ，16:9 ， 录制一分钟大约80MB。

@end
