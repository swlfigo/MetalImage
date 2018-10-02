//
//  MIFilter.m
//  MetalImage
//
//  Created by Sylar on 2018/9/28.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIFilter.h"


@implementation MIFilter

- (instancetype)init
{
    self = [super init];
    if (self) {
        //创建ShaderState
        _renderPipelineState = [MIContext createRenderPipelineStateWithVertexFunction:[[self class] vertexShaderFunction]
                                                                     fragmentFunction:[[self class] fragmentShaderFunction]];
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        //清空画布颜色
        self.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        //顶点坐标
        _positionBuffer = [MIContext createBufferWithLength:4 * sizeof(vector_float4)];
        //输出纹理
        _outputTexture = [[MITexture alloc] init];
    }
    return self;
}

- (instancetype)initWithContentSize:(CGSize)contentSize {
    if (self = [self init]) {
        self.contentSize = contentSize;
    }
    return self;
}

- (void)setInputTexture:(MITexture *)inputTexture {
    _inputTexture = inputTexture;
}

- (void)renderRect:(CGRect)rect atTime:(CMTime)time commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
    if (!_inputTexture || !self.isEnabled) {
        return;
    }
    
    if (CGSizeEqualToSize(CGSizeZero, self.contentSize)) {
        self.contentSize = _inputTexture.size;
    }
    
    if (CGRectEqualToRect(self.outputFrame, CGRectZero)) {
        self.outputFrame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    }
    
    if (!CGSizeEqualToSize(self.contentSize, _outputTexture.size)) {
        [_outputTexture setupContentWithSize:self.contentSize];
    }
    
    if (!CGRectEqualToRect(_preRenderRect, rect)) {
        _preRenderRect = rect;
        //更新定点坐标相对位置
        [MIContext updateBufferContent:_positionBuffer contentSize:self.contentSize outputFrame:rect];
    }

    _renderPassDescriptor.colorAttachments[0].texture = _outputTexture.mtlTexture;;
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [commandEncoder setRenderPipelineState:_renderPipelineState];
    
    [commandEncoder setVertexBuffer:_positionBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:_inputTexture.textureCoordinateBuffer offset:0 atIndex:1];
    
    [commandEncoder setFragmentTexture:_inputTexture.mtlTexture atIndex:0];
    
    [self setVertexFragmentBufferOrTexture:commandEncoder];
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [commandEncoder endEncoding];
    
    [self produceAtTime:time commandBuffer:commandBuffer];
}

- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder {
    
}

- (void)setClearColor:(MTLClearColor)clearColor {
    _clearColor = clearColor;
    _renderPassDescriptor.colorAttachments[0].clearColor = _clearColor;
}


+ (NSString *)vertexShaderFunction {
    static NSString *vFunction = @"MIDefaultVertexShader";
    return vFunction;
}

+ (NSString *)fragmentShaderFunction {
    static NSString *fFunction = @"MIDefaultFragmentShader";
    return fFunction;
}



@end


