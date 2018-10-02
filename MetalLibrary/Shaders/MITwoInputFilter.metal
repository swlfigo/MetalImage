//
//  MIDefaultFilter.metal
//  MetalImage
//
//  Created by Sylar on 2018/9/29.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#include "MIMetalShaderHeader.h"

vertex MITwoInputVertexData MITwoInputVertexShader(uint vertexID [[vertex_id]],
                                                   constant float4 *position [[buffer(0)]],
                                                   constant float2 *textureCoordinate [[buffer(1)]],
                                                   constant float2 *secondTextureCoordinate [[buffer(2)]]) {
    MITwoInputVertexData out;
    
    float4 pixelSpacePosition = position[vertexID];
    float2 uv = textureCoordinate[vertexID];
    float2 secondUV = textureCoordinate[vertexID];
    
    out.position = pixelSpacePosition;
    out.textureCoordinate = uv;
    out.secondTextureCoordinate = secondUV;
    
    return out;
}

fragment half4 MITwoInputFragmentShader(MITwoInputVertexData in [[stage_in]],
                                        texture2d<half> inputTexture [[ texture(0) ]],
                                        texture2d<half> secondTexture [[ texture(1) ]]) {
    constexpr sampler inputSampler (mag_filter::linear, min_filter::linear);
    
    half4 outputColor = inputTexture.sample (inputSampler, in.textureCoordinate);
    half4 secondoutputColor = secondTexture.sample (inputSampler, in.secondTextureCoordinate);
    
    outputColor = mix(outputColor, secondoutputColor, 0.5h);
    
    return outputColor;
}
