//
//  MIContrastFilter.metal
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#include "MIMetalShaderHeader.h"

fragment half4 MILuminanceThresholdFragmentShader(MIDefaultVertexData in [[stage_in]],
                                                   texture2d<half> colorTexture [[texture(0)]],
                                                   constant float *thresholds [[buffer(0)]])
{
    constexpr sampler sourceImage (mag_filter::linear, min_filter::linear);
    
    half threshold = thresholds[0];
    
    half4 textureColor = colorTexture.sample (sourceImage, in.textureCoordinate);
    
    half luminance = dot(textureColor.rgb, luminanceWeighting);
    float thresholdResult = step(threshold, luminance);

    textureColor = half4(half3(thresholdResult), textureColor.w);
    return textureColor;
}
