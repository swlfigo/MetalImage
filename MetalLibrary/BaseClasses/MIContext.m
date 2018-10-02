//
//  MIContext.m
//  MetalImage
//
//  Created by Sylar on 2018/9/3.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIContext.h"
#import <simd/simd.h>
static void *metalContextQueueKey;

@interface MIContext ()
{
    #if !TARGET_IPHONE_SIMULATOR
    CVMetalTextureCacheRef _videoTextureCache;
    #endif
}
@end

@implementation MIContext

+ (instancetype)defaultContext {
    static dispatch_once_t onceToken;
    static MIContext *instance = nil;
    dispatch_once(&onceToken, ^{
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        instance = [[MIContext alloc] initWithDevice:device];
    });
    
    return instance;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if ((self = [super init])) {
        
        _device = device;
        
        _library = [_device newDefaultLibrary];
        
        _commandQueue = [_device newCommandQueue];
        
        metalContextQueueKey = &metalContextQueueKey;
        
        _imageProcessingQueue = dispatch_queue_create("Sylar.MetalImageProcessor.imageProcessingQueue",NULL);
        
        dispatch_queue_set_specific(_imageProcessingQueue, metalContextQueueKey, (__bridge void *)self, NULL);
        
    }
    
    return self;
}

#if !TARGET_IPHONE_SIMULATOR
-(CVMetalTextureCacheRef)videoTextureCache{
    if (!_videoTextureCache) {
        CVMetalTextureCacheFlush(_videoTextureCache, 0);
        CVReturn textureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                                               NULL,
                                                               [MIContext defaultContext].device,
                                                               NULL,
                                                               &_videoTextureCache);
        if (textureCacheError) {
            NSLog(@">> ERROR: CVMetalTextureCacheCreate");
            assert(0);
        }
    }
    return _videoTextureCache;
}

#endif

+(void *)contextKey{
    return metalContextQueueKey;
}

+(dispatch_queue_t)metalContextQueue{
    return [MIContext defaultContext].imageProcessingQueue;
}

+(void)performSynchronouslyOnImageProcessingQueue:(void (^)(void))block{
    dispatch_queue_t imageProcessingQueue = [MIContext metalContextQueue];
    
    if (block) {
        if (dispatch_get_specific([MIContext contextKey])) {
            block();
        }else{
            dispatch_sync(imageProcessingQueue, block);
        }
    }
    
}

+(void)performAsynchronouslyOnImageProcessingQueue:(void (^)(void))block{
    
    dispatch_queue_t imageProcessingQueue = [MIContext metalContextQueue];
    
    if (block) {
        if (dispatch_get_specific([MIContext contextKey])) {
            block();
        }else{
            dispatch_async(imageProcessingQueue, block);
        }
    }
}


+(id<MTLBuffer>)createBufferWithLength:(NSUInteger)length{
    id<MTLBuffer> mtlBuffer = [[MIContext defaultContext].device newBufferWithLength:length options:MTLResourceCPUCacheModeDefaultCache];
    return mtlBuffer;
}

+ (id<MTLRenderPipelineState>)createRenderPipelineStateWithVertexFunction:(NSString *)vertexFunction fragmentFunction:(NSString *)fragmentFunction{
    id<MTLFunction> vertexFunc = nil;
    id<MTLFunction> fragmentFunc = nil;
    
    vertexFunc = [[MIContext defaultContext].library newFunctionWithName:vertexFunction];
    
    
    fragmentFunc = [[MIContext defaultContext].library newFunctionWithName:fragmentFunction];
    
    
    if (!vertexFunc) {
        NSLog(@"MetalImage Error : vertexFunction : %@ not fount",vertexFunction);
    }
    
    if (!fragmentFunc) {
        NSLog(@"MetalImage Error : fragmentFunction : %@ not fount",fragmentFunction);
    }
    
    id<MTLRenderPipelineState> pipeline = [self createPipleStateWithVertexFunc:vertexFunc fragmentFunc:fragmentFunc];
    return pipeline;
}

#pragma mark - private

+ (id<MTLRenderPipelineState>)createPipleStateWithVertexFunc:(id<MTLFunction>)vertexFunc fragmentFunc:(id<MTLFunction>)fragmentFunc {
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    
    NSError *error = nil;
    id<MTLRenderPipelineState> pipeline = [[MIContext defaultContext].device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    
    if (!pipeline) {
        NSLog(@"MetalImage Error : occurred when creating render pipeline state: %@", error);
    }
    return pipeline;
}

+ (void)updateBufferContent:(id<MTLBuffer>)buffer contentSize:(CGSize)contentSize outputFrame:(CGRect)outputFrame {
    if (!buffer || buffer.length < 4 * sizeof(vector_float4) || CGSizeEqualToSize(CGSizeZero, contentSize)) {
        return;
    }
    vector_float4 *bufferContent = buffer.contents;
    
    if (CGRectEqualToRect(outputFrame, CGRectZero)) {
        bufferContent[0] = vector4(-1.0f, -1.0f, 0.0f, 1.0f);
        bufferContent[1] = vector4( 1.0f, -1.0f, 0.0f, 1.0f);
        bufferContent[2] = vector4(-1.0f,  1.0f, 0.0f, 1.0f);
        bufferContent[3] = vector4( 1.0f,  1.0f, 0.0f, 1.0f);
        return;
    }
    
    float left   = outputFrame.origin.x / contentSize.width * 2.0 - 1.0;
    float right  = (outputFrame.origin.x + outputFrame.size.width) / contentSize.width * 2.0 - 1.0;
    float top    = (1.0 - outputFrame.origin.y / contentSize.height) * 2.0 - 1.0;
    float bottom = (1.0 - (outputFrame.origin.y + outputFrame.size.height) / contentSize.height) * 2.0 - 1.0;
    
    bufferContent[0] = vector4(left,  bottom, 0.0f, 1.0f);
    bufferContent[1] = vector4(right, bottom, 0.0f, 1.0f);
    bufferContent[2] = vector4(left,  top, 0.0f, 1.0f);
    bufferContent[3] = vector4(right, top, 0.0f, 1.0f);
}

@end
