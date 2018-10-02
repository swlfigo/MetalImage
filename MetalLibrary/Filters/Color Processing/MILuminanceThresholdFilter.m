//
//  MILuminanceThresholdFilter.m
//  MetalImage
//
//  Created by zsr on 2018/6/18.
//  Copyright © 2018年 beauty Inc. All rights reserved.
//

#import "MILuminanceThresholdFilter.h"

@implementation MILuminanceThresholdFilter

- (instancetype)init {
    if (self = [super init]) {
        _thresholdBuffer = [MIContext createBufferWithLength:sizeof(float)];
        self.threshold = 0.25;
    }
    return self;
}

- (void)setThreshold:(float)threshold {
    _threshold = threshold;
    float *thresholds = _thresholdBuffer.contents;
    thresholds[0] = threshold;
}

- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder {
    [super setVertexFragmentBufferOrTexture:commandEncoder];
    [commandEncoder setFragmentBuffer:_thresholdBuffer offset:0 atIndex:0];
}

+ (NSString *)fragmentShaderFunction {
    NSString *fFunction = @"MILuminanceThresholdFragmentShader";
    return fFunction;
}

@end

