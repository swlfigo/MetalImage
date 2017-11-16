//
//  MetalGaussianShader.metal
//  Metal
//
//  Created by Sylar on 2017/10/23.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


//////////////////////////Optimize Gaussian algorithm with two pass/////////////////////////
kernel void gaussian_BlurHorizontal(texture2d<float, access::read>  inTexture [[texture(0)]],
                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                    texture1d<float, access::sample> weights [[texture(2)]],
                                    uint2                           gid [[thread_position_in_grid]])
{
    int size = weights.get_width()*2 - 1;
    int radius = weights.get_width() - 1;
    
    float4 xColor(0.0, 0.0, 0.0, 0.0);
    
    for (int i = 0; i < size; ++i)
    {
        // uint    widthOffset = radius*2 + 1;
        uint2   textureIndex(gid.x + (i - radius)*radius, gid.y);
        float4  color = inTexture.read(textureIndex).rgba;
        int   xindx = abs(i - radius);
        float  weight = weights.read(xindx).x;
        xColor  += float4(weight)*color;
    }
    //xColor = xColor/(float)size;
    outTexture.write(float4(xColor.rgb, 1), gid);
}

kernel void gaussian_BlurVertical(texture2d<float, access::read>  inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  texture1d<float, access::sample> weights [[texture(2)]],
                                  uint2                           gid [[thread_position_in_grid]])
{
    int size = weights.get_width()*2 - 1;
    int radius = weights.get_width() - 1;
    
    float4 yColor(0.0, 0.0, 0.0, 0.0);
    
    for (int j = 0; j < size; ++j)
    {
        //  uint    heightOffset = radius*2 + 1;
        uint2 textureIndex(gid.x , gid.y + (j - radius)*radius);
        float4 color = inTexture.read(textureIndex).rgba;
        int   yindx = abs(j - radius);
        float weight = weights.read(yindx).x;
        yColor +=  float4(weight)*color;
    }
    //yColor = yColor/(float)size;
    outTexture.write(float4(yColor.rgb, 1), gid);
}




