//
//  DUAQueue.m
//  DUALive
//
//  Created by Mengmin Duan on 2017/5/2.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

#import "DUAQueue.h"

@interface DUAQueue ()

@property (nonatomic, strong) NSMutableArray *queue;

@end
@implementation DUAQueue

- (instancetype)init
{
    if (self = [super init]) {
        self.queue = [NSMutableArray arrayWithCapacity:50];
        self.currentCount = 0;
    }
    
    return self;
}

- (void)enQueue:(id)item
{
    [self.queue addObject:item];
}

- (id)deQueue
{
    if (self.queue.count == 0) {
        return nil;
    }else {
        id object = [self.queue objectAtIndex:0];
        [self.queue removeObjectAtIndex:0];
        return object;
    }
}

- (BOOL)isEmpty
{
    if (self.queue.count > 0) {
        return NO;
    }
    return YES;
}

- (NSUInteger)queueLength
{
    return self.queue.count;
}

@end
