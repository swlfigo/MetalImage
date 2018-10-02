//
//  MISaturationFilter.metal
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#include "MIMetalShaderHeader.h"

//饱和度
fragment half4 MISaturationFragmentShader(MIDefaultVertexData in [[stage_in]],
                                          texture2d<half> colorTexture [[ texture(0) ]],
                                          constant float *saturations [[buffer(0)]])
{
    constexpr sampler sourceImage (mag_filter::linear, min_filter::linear);
    
    half saturation = saturations[0];
    
    half4 textureColor = colorTexture.sample (sourceImage, in.textureCoordinate);
    
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    half3 greyScaleColor = half3(luminance);
    
    
    textureColor = half4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
    return textureColor;
}
