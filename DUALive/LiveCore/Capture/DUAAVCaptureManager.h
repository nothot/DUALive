//
//  DUAAVCaptureManager.h
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWAVConfig.h"
#import "AWEncoderManager.h"
#import "aw_all.h"

@protocol DUARtmpStateChangedDelegate <NSObject>

- (void)rtmpStateChangedFrom:(aw_rtmp_state)stateBefore To:(aw_rtmp_state)stateAfter;

@end

@interface DUAAVCaptureManager : NSObject

@property (nonatomic, strong) AWAudioConfig *audioConfig;
@property (nonatomic, strong) AWVideoConfig *videoConfig;
@property (nonatomic, strong) AWAudioEncoder *audioEncoder;
@property (nonatomic, strong) AWVideoEncoder *videoEncoder;
@property (nonatomic, strong) NSString *rtmpUrl;
@property (nonatomic, weak) id<DUARtmpStateChangedDelegate> stateDelegate;

- (instancetype)initWithVideoConfig:(AWVideoConfig *)videoConfig AudioConfig:(AWAudioConfig *)audioConfig RtmpUrl:(NSString *)rtmpUrl;
- (void)startLive;
- (void)stopLive;

@end
