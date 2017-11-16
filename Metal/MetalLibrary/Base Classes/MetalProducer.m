//
//  MetalProducer.m
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalProducer.h"

@interface MetalProducer(){
    
}
@end

@implementation MetalProducer


- (instancetype)init
{
    self = [super init];
    if (self) {
        consumers = [[NSMutableArray alloc]init];
    }
    return self;
}

//添加消费者
-(void)addConsumer:(id<MetalConsumer>)consumer{
    
    [MetalContext performSynchronouslyOnImageProcessingQueue:^{
        if (!consumer) {
            return;
        }
        [consumers addObject:consumer];
    }];
    
    
}

-(void)removeConsumer:(id<MetalConsumer>)consumer{
    
    [MetalContext performSynchronouslyOnImageProcessingQueue:^{
        if (!consumer) {
            return;
        }
        
        if ([consumers containsObject:consumer]) {
            [consumers removeObject:consumer];
        }
    }];
    
    
}

- (void)removeAllConsumers
{
    [MetalContext performSynchronouslyOnImageProcessingQueue:^{
        [consumers removeAllObjects];
    }];
    
    
}

-(void)produceAtTime{
    
    [MetalContext performSynchronouslyOnImageProcessingQueue:^{
        if (outputTexture && [consumers count]) {
            for (id <MetalConsumer> consumer in consumers) {
                [consumer setInputTexture:outputTexture];
                [consumer render];
            }
        }
    }];
    
}

-(UIImage *)imageFromCurrentFrame{
    
    return [outputTexture imageFromCurrentTexture];
}
@end
