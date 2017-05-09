//
//  ViewController.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "ViewController.h"
#import "DUALiveManager.h"

#import <MediaPlayer/MediaPlayerDefines.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *colorArray;
@property (nonatomic, strong) DUALiveManager *liveManager;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.colorArray = [NSMutableArray arrayWithObjects:
                       [UIColor orangeColor],
                       [UIColor redColor],
                       [UIColor yellowColor],
                       [UIColor greenColor],
                       [UIColor purpleColor],
                       nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onStartClick:(id)sender
{
//    AWVideoConfig *videoConfig = [[AWVideoConfig alloc] init];
//    videoConfig.fps = 25;
//    AWAudioConfig *audioConfig = [[AWAudioConfig alloc] init];
//    audioConfig.sampleRate = 48000;
//    
//    //获取推流地址rtmpUrl
//    NSString *rtmpUrl = @"rtmp://rtmp-api.facebook.com:80/rtmp/423192058058423?ds=1&s_l=1&a=AThLXHWDnrVdf9Bp";
//    self.avCaptureManager = [[DUAAVCaptureManager alloc] initWithVideoConfig:videoConfig AudioConfig:audioConfig RtmpUrl:rtmpUrl];
    
    LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
    videoConfiguration.videoSize = CGSizeMake(360, 640);
    videoConfiguration.videoBitRate = 800*1024;
    videoConfiguration.videoMaxBitRate = 1000*1024;
    videoConfiguration.videoMinBitRate = 500*1024;
    videoConfiguration.videoFrameRate = 24;
    videoConfiguration.videoMaxKeyframeInterval = 48;
    videoConfiguration.outputImageOrientation = UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
    videoConfiguration.autorotate = NO;
    videoConfiguration.sessionPreset = LFCaptureSessionPreset720x1280;
    
    LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
    audioConfiguration.numberOfChannels = 1;
    audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_48000Hz;
    audioConfiguration.audioBitrate = LFLiveAudioBitRate_128Kbps;
    
    self.liveManager = [[DUALiveManager alloc] initWithAudioConfiguration:audioConfiguration
                                                                 videoConfiguration:videoConfiguration
                                                                            rmptUrl:@"rtmp://live.hkstv.hk.lxdns.com:1935/live/stream153"];
    [self.liveManager startLive];
}

- (IBAction)onStopClick:(id)sender
{
    [self.liveManager stopLive];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//        NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:@"IOSCamDemoX.h264"];
//        
//        [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:writablePath]
//                                    completionBlock:^(NSURL *assetURL, NSError *error) {
//                                        if (error) {
//                                            NSLog(@"Save video failed:%@",error);
//                                        } else {
//                                            NSLog(@"Save video succeed.");
//                                        }
//                                    }];
//    });
    
}

- (IBAction)onColorClick:(id)sender
{
    static int i = 0;
    self.view.backgroundColor = (UIColor *)[self.colorArray objectAtIndex:i];
    i++;
    if (i == self.colorArray.count) {
        i = 0;
    }
}


@end
