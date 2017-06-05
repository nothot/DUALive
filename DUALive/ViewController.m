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
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <DUALiveDelegate>

@property (nonatomic, strong) NSMutableArray *colorArray;
@property (nonatomic, strong) DUALiveManager *liveManager;
@property (nonatomic, strong) FBSDKLoginManager *fbLoginManager;
@property (nonatomic, strong) NSString *fbrtmpUrl;

@end

@implementation ViewController
NSString *userId;
NSString *liveVideoId;

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor orangeColor];
    self.colorArray = [NSMutableArray arrayWithObjects:
                       [UIColor orangeColor],
                       [UIColor redColor],
                       [UIColor yellowColor],
                       [UIColor greenColor],
                       [UIColor purpleColor],
                       nil];
    [self requestAccessForAudio];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onStartClick:(id)sender
{
    self.fbrtmpUrl = @"rtmp://ossrs.net/live/123456";
    if (self.fbrtmpUrl) {
        [self startFacebookLive:self.fbrtmpUrl];
    }else
    {
        [self startFacebookLiveWithRTMPUrl:^(NSString *url) {
            [self startFacebookLive:url];
        }];
    }
    
}

- (void)startFacebookLive:(NSString *)url
{
    if (!url) {
        NSLog(@"url is null");
        return;
    }
    NSLog(@"facebook rtmp url: %@", url);
    

    LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
    videoConfiguration.videoSize = CGSizeMake(640, 360);
    videoConfiguration.videoBitRate = 800*1024;
    videoConfiguration.videoMaxBitRate = 1000*1024;
    videoConfiguration.videoMinBitRate = 500*1024;
    videoConfiguration.videoFrameRate = 20;
    videoConfiguration.videoMaxKeyframeInterval = 40;
    videoConfiguration.outputImageOrientation = UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
    videoConfiguration.autorotate = NO;
    
    LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
    audioConfiguration.numberOfChannels = 1;
    audioConfiguration.audioSampleRate = 48000;
    audioConfiguration.audioBitrate = 128000;
    
    self.liveManager = [[DUALiveManager alloc] initWithAudioConfiguration:audioConfiguration
                                                       videoConfiguration:videoConfiguration
                                                                  rmptUrl:url
                        ];
    [self.liveManager startLive];

}

- (IBAction)onStopClick:(id)sender
{
    [self.liveManager stopLive];
    
    NSDictionary *param = @{
                            @"end_live_video":@"true"
                            };
    FBSDKGraphRequest *liveRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@", liveVideoId]
                                                                       parameters:param
                                                                       HTTPMethod:@"POST"];
    [liveRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *liveConnection, id liveRequest, NSError *liveError) {
        NSDictionary *streamInfo = (NSDictionary *)liveRequest;
        NSLog(@"facebook live result: %@", streamInfo);
    }];

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
    [self.fbLoginManager logInWithPublishPermissions:@[@"publish_actions", @"manage_pages", @"publish_pages"]
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
                    userId = userInfo[@"id"];
                    NSDictionary *param = @{
                                            @"description":@"宇宙超级无敌巨搞笑直播",
                                            @"title":@"Just enjoy yourself!"
                                            };
                    FBSDKGraphRequest *liveRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/live_videos", userId]
                                                                                       parameters:param
                                                                                       HTTPMethod:@"POST"];
                    [liveRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *liveConnection, id liveRequest, NSError *liveError) {
                        NSDictionary *streamInfo = (NSDictionary *)liveRequest;
                        NSLog(@"facebook live info: %@", streamInfo);
                        liveVideoId = [streamInfo objectForKey:@"id"];
                        NSString *rtmpUrl = streamInfo[@"stream_url"];
                        callback(rtmpUrl);
                        self.fbrtmpUrl = rtmpUrl;
                    }];
                }
            }];
        }
    }];
    
}


- (void)requestAccessForAudio {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
}


@end
