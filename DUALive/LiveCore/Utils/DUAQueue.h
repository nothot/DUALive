//
//  DUAQueue.h
//  DUALive
//
//  Created by Mengmin Duan on 2017/5/2.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DUAQueue : NSObject

@property (nonatomic, assign) NSUInteger currentCount;

- (instancetype)init;
- (void)enQueue:(id)item;
- (id)deQueue;
- (BOOL)isEmpty;

@end
