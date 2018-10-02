//
//  MIHueFilter.m
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIHueFilter.h"

@implementation MIHueFilter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hueAdjustBuffer = [MIContext createBufferWithLength:sizeof(float)];
        _hue = 90.0;
    }
    return self;
}

- (void)setHue:(float)hue {
    // Convert degrees to radians for hue rotation
    _hue = fmodf(hue, 360.0) * M_PI/180;
    
    float *hues = _hueAdjustBuffer.contents;
    
    hues[0] = _hue;
}

- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder {
    [super setVertexFragmentBufferOrTexture:commandEncoder];
    [commandEncoder setFragmentBuffer:_hueAdjustBuffer offset:0 atIndex:0];
}

+ (NSString *)fragmentShaderFunction {
    NSString *funciton = @"MIHueFragmentShader";
    return funciton;
}
@end
