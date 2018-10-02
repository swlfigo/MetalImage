//
//  MILevelsFilter.m
//  MetalImage
//
//  Created by zsr on 2018/6/18.
//  Copyright © 2018年 beauty Inc. All rights reserved.
//

#import "MILevelsFilter.h"

@implementation MILevelsFilter

- (instancetype)init {
    if (self = [super init]) {
        _minBuffer = [MIContext createBufferWithLength:sizeof(vector_float3)];
        _midBuffer = [MIContext createBufferWithLength:sizeof(vector_float3)];
        _maxBuffer = [MIContext createBufferWithLength:sizeof(vector_float3)];
        _minOutputBuffer = [MIContext createBufferWithLength:sizeof(vector_float3)];
        _maxOutputBuffer = [MIContext createBufferWithLength:sizeof(vector_float3)];
        
        [self setRedMin:0.0 gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
        [self setGreenMin:1.0 gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
        [self setBlueMin:1.0 gamma:2.0 max:1.0 minOut:0.0 maxOut:1.0];
    }
    return self;
}

- (void)updateBuffers {
    vector_float3 *mins = _minBuffer.contents;
    mins[0] = _minVector;
    
    vector_float3 *mids = _midBuffer.contents;
    mids[0] = _midVector;
    
    vector_float3 *maxs = _maxBuffer.contents;
    maxs[0] = _maxVector;
    
    vector_float3 *minOutputs = _minOutputBuffer.contents;
    minOutputs[0] = _minOutputVector;
    
    vector_float3 *maxOutputs = _maxOutputBuffer.contents;
    maxOutputs[0] = _maxOutputVector;
}

- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder {
    [super setVertexFragmentBufferOrTexture:commandEncoder];
    
    [commandEncoder setFragmentBuffer:_minBuffer offset:0 atIndex:0];
    [commandEncoder setFragmentBuffer:_midBuffer offset:0 atIndex:1];
    [commandEncoder setFragmentBuffer:_maxBuffer offset:0 atIndex:2];
    [commandEncoder setFragmentBuffer:_minOutputBuffer offset:0 atIndex:3];
    [commandEncoder setFragmentBuffer:_maxOutputBuffer offset:0 atIndex:4];
    
}

- (void)setMin:(float)min gamma:(float)mid max:(float)max minOut:(float)minOut maxOut:(float)maxOut {
    [self setRedMin:min gamma:mid max:max minOut:minOut maxOut:maxOut];
    [self setGreenMin:min gamma:mid max:max minOut:minOut maxOut:maxOut];
    [self setBlueMin:min gamma:mid max:max minOut:minOut maxOut:maxOut];
}

- (void)setMin:(float)min gamma:(float)mid max:(float)max {
    [self setMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (void)setRedMin:(float)min gamma:(float)mid max:(float)max minOut:(float)minOut maxOut:(float)maxOut {
    _minVector.r = min;
    _midVector.r = mid;
    _maxVector.r = max;
    _minOutputVector.r = minOut;
    _maxOutputVector.r = maxOut;
    
    [self updateBuffers];
}

- (void)setRedMin:(float)min gamma:(float)mid max:(float)max {
    [self setRedMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (void)setGreenMin:(float)min gamma:(float)mid max:(float)max minOut:(float)minOut maxOut:(float)maxOut {
    _minVector.g = min;
    _midVector.g = mid;
    _maxVector.g = max;
    _minOutputVector.g = minOut;
    _maxOutputVector.g = maxOut;
    
    [self updateBuffers];
}

- (void)setGreenMin:(float)min gamma:(float)mid max:(float)max {
    [self setGreenMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

- (void)setBlueMin:(float)min gamma:(float)mid max:(float)max minOut:(float)minOut maxOut:(float)maxOut {
    _minVector.b = min;
    _midVector.b = mid;
    _maxVector.b = max;
    _minOutputVector.b = minOut;
    _maxOutputVector.b = maxOut;
    
    [self updateBuffers];
}

- (void)setBlueMin:(float)min gamma:(float)mid max:(float)max {
    [self setBlueMin:min gamma:mid max:max minOut:0.0 maxOut:1.0];
}

+ (NSString *)fragmentShaderFunction {
    NSString *fFunction = @"MILevelsFragmentShader";
    return fFunction;
}

@end
