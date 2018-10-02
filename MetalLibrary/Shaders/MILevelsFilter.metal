//
//  MIContrastFilter.metal
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#include "MIMetalShaderHeader.h"

float3 levelsControlInputRange (float3 color, float3 minInput, float3 maxInput) {
    return min(max(color - minInput, float3(0.0)) / (maxInput - minInput), float3(1.0));
}

float3 levelsControlInput (float3 color, float3 minInput, float3 gamma,float3 maxInput) {
    float3 inputRange = levelsControlInputRange(color, minInput, maxInput);
    return  pow(inputRange, 1.0 / gamma);
}

float3 levelsControlOutputRange (float3 color, float3 minOutput, float3 maxOutput) {
    return mix(minOutput, maxOutput, color);
}

float3 levelsControl (float3 color, float3 minInput, float3 gamma, float3 maxInput, float3 minOutput, float3 maxOutput) {
    float3 inputRange = levelsControlInput(color, minInput, gamma, maxInput);
    return levelsControlOutputRange(inputRange, minOutput, maxOutput);
}

fragment float4 MILevelsFragmentShader(MIDefaultVertexData in [[stage_in]],
                                       texture2d<float> colorTexture [[ texture(0) ]],
                                       constant float3 *levelMinimums [[buffer(0)]],
                                       constant float3 *levelMiddles [[buffer(1)]],
                                       constant float3 *levelMaximums [[buffer(2)]],
                                       constant float3 *minOutputs [[buffer(3)]],
                                       constant float3 *maxOutputs [[buffer(4)]]) {
    constexpr sampler sourceImage (mag_filter::linear, min_filter::linear);
    float3 levelMinimum = levelMinimums[0];
    float3 levelMiddle = levelMiddles[0];
    float3 levelMaximum = levelMaximums[0];
    float3 minOutput = minOutputs[0];
    float3 maxOutput = maxOutputs[0];
    
    float4 textureColor = colorTexture.sample (sourceImage, in.textureCoordinate);
    
    float3 levelsColor = levelsControl(textureColor.rgb, levelMinimum, levelMiddle, levelMaximum, minOutput, maxOutput);
    
    float4 outputColor = float4(levelsColor, textureColor.a);
    return outputColor;
}


