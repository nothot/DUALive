//
//  DUAAVCaptureManager.h
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFLiveAudioConfiguration.h"
#import "LFLiveVideoConfiguration.h"
#import "LFStreamSocket.h"


@class DUALiveManager;
@protocol DUALiveDelegate <NSObject>

@optional
- (void)liveManager:(DUALiveManager *)manager liveState:(LFLiveState)state;
- (void)liveManager:(DUALiveManager *)manager liveErrorCode:(LFLiveSocketErrorCode)errorCode;
- (void)liveManager:(DUALiveManager *)manager liveDebugInfo:(LFLiveDebug *)debugInfo;

@end

@interface DUALiveManager : NSObject

@property (nonatomic, weak) id<DUALiveDelegate> liveDelegate;

- (instancetype)initWithAudioConfiguration:(LFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(LFLiveVideoConfiguration *)videoConfiguration rmptUrl:(NSString *)urlString;
- (void)startLive;
- (void)stopLive;

@end
