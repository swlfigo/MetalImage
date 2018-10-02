//
//  MIContrastFilter.m
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIContrastFilter.h"

@implementation MIContrastFilter

- (instancetype)init {
    if (self = [super init]) {
        
        _contrastBuffer = [MIContext createBufferWithLength:sizeof(float)];
        self.contrast = 1.0;
    }
    return self;
}

- (void)setContrast:(float)contrast {
    if (contrast < 0.0f) {
        contrast = 0.0f;
    }
    
    if (contrast > 4.0f) {
        contrast = 4.0f;
    }
    _contrast = contrast;
    
    float *contrasts = _contrastBuffer.contents;
    contrasts[0] = _contrast;
}

- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder {
    [super setVertexFragmentBufferOrTexture:commandEncoder];
    [commandEncoder setFragmentBuffer:_contrastBuffer offset:0 atIndex:0];
}

+ (NSString *)fragmentShaderFunction {
    NSString *funciton = @"MIContrastFragmentShader";
    return funciton;
}

@end
