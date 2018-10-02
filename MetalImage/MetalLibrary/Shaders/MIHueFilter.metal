//
//  MIHueFilter.metal
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#include "MIMetalShaderHeader.h"

constant float4  kRGBToYPrime = float4 (0.299, 0.587, 0.114, 0.0);
constant float4  kRGBToI      = float4 (0.595716, -0.274453, -0.321263, 0.0);
constant float4  kRGBToQ      = float4 (0.211456, -0.522591, 0.31135, 0.0);

constant float4  kYIQToR   = float4 (1.0, 0.9563, 0.6210, 0.0);
constant float4  kYIQToG   = float4 (1.0, -0.2721, -0.6474, 0.0);
constant float4  kYIQToB   = float4 (1.0, -1.1070, 1.7046, 0.0);

fragment float4 MIHueFragmentShader(MIDefaultVertexData in [[stage_in]],
                                    texture2d<float> colorTexture [[ texture(0) ]],
                                    constant float *hueAdjusts [[buffer(0)]])
{
    constexpr sampler sourceImage (mag_filter::linear, min_filter::linear);
    
    float hueAdjust = hueAdjusts[0];
    
    float4 color = colorTexture.sample (sourceImage, in.textureCoordinate);
    
    // Convert to YIQ
    float   YPrime  = dot (color, kRGBToYPrime);
    float   I      = dot (color, kRGBToI);
    float   Q      = dot (color, kRGBToQ);
    
    // Calculate the hue and chroma
    float   hue     = atan2 (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);
    
    // Make the user's adjustments
    hue += (-hueAdjust); //why negative rotation?
    
    // Convert back to YIQ
    Q = chroma * sin (hue);
    I = chroma * cos (hue);
    
    // Convert back to RGB
    float4    yIQ   = float4 (YPrime, I, Q, 0.0);
    color.r = dot (yIQ, kYIQToR);
    color.g = dot (yIQ, kYIQToG);
    color.b = dot (yIQ, kYIQToB);
    
    return color;
}


