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
        //self.queue = [[NSMutableArray alloc] init];
        self.queue = [NSMutableArray arrayWithCapacity:50];
    }
    
    return self;
}

- (void)enQueue:(id)item
{
    NSLog(@"===> in queue, count: %lu", (unsigned long)self.queue.count);
    [self.queue addObject:item];
}

- (id)deQueue
{
    if (self.queue.count == 0) {
        NSLog(@"===> queue is empty.");
        return nil;
    }else {
        NSLog(@"===> out queue, count: %lu", (unsigned long)self.queue.count);
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

@end
