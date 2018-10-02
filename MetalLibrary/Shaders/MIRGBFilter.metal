//
//  MIContrastFilter.metal
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#include "MIMetalShaderHeader.h"


fragment float4 MIRGBFragmentShader(MIDefaultVertexData in [[stage_in]],
                                    texture2d<float> colorTexture [[ texture(0) ]],
                                    constant float *redAdjustments [[buffer(0)]],
                                    constant float *greenAdjustments [[buffer(1)]],
                                    constant float *blueAdjustments [[buffer(2)]])
{
    constexpr sampler sourceImage (mag_filter::linear, min_filter::linear);
    
    float redAdjustment = redAdjustments[0];
    float greenAdjustment = greenAdjustments[0];
    float blueAdjustment = blueAdjustments[0];
    
    float4 textureColor = colorTexture.sample (sourceImage, in.textureCoordinate);
    float4 outputColor = float4(textureColor.r * redAdjustment, textureColor.g * greenAdjustment, textureColor.b * blueAdjustment, textureColor.a);

    return outputColor;
}
