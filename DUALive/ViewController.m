//
//  ViewController.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "ViewController.h"
#import "DUALiveManager.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *colorArray;
@property (nonatomic, strong) DUALiveManager *liveManager;
@property (nonatomic, strong) FBSDKLoginManager *fbLoginManager;

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
//    [self startFacebookLiveWithRTMPUrl:^(NSString *url) {
//        NSLog(@"facebook rtmp url: %@", url);
//        if (!url) {
//            NSLog(@"url is null");
//            return;
//        }
//        //url = @"rtmp://ossrs.net/live/123456";
//        //url = @"rtmp://live.hkstv.hk.lxdns.com:1935/live/stream153";
//        
//        LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
//        videoConfiguration.videoSize = CGSizeMake(540, 960);
//        videoConfiguration.videoBitRate = 800*1024;
//        videoConfiguration.videoMaxBitRate = 1000*1024;
//        videoConfiguration.videoMinBitRate = 500*1024;
//        videoConfiguration.videoFrameRate = 20;
//        videoConfiguration.videoMaxKeyframeInterval = 40;
//        videoConfiguration.outputImageOrientation = UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
//        videoConfiguration.autorotate = NO;
//        //videoConfiguration.sessionPreset = LFCaptureSessionPreset720x1280;
//        
//        LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
//        audioConfiguration.numberOfChannels = 1;
//        audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_48000Hz;
//        audioConfiguration.audioBitrate = LFLiveAudioBitRate_128Kbps;
//        
//        self.liveManager = [[DUALiveManager alloc] initWithAudioConfiguration:audioConfiguration
//                                                           videoConfiguration:videoConfiguration
//                                                                      rmptUrl:url
//                            ];
//        [self.liveManager startLive];
//
//    }];
    
    NSString *url = @"rtmp://ossrs.net/live/123456";
    
    LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
    videoConfiguration.videoSize = CGSizeMake(540, 960);
    videoConfiguration.videoBitRate = 800*1024;
    videoConfiguration.videoMaxBitRate = 1000*1024;
    videoConfiguration.videoMinBitRate = 500*1024;
    videoConfiguration.videoFrameRate = 20;
    videoConfiguration.videoMaxKeyframeInterval = 40;
    videoConfiguration.outputImageOrientation = UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
    videoConfiguration.autorotate = NO;
    //videoConfiguration.sessionPreset = LFCaptureSessionPreset720x1280;
    
    LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
    audioConfiguration.numberOfChannels = 1;
    audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_48000Hz;
    audioConfiguration.audioBitrate = LFLiveAudioBitRate_128Kbps;
    
    self.liveManager = [[DUALiveManager alloc] initWithAudioConfiguration:audioConfiguration
                                                       videoConfiguration:videoConfiguration
                                                                  rmptUrl:url
                        ];
    [self.liveManager startLive];


}

- (IBAction)onStopClick:(id)sender
{
    [self.liveManager stopLive];
    
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

- (void)startFacebookLiveWithRTMPUrl:(void (^)(NSString *))callback
{
    if (!self.fbLoginManager) {
        self.fbLoginManager = [FBSDKLoginManager new];
    }
    [self.fbLoginManager logOut];
    self.fbLoginManager.loginBehavior = FBSDKLoginBehaviorNative;
    [self.fbLoginManager logInWithPublishPermissions:@[@"publish_actions", @"manage_pages"]
                                  fromViewController:nil
                                             handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
        NSLog(@"facebook auth failed");
        }else if (result.isCancelled) {
            NSLog(@"facebook auth canceled");
        }else {
            FBSDKGraphRequest *UserIDRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                                 parameters:@{@"fields": @"id, name"}
                                                                                 HTTPMethod:@"GET"];
            [UserIDRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id requestResult, NSError *requestError) {
                if (requestError) {
                    NSLog(@"request fb user id failed");
                }else {
                    NSDictionary *userInfo = (NSDictionary *)requestResult;
                    NSLog(@"facebook user info: %@", userInfo);
                    NSString *userId = userInfo[@"id"];
                    NSDictionary *param = @{//@"content_tags":@"12",
                                            @"description":@"this is a live.",
                                            @"status":@"LIVE_NOW",
                                            //@"is_spherical":@NO,
                                            @"title":@"live life"
                                            };
                    FBSDKGraphRequest *liveRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/live_videos", userId]
                                                                                       parameters:param
                                                                                       HTTPMethod:@"POST"];
                    [liveRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *liveConnection, id liveRequest, NSError *liveError) {
                        NSDictionary *streamInfo = (NSDictionary *)liveRequest;
                        NSLog(@"facebook live info: %@", streamInfo);
                        NSString *rtmpUrl = streamInfo[@"stream_url"];
                        callback(rtmpUrl);
                    }];
                }
            }];
        }
    }];
    
}


@end
