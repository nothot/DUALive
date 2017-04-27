//
//  ViewController.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/4/26.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "ViewController.h"
#import "DUAAudioCapture.h"
#import "DUAVideoCapture.h"

@interface ViewController ()

@end

@implementation ViewController

DUAVideoCapture *videoCapture;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    DUAAudioCapture *capture = [DUAAudioCapture new];
//    [capture startAudioCapture];
//    
//    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)5*NSEC_PER_SEC);
//    dispatch_after(time, dispatch_get_main_queue(), ^ {
//        [capture stopAudioCapture];
//    });
    
    videoCapture = [DUAVideoCapture new];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onStartClick:(id)sender
{
    [videoCapture startVideoCapture];
}

- (IBAction)onStopClick:(id)sender
{
    [videoCapture stopVideoCapture];
}

- (IBAction)onColorClick:(id)sender
{
    
}

@end
