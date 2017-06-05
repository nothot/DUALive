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

/// 流状态
typedef NS_ENUM (NSUInteger, DUALiveState){
    /// 准备
    DUALiveReady = 0,
    /// 连接中
    DUALivePending = 1,
    /// 已连接
    DUALiveStart = 2,
    /// 已断开
    DUALiveStop = 3,
    /// 连接出错
    DUALiveError = 4,
    ///  正在刷新
    DUALiveRefresh = 5
};

typedef NS_ENUM (NSUInteger, DUALiveSocketErrorCode) {
    DUALiveSocketError_PreView = 201,              ///< 预览失败
    DUALiveSocketError_GetStreamInfo = 202,        ///< 获取流媒体信息失败
    DUALiveSocketError_ConnectSocket = 203,        ///< 连接socket失败
    DUALiveSocketError_Verification = 204,         ///< 验证服务器失败
    DUALiveSocketError_ReConnectTimeOut = 205      ///< 重新连接服务器超时
};

typedef NS_ENUM (NSUInteger, DUALiveCaptureType) {
    DUALiveInputAudio   = 1 << 0,
    DUALiveInputVideo   = 1 << 1,
    DUALiveDefaultAudio = 1 << 2,
    DUALiveDefaultVideo = 1 << 3,
    DUALiveDafaultAll   = DUALiveDefaultAudio | DUALiveDefaultVideo
};

@class DUALiveManager;
@protocol DUALiveDelegate <NSObject>

@optional
- (void)liveManager:(DUALiveManager *)manager liveState:(DUALiveState)state;
- (void)liveManager:(DUALiveManager *)manager liveErrorCode:(DUALiveSocketErrorCode)errorCode;
- (void)liveManager:(DUALiveManager *)manager liveDebugInfo:(NSString *)debugInfo;

@end

@interface DUALiveManager : NSObject

@property (nonatomic, weak) id<DUALiveDelegate> liveDelegate;

- (instancetype)initWithAudioConfiguration:(LFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(LFLiveVideoConfiguration *)videoConfiguration rmptUrl:(NSString *)urlString;
- (instancetype)initWithAudioConfiguration:(LFLiveAudioConfiguration *)audioConfiguration videoConfiguration:(LFLiveVideoConfiguration *)videoConfiguration rmptUrl:(NSString *)urlString captureType:(DUALiveCaptureType)captureType;

- (void)startLive;
- (void)stopLive;

- (void)pushAudioData:(NSData *)audioData;
- (void)pushVideoData:(CVPixelBufferRef)pixelBuffer;

@end
