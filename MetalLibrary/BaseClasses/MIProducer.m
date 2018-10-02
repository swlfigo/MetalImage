//
//  MIProducer.m
//  MetalImage
//
//  Created by Sylar on 2018/9/28.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIProducer.h"
#import "MIConsumer.h"
#import "MIContext.h"
#import "MITexture.h"

@implementation MIProducer

- (instancetype)init {
#if TARGET_IPHONE_SIMULATOR
    return nil;
#endif
    if (self = [super init]) {
        _imageProcessingSemaphore = dispatch_semaphore_create(1);
        _enabled = YES;
        _consumers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addConsumer:(id<MIConsumer>)consumer {
    [MIContext performSynchronouslyOnImageProcessingQueue:^{
        if (!consumer) {
            return;
        }
        [_consumers addObject:consumer];
    }];
}

- (void)removeConsumer:(id<MIConsumer>)consumer {
    [MIContext performSynchronouslyOnImageProcessingQueue:^{
        if (!consumer) {
            return;
        }
        
        if ([_consumers containsObject:consumer]) {
            [_consumers removeObject:consumer];
        }
    }];

}

- (void)removeAllConsumers {
    [MIContext performSynchronouslyOnImageProcessingQueue:^{
        [_consumers removeAllObjects];
    }];

}

- (void)produceAtTime:(CMTime)time commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
    [MIContext performSynchronouslyOnImageProcessingQueue:^{
        if (_outputTexture && _consumers.count) {
            for (id <MIConsumer> consumer in _consumers) {
                [consumer setInputTexture:_outputTexture];
                [consumer renderRect:self.outputFrame atTime:time commandBuffer:commandBuffer];
            }
        }
    }];
    
    
}

@end
