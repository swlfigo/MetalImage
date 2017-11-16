//
//  MetalProducer.h
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalProgram.h"

@interface MetalProducer : NSObject
{
    MetalTexture *outputTexture;
    NSMutableArray *consumers;
}


//Program
@property(nonatomic,strong)MetalProgram *program;

//添加消费者
- (void)addConsumer:(id <MetalConsumer>)consumer;

//去除消费者
- (void)removeConsumer:(id <MetalConsumer>)consumer;
- (void)removeAllConsumers;




//Producer处理纹理
- (void)produceAtTime;
//获得当前帧纹理
- (UIImage*)imageFromCurrentFrame;
@end
