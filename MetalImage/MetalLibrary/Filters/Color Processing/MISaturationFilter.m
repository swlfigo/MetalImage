//
//  MISaturationFilter.m
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MISaturationFilter.h"

@implementation MISaturationFilter

- (instancetype)init {
    if (self = [super init]) {
        _saturationBuffer = [MIContext createBufferWithLength:sizeof(float)];
        self.saturation = 1.0;
    }
    return self;
}

- (void)setSaturation:(float)saturation {
    if (saturation < 0.0f) {
        saturation = 0.0f;
    }
    
    if (saturation > 2.0f) {
        saturation = 2.0f;
    }
    _saturation = saturation;
    
    float *saturations = _saturationBuffer.contents;
    saturations[0] = _saturation;
}

- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder {
    [super setVertexFragmentBufferOrTexture:commandEncoder];
    [commandEncoder setFragmentBuffer:_saturationBuffer offset:0 atIndex:0];
}

+ (NSString *)fragmentShaderFunction {
    NSString *funciton = @"MISaturationFragmentShader";
    return funciton;
}

@end
