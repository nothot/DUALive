//
//  ViewController.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "ViewController.h"
#import "DUAAVCaptureManager.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *colorArray;
@property (nonatomic, strong) DUAAVCaptureManager *avCaptureManager;

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
    AWVideoConfig *videoConfig = [[AWVideoConfig alloc] init];
    videoConfig.fps = 25;
    AWAudioConfig *audioConfig = [[AWAudioConfig alloc] init];
    audioConfig.sampleRate = 48000;
    
    //获取推流地址rtmpUrl
    NSString *rtmpUrl = @"";
    self.avCaptureManager = [[DUAAVCaptureManager alloc] initWithVideoConfig:videoConfig AudioConfig:audioConfig RtmpUrl:rtmpUrl];
    [self.avCaptureManager startLive];
}

- (IBAction)onStopClick:(id)sender
{
    [self.avCaptureManager stopLive];
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
