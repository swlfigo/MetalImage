//
//  MetalImageFilter.m
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalImageFilter.h"

@interface MetalImageFilter()
{
    NSMutableArray *textureArray;
    NSMutableArray *paramArray;
}
@end

@implementation MetalImageFilter



-(instancetype)initWithMetalRenderType:(MetalImageRenderType)renderType{
    if (self = [super init]) {
        
        if (renderType == MetalImageComputeFunctionType) {
            [self configComputeFunction];
        }else{
            [self configRenderFunction];
        }
        
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        orien_ = kMetalImageNoRotation;
        [self configComputeFunction];
    }
    return self;
}

-(void)configComputeFunction{
    outputTexture = nil;
    _inputTexture = nil;
    //初始化一个Compute Program
    filterProgram = [[MetalProgram alloc]initWithFunctionName:[[self class]functionName]];
    paramArray = [[NSMutableArray alloc]init];
    textureArray = [[NSMutableArray alloc]init];
}


-(void)configRenderFunction{
    outputTexture = nil;
    _inputTexture = nil;
    //初始化一个Render Program
    filterProgram = [[MetalProgram alloc]initWithVertexShaderName:[[self class]vertexShaderName] fragmentShaderName:[[self class]fragmentShaderName]];
    paramArray = [[NSMutableArray alloc]init];
    textureArray = [[NSMutableArray alloc]init];
}

-(void)setInputTexture:(MetalTexture *)inputTexture{
    if (_inputTexture != inputTexture) {
        _inputTexture = nil ;
        _inputTexture = inputTexture;
    }
}

-(void)setTextureOrien:(MetalImageRotationMode)orien{
    if (_inputTexture ) {
        _inputTexture.orientation = orien;
    }
    orien_ = orien;
}

- (void)render {
    //绘制
    if (!_inputTexture) return;
    
    if (!filterProgram) return;
    
    
    
    if ( filterProgram.renderType == MetalImageComputeFunctionType) {
        
        //Compute渲染
        if (!outputTexture && !CGSizeEqualToSize(outputTexture.size, _inputTexture.size)) {
            
            //生成输出纹理
         outputTexture = [[MetalTexture alloc]initWithTexturePixelFormat:MTLPixelFormatBGRA8Unorm TextureWidth:[_inputTexture.texture width] TextureHeight:[_inputTexture.texture height]];
        }
        
        
        //new output texture for next filter
        if (filterProgram.threadGroupSize.width == 0 || filterProgram.threadGroupSize.height == 0 || filterProgram.threadGroupCount.depth == 0) {
            
            NSInteger w = filterProgram.computePipeline.threadExecutionWidth;
            NSInteger h = filterProgram.computePipeline.maxTotalThreadsPerThreadgroup / w;
            filterProgram.threadGroupSize = MTLSizeMake(w, h, 1);
            
        }
        
        //calculate compute kenel's width and height
        NSUInteger nthreadWidthSteps  = (_inputTexture.size.width + filterProgram.threadGroupSize.width - 1) / filterProgram.threadGroupSize.width;
        NSUInteger nthreadHeightSteps = (_inputTexture.size.height + filterProgram.threadGroupSize.height - 1 )/ filterProgram.threadGroupSize.height;
        filterProgram.threadGroupCount = MTLSizeMake(nthreadWidthSteps, nthreadHeightSteps, 1);
        
        
        id<MTLCommandBuffer> commandBuffer = [[MetalContext defaultContext].commandQueue commandBuffer];
        id<MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
        [commandEncoder setComputePipelineState:filterProgram.computePipeline];
        //设置纹理
        [commandEncoder setTexture:outputTexture.texture atIndex:0];
        [commandEncoder setTexture:_inputTexture.texture atIndex:1];
        
        //设置多张纹理,从2位置开始设置
        NSArray *textureArrayFromCurrentFilter = [self textureParam];
        if (textureArrayFromCurrentFilter.count) {
            for (int i = 0 ; i < textureArrayFromCurrentFilter.count; ++i) {
                MetalTexture *textureToBlind = textureArrayFromCurrentFilter[i];
                if ([textureToBlind isKindOfClass:[MetalTexture class]] && textureToBlind.texture ) {
                    [commandEncoder setTexture:textureToBlind.texture atIndex:i+2];
                }
            }
        }
        
        
        //着色器传入数据
        NSArray *paramArrayFromCurrentFilter = [self filterParam];
        if (paramArrayFromCurrentFilter.count) {

            for (int i = 0 ;  i < paramArrayFromCurrentFilter.count; ++i) {
                float param = [(paramArrayFromCurrentFilter[i]) floatValue];
                id<MTLBuffer> uniformBuffer = [[MetalContext defaultContext].device newBufferWithBytes:&param length:sizeof(param) options:MTLResourceOptionCPUCacheModeDefault];
                [commandEncoder setBuffer:uniformBuffer offset:0 atIndex:i];
            }
        }
        
        [commandEncoder dispatchThreadgroups:filterProgram.threadGroupCount threadsPerThreadgroup:filterProgram.threadGroupSize];
        [commandEncoder endEncoding];
        [commandBuffer commit];
        
        
        
    }else{
        //RenderFunction
        if (!outputTexture && !CGSizeEqualToSize(outputTexture.size, _inputTexture.size)) {
            
            //生成输出纹理
            outputTexture = [[MetalTexture alloc]initWithTexturePixelFormat:MTLPixelFormatBGRA8Unorm TextureWidth:[_inputTexture.texture width] TextureHeight:[_inputTexture.texture height]];
            
        }
        
        MTLRenderPassDescriptor *renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
        MTLRenderPassColorAttachmentDescriptor    *colorAttachment  = renderPassDescriptor.colorAttachments[0];
        colorAttachment.texture         = outputTexture.texture;
        colorAttachment.loadAction      = MTLLoadActionClear;
        colorAttachment.clearColor      = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);//black
        colorAttachment.storeAction     = MTLStoreActionStore;
        [filterProgram setupProgramRenderPassDescriptor:renderPassDescriptor];
        
        
        
       
        
        id<MTLCommandBuffer> commandBuffer = [[MetalContext defaultContext].commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:filterProgram.renderPassDescriptor];
        [commandEncoder pushDebugGroup:[NSString stringWithFormat:@"%@ DebugGroup",NSStringFromClass([self class])] ];
        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [commandEncoder setRenderPipelineState:filterProgram.renderPipelineState];
        [commandEncoder setFragmentTexture: _inputTexture.texture atIndex:0];
        [commandEncoder setVertexBuffer:[self verticesBuffer]  offset:0  atIndex: 0 ];
        [commandEncoder setVertexBuffer:_inputTexture.textureCoordinate offset:0  atIndex: 1];
        
        //设置多张纹理,从2位置开始设置
        NSArray *textureArrayFromCurrentFilter = [self textureParam];
        if (textureArrayFromCurrentFilter.count) {
            for (int i = 0 ; i < textureArrayFromCurrentFilter.count; ++i) {
                MetalTexture *textureToBlind = textureArrayFromCurrentFilter[i];
                if ([textureToBlind isKindOfClass:[MetalTexture class]] && textureToBlind.texture ) {
                    [commandEncoder setFragmentTexture:textureToBlind.texture atIndex:i+2];
                }
            }
        }
        
        
        //着色器传入数据
        NSArray *paramArrayFromCurrentFilter = [self filterParam];
        if (paramArrayFromCurrentFilter.count) {
            
            for (int i = 0 ;  i < paramArrayFromCurrentFilter.count; ++i) {
                float param = [(paramArrayFromCurrentFilter[i]) floatValue];
                id<MTLBuffer> uniformBuffer = [[MetalContext defaultContext].device newBufferWithBytes:&param length:sizeof(param) options:MTLResourceOptionCPUCacheModeDefault];
                [commandEncoder setVertexBuffer:uniformBuffer offset:0 atIndex:i];
            }
        }
        [commandEncoder drawPrimitives: MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
        [commandEncoder endEncoding];
        [commandBuffer commit];
        
    }
    
    //下一级消费者处理纹理
    [self produceAtTime];
}


//子类重写 返回着色器参数
-(NSArray*)filterParam{
    return paramArray;
}

//子类重写 返回纹理
-(NSArray<MetalTexture *> *)textureParam{
    return textureArray;
}

+(NSString *)functionName{
    static NSString *fName = @"defaultFunction";
    return fName;
}

//子类重写->用于RenderFunction
+(NSString *)fragmentShaderName{
    static NSString *fName = @"defaultShaderFragment";
    return fName;
}

+(NSString*)vertexShaderName{
    static NSString *vName = @"defaultShaderVertex";
    return vName;
}

-(id<MTLBuffer>)verticesBuffer{
    static const vector_float4 imageVertices[6] = {
        { -1.0f,  -1.0f, 0.0f, 1.0f },
        {  1.0f,  -1.0f, 0.0f, 1.0f },
        { -1.0f,   1.0f, 0.0f, 1.0f },
        
        {  1.0f,  -1.0f, 0.0f, 1.0f },
        { -1.0f,   1.0f, 0.0f, 1.0f },
        {  1.0f,   1.0f, 0.0f, 1.0f },
    };
    id<MTLDevice> device = [MetalContext defaultContext].device;
    
    id<MTLBuffer> verticesBuffer = [device newBufferWithBytes:imageVertices length:sizeof(imageVertices) options:MTLResourceOptionCPUCacheModeDefault];
    verticesBuffer.label = [NSString stringWithFormat:@"%@ quad vertices",NSStringFromClass([self class])];
    
    return verticesBuffer;
}

@end
