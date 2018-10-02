//
//  MIProducer.h
//  MetalImage
//
//  Created by Sylar on 2018/9/28.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>


@protocol MIConsumer;
@class MITexture;
@interface MIProducer : NSObject{
    MITexture *_outputTexture;
    dispatch_semaphore_t _imageProcessingSemaphore;
    NSMutableArray<id<MIConsumer> > *_consumers;
}

@property (nonatomic, assign, getter = isEnabled) BOOL enabled;
@property (nonatomic, readonly) NSMutableArray<id<MIConsumer> > *consumers;
@property (nonatomic, assign) CGRect outputFrame;

- (void)addConsumer:(id<MIConsumer>)consumer;
- (void)removeConsumer:(id<MIConsumer>)consumer;
- (void)removeAllConsumers;
- (void)produceAtTime:(CMTime)time commandBuffer:(id<MTLCommandBuffer>)commandBuffer;

@end
