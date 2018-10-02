//
//  MIRGBFilter.m
//  MetalImage
//
//  Created by zsr on 2018/6/18.
//  Copyright © 2018年 beauty Inc. All rights reserved.
//

#import "MIRGBFilter.h"

@implementation MIRGBFilter

- (instancetype)init {
    if (self = [super init]) {
        
        _redBuffer = [MIContext createBufferWithLength:sizeof(float)];
        _greenBuffer = [MIContext createBufferWithLength:sizeof(float)];
        _blueBuffer = [MIContext createBufferWithLength:sizeof(float)];
        self.red = 1.0;
        self.green = 1.0;
        self.blue = 1.0;
    }
    return self;
}

- (void)setRed:(float)newValue {
    _red = newValue;
    
    float *reds = _redBuffer.contents;
    reds[0] = _red;
}

- (void)setGreen:(float)newValue {
    _green = newValue;
    
    float *greens = _greenBuffer.contents;
    greens[0] = _green;
}

- (void)setBlue:(float)newValue {
    _blue = newValue;
    
    float *blues = _blueBuffer.contents;
    blues[0] = _blue;
}

- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder {
    [super setVertexFragmentBufferOrTexture:commandEncoder];
    [commandEncoder setFragmentBuffer:_redBuffer offset:0 atIndex:0];
    [commandEncoder setFragmentBuffer:_greenBuffer offset:0 atIndex:1];
    [commandEncoder setFragmentBuffer:_blueBuffer offset:0 atIndex:2];
}

+ (NSString *)fragmentShaderFunction {
    NSString *funciton = @"MIRGBFragmentShader";
    return funciton;
}

@end
