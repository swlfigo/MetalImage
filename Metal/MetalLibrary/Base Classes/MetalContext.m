//
//  MetalContext.m
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalContext.h"

@interface MetalContext(){
    long kCmdBuffersforProcessing;  //handle by different cpu threads
}
@end

@implementation MetalContext


static void *metalContextQueueKey;

+ (instancetype)defaultContext {
    static dispatch_once_t onceToken;
    static MetalContext *instance = nil;
    dispatch_once(&onceToken, ^{
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        instance = [[MetalContext alloc] initWithDevice:device];
    });
    
    return instance;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if ((self = [super init])) {
        kCmdBuffersforProcessing = 3;
        _device = device;
        _library = [_device newDefaultLibrary];
        _commandQueue = [_device newCommandQueue];
        
        _cmdBuffer_process_semaphore = dispatch_semaphore_create(kCmdBuffersforProcessing);
        
        
        metalContextQueueKey = &metalContextQueueKey;
        
        _imageProcessingQueue = dispatch_queue_create("Sylar.MetalImageProcessor.imageProcessingQueue", GPUImageDefaultQueueAttribute());
        

        dispatch_queue_set_specific(_imageProcessingQueue, metalContextQueueKey, (__bridge void *)self, NULL);

    }
    
    return self;
}

dispatch_queue_attr_t GPUImageDefaultQueueAttribute(void)
{
#if TARGET_OS_IPHONE
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
    {
        return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    }
#endif
    return nil;
}


+(dispatch_semaphore_t)getSemaphore{
    return [MetalContext defaultContext].cmdBuffer_process_semaphore;
}

+(void *)contextKey{
    return metalContextQueueKey;
}

+(dispatch_queue_t)metalContextQueue{
    return [MetalContext defaultContext].imageProcessingQueue;
}

+(void)performSynchronouslyOnImageProcessingQueue:(void (^)(void))block{
    dispatch_queue_t imageProcessingQueue = [MetalContext metalContextQueue];
    
    if (block) {
        if (dispatch_get_specific([MetalContext contextKey])) {
            block();
        }else{
            dispatch_sync(imageProcessingQueue, block);
        }
    }
    
}

+(void)performAsynchronouslyOnImageProcessingQueue:(void (^)(void))block{
    
    dispatch_queue_t imageProcessingQueue = [MetalContext metalContextQueue];
    
    if (block) {
        if (dispatch_get_specific([MetalContext contextKey])) {
            block();
        }else{
            dispatch_async(imageProcessingQueue, block);
        }
    }
}
@end
