//
//  MetalContext.h
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MetalContext : NSObject


//单例化Context
+ (instancetype)defaultContext;

//处理Queue
@property (readonly, nonatomic) dispatch_queue_t imageProcessingQueue;

//处理信号量
@property(nonatomic, readonly) dispatch_semaphore_t cmdBuffer_process_semaphore;


//Device
//在Metal中，设备是GPU的抽象。我们可以通过MTLCreateSystemDefaultDevice方法来获取当前设备
@property (nonatomic, strong) id<MTLDevice> device;



//Shader Library
/*
 warning: 库中至少需要一个默认的Shader,不然报错
 */
@property (nonatomic, strong) id<MTLLibrary> library;


/*
 
 The MTLCommandQueue protocol defines the interface for an object that can queue an ordered list of command buffers for a Metal device to execute. In general, command queues are thread-safe and allow multiple outstanding command buffers to be encoded simultaneously.
 
 MTLCommandQueue协议定义了对象的接口,可以队列有序列表的命令缓冲区执行渲染。
 */

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;


//信号量
+(dispatch_semaphore_t)getSemaphore;



//ContextKey
+(void *)contextKey;

//imageProcessQueue
+(dispatch_queue_t)metalContextQueue;

+ (void)performSynchronouslyOnImageProcessingQueue:(void (^)(void))block;

+ (void)performAsynchronouslyOnImageProcessingQueue:(void (^)(void))block;
@end
