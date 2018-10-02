//
//  MIDefaultFilter.metal
//  MetalImage
//
//  Created by Sylar on 2018/9/29.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#include "MIMetalShaderHeader.h"

vertex MIDefaultVertexData MIDefaultVertexShader(uint vertexID [[vertex_id]],
                                                 constant float4 *position [[buffer(0)]],
                                                 constant float2 *textureCoordinate [[buffer(1)]]) {
    MIDefaultVertexData out;
    
    float4 pixelSpacePosition = position[vertexID];
    float2 uv = textureCoordinate[vertexID];
    
    out.position = pixelSpacePosition;
    out.textureCoordinate = uv;
    
    return out;
}

fragment half4 MIDefaultFragmentShader(MIDefaultVertexData in [[stage_in]],
                                       texture2d<half> inputTexture [[ texture(0) ]]) {
    constexpr sampler inputSampler (mag_filter::linear, min_filter::linear);
    
    half4 outputColor = inputTexture.sample (inputSampler, in.textureCoordinate);
    return outputColor;
}
