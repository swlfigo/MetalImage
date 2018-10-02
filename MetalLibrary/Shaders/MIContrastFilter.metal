//
//  MIContrastFilter.metal
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#include "MIMetalShaderHeader.h"

fragment float4 MIContrastFragmentShader(MIDefaultVertexData in [[stage_in]],
                                         texture2d<float> colorTexture [[ texture(0) ]],
                                         constant float *contrasts [[buffer(0)]])
{
    constexpr sampler sourceImage (mag_filter::linear, min_filter::linear);
    
    float contrast = contrasts[0];
    
    float4 textureColor = colorTexture.sample (sourceImage, in.textureCoordinate);
    textureColor = float4(textureColor.rgb - float3(0.5) * contrast + float3(0.5), textureColor.w);
    return textureColor;
}
