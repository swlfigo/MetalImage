//
//  MetalProgram.m
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalProgram.h"

@interface MetalProgram ()
{
    id <MTLLibrary> renderLibrary;
}
@end

@implementation MetalProgram

//用于Compute Function的初始化
-(instancetype)initWithFunctionName:(NSString *)functionName{
    if (self = [super init]) {
        
        NSError *error = nil;
        renderLibrary  = [[MetalContext defaultContext].device newDefaultLibrary];
        _kernelFunction = [renderLibrary newFunctionWithName:functionName];
        _computePipeline = [[MetalContext defaultContext].device newComputePipelineStateWithFunction:_kernelFunction error:&error];
        _renderType = MetalImageComputeFunctionType;
    }
    return self;
}

//用于Render Function初始化
-(id)initWithVertexShaderName:(NSString *)vShaderName fragmentShaderName:(NSString *)fShaderName{
    
    if (!vShaderName || !fShaderName) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        
        renderLibrary  = [[MetalContext defaultContext].device newDefaultLibrary];
        
        id <MTLFunction> vertexProgram   = [renderLibrary newFunctionWithName:vShaderName];
        // get the fragment function from the library
        id <MTLFunction> fragmentProgram = [renderLibrary newFunctionWithName:fShaderName];
        
        _renderPipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
        _renderPipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        _renderPipelineStateDescriptor.sampleCount                     = 1;
        _renderPipelineStateDescriptor.vertexFunction                  = vertexProgram;
        _renderPipelineStateDescriptor.fragmentFunction                = fragmentProgram;
        
        
        NSError *pError = nil;
        _renderPipelineState = [[MetalContext defaultContext].device newRenderPipelineStateWithDescriptor:_renderPipelineStateDescriptor error:&pError];
        
        _renderType = MetalImageRenderFunctionType;
        
        if(!_renderPipelineState)
        {
            NSLog(@"MetalProgram ==========>> ERROR: Failed acquiring pipeline state descriptor: %@", pError);
            
            return nil;
        }
        
    }
    return self;
}

//Render描述配置
-(void)setupProgramRenderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor{
    
    if (!renderPassDescriptor) {
        NSLog(@"MetalProgram can not setup RenderPassDescriptor with nil object! ");
    }
    
    if (self.renderPassDescriptor) {
        _renderPassDescriptor = nil;
    }
    
    _renderPassDescriptor = renderPassDescriptor;
    NSError *pError = nil;
    _renderPipelineState = [[MetalContext defaultContext].device newRenderPipelineStateWithDescriptor:_renderPipelineStateDescriptor error:&pError];
    if(!_renderPipelineState)
    {
        NSLog(@"MetalProgram ==========>> ERROR: Failed acquiring pipeline state descriptor: %@", pError);
    }
}

@end
