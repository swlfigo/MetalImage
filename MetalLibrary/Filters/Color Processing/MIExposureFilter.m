//
//  MIExposureFilter.m
//  MetalImage
//
//  Created by zsr on 2018/6/18.
//  Copyright © 2018年 beauty Inc. All rights reserved.
//

#import "MIExposureFilter.h"

@implementation MIExposureFilter

- (instancetype)init {
    if (self = [super init]) {
        _exposureBuffer = [MIContext createBufferWithLength:sizeof(float)];
        self.exposure = 0.0;
    }
    return self;
}

- (void)setExposure:(float)exposure {
    if (exposure < -10.0f) {
        exposure = -10.0f;
    }
    
    if (exposure > 10.0f) {
        exposure = 10.0f;
    }
    
    _exposure = exposure;
    
    float *exposures = _exposureBuffer.contents;
    exposures[0] = _exposure;
}

- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder {
    [super setVertexFragmentBufferOrTexture:commandEncoder];
    [commandEncoder setFragmentBuffer:_exposureBuffer offset:0 atIndex:0];
}

+ (NSString *)fragmentShaderFunction {
    NSString *funciton = @"MIExposureFragmentShader";
    return funciton;
}


@end
