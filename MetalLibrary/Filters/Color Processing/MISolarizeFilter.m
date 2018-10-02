//
//  MISolarizeFilter.m
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MISolarizeFilter.h"

@implementation MISolarizeFilter

- (instancetype)init {
    if (self = [super init]) {
        _thresholdBuffer = [MIContext createBufferWithLength:sizeof(float)];
        self.threshold = 0.5;
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
    NSString *fFunction = @"MISolarizeFragmentShader";
    return fFunction;
}

@end
