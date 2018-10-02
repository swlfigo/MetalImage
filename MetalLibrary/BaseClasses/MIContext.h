//
//  MIContext.h
//  MetalImage
//
//  Created by Sylar on 2018/9/3.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>

//Metal全局环境变量
@interface MIContext : NSObject

//单例化Context
+ (instancetype)defaultContext;

//处理Queue
@property (nonatomic,readonly ) dispatch_queue_t imageProcessingQueue;


//Device
//在Metal中，设备是GPU的抽象。我们可以通过MTLCreateSystemDefaultDevice方法来获取当前设备
@property (nonatomic, strong ,readonly) id<MTLDevice> device;


//Shader Library
/*
 warning: 库中至少需要一个默认的Shader,不然报错
 */
@property (nonatomic, strong , readonly) id<MTLLibrary> library;


/*
 The MTLCommandQueue protocol defines the interface for an object that can queue an ordered list of command buffers for a Metal device to execute. In general, command queues are thread-safe and allow multiple outstanding command buffers to be encoded simultaneously.

 MTLCommandQueue协议定义了对象的接口,可以队列有序列表的命令缓冲区执行渲染。
 */

@property (nonatomic, strong ,readonly) id<MTLCommandQueue> commandQueue;

//Core Video的Metal纹理缓存
//A Core Video Metal texture cache creates and manages CVMetalTextureRef textures. You use a CVMetalTextureCache object to directly read from or write to GPU-based Core Video image buffers in rendering or GPU compute tasks that use the Metal framework. For example, you can use a Metal texture cache to present live output from a device’s camera in a 3D scene rendered with Metal.
//快速读或者写入GPU缓存图片
#if !TARGET_IPHONE_SIMULATOR
@property (nonatomic, readonly) CVMetalTextureCacheRef videoTextureCache;
#endif


//ContextKey
+(void *)contextKey;

//imageProcessQueue
+(dispatch_queue_t)metalContextQueue;

+ (void)performSynchronouslyOnImageProcessingQueue:(void (^)(void))block;

+ (void)performAsynchronouslyOnImageProcessingQueue:(void (^)(void))block;

//创建顶点纹理坐标Buffer
+ (id<MTLBuffer>)createBufferWithLength:(NSUInteger)length;


//创建Shader Pipline
+ (id<MTLRenderPipelineState>)createRenderPipelineStateWithVertexFunction:(NSString *)vertexFunction
                                                         fragmentFunction:(NSString *)fragmentFunction;

//更新outputFrame与画布大小的相对顶点坐标,居中于画布绘制
+ (void)updateBufferContent:(id<MTLBuffer>)buffer contentSize:(CGSize)contentSize outputFrame:(CGRect)outputFrame;

@end
