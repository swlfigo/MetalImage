//
//  MetalImageFilters.h
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalProducer.h"

@interface MetalImageFilter : MetalProducer<MetalConsumer>
{
    MetalProgram *filterProgram;
    MetalTexture *_inputTexture;
    MetalImageRotationMode orien_;
}


//用于ComputeFunction的参数 ComputeFunction Kernel
+(NSString *)functionName;

//用于RenderFunction的参数
+ (NSString *)vertexShaderName;
+ (NSString *)fragmentShaderName;

//顶点坐标
-(id <MTLBuffer>)verticesBuffer;

//着色器数据
-(NSArray*)filterParam;

//纹理数据
-(NSArray<MetalTexture*>*)textureParam;

-(instancetype)initWithMetalRenderType:(MetalImageRenderType)renderType;


@end
