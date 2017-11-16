//
//  DefaultShader.metal
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//Kernel Function Shader
kernel void defaultFunction(texture2d<float, access::write> outTexture [[texture(0)]],
                            texture2d<float, access::read> inTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    outTexture.write(inColor, gid);
}



struct VertexInOut
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

vertex VertexInOut defaultShaderVertex(constant float4         *pPosition[[ buffer(0) ]],
                                       constant packed_float2  *pTexCoords[[ buffer(1) ]],
                                       uint                     vid[[ vertex_id ]]        )
{
    VertexInOut outVertices;
    
    outVertices.m_Position =  pPosition[vid];
    outVertices.m_TexCoord =  pTexCoords[vid];
    
    return outVertices;
}

fragment half4 defaultShaderFragment(VertexInOut inFrag[[ stage_in ]], texture2d<half> tex2D[[ texture(0) ]])
{
    constexpr sampler qsampler;
    
    half4 color = tex2D.sample(qsampler, inFrag.m_TexCoord);//half4(r, 0.0, 0.0, 1.0);
    
    return color;
}
