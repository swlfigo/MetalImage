//
//  MetalGaussianFilter.m
//  Metal
//
//  Created by Sylar on 2017/10/23.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalGaussianFilter.h"

//需要跑2次Kernel Function
@interface MetalGaussianFilter(){
    id <MTLTexture>             blurWeightTexture;
    id <MTLTexture>             weightsTexture;
    int                         _blurRadius;
    id <MTLComputePipelineState> vertical_Caculatepipeline;
    MetalTexture*          TempoutputTexture;
}
@property (nonatomic, assign) float sigma;  // Default value 0.0
@end


@implementation MetalGaussianFilter

-(instancetype)initWithMetalRenderType:(MetalImageRenderType)renderType{
    //此滤镜只能通过ComputeFunction初始化
    if (self = [super initWithMetalRenderType:MetalImageComputeFunctionType]) {
        self.radius  =  4.0;
        self.sigma   =  self.radius / 2.0;
        _blurRadius  = round(self.radius);
        [self createGaussianWeightsTexture];
        
        //垂直纹理
        TempoutputTexture = nil;
        id <MTLFunction> caculateFuncHoz   = [[MetalContext defaultContext].library newFunctionWithName:@"gaussian_BlurVertical"];
        NSError *pError = nil;
        vertical_Caculatepipeline  = [[MetalContext defaultContext].device newComputePipelineStateWithFunction:caculateFuncHoz error:&pError];
    }
    return self;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.radius  =  4.0;
        self.sigma   =  self.radius / 2.0;
        _blurRadius  = round(self.radius);
        [self createGaussianWeightsTexture];
        
        //垂直纹理
        TempoutputTexture = nil;
        id <MTLFunction> caculateFuncHoz   = [[MetalContext defaultContext].library newFunctionWithName:@"gaussian_BlurVertical"];
        NSError *pError = nil;
        vertical_Caculatepipeline  = [[MetalContext defaultContext].device newComputePipelineStateWithFunction:caculateFuncHoz error:&pError];
    }
    return self;
}

//Kernerl Function
+(NSString *)functionName{
    static NSString *fName = @"gaussian_BlurHorizontal";
    return fName;
}


-(void)setRadius:(float)radius{
    [MetalContext performSynchronouslyOnImageProcessingQueue:^{
        _radius = radius;
        _sigma = _radius / 2.0f;
        _blurRadius = round(radius);
        [self createGaussianWeightsTexture];
    }];
    
}


//创建一个权重纹理
-(void)createGaussianWeightsTexture
{
    
    float *standardGaussianWeights = (float*)malloc((_blurRadius + 1)*sizeof(float));
    float sumOfWeights = 0.0;
    for (int  currentGaussianWeightIndex = 0; currentGaussianWeightIndex < _blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(_sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(_sigma, 2.0)));
        
        if (currentGaussianWeightIndex == 0)
        {
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        }
        else
        {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }
    
    // Next, normalize these weights to prevent the clipping of the Gaussian curve at the end of the discrete samples from reducing luminance
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < _blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }

    MTLTextureDescriptor *text1DDescriptor = [[MTLTextureDescriptor alloc] init];
    text1DDescriptor.textureType = MTLTextureType1D;
    text1DDescriptor.pixelFormat = MTLPixelFormatR32Float;
    text1DDescriptor.width       = _blurRadius + 1;
    text1DDescriptor.height      = 1;
    text1DDescriptor.depth       = 1;
    weightsTexture  = [[MetalContext defaultContext].device newTextureWithDescriptor:text1DDescriptor];
    MTLRegion regionw = MTLRegionMake1D(0, _blurRadius + 1);
    [weightsTexture replaceRegion:regionw mipmapLevel:0 withBytes:standardGaussianWeights bytesPerRow:sizeof(float)*(_blurRadius + 1)];
    
}


-(void)render{
    //绘制
    if (!_inputTexture) {
        return;
    }
    
    //Compute渲染
    if (!outputTexture && !CGSizeEqualToSize(outputTexture.size, _inputTexture.size)) {
        
        //生成输出纹理
        outputTexture = [[MetalTexture alloc]initWithTexturePixelFormat:MTLPixelFormatBGRA8Unorm TextureWidth:[_inputTexture.texture width] TextureHeight:[_inputTexture.texture height]];
    }
    
    if (!TempoutputTexture && !CGSizeEqualToSize(TempoutputTexture.size, _inputTexture.size)) {
        
        //生成输出纹理
        TempoutputTexture = [[MetalTexture alloc]initWithTexturePixelFormat:MTLPixelFormatBGRA8Unorm TextureWidth:[_inputTexture.texture width] TextureHeight:[_inputTexture.texture height]];
    }
    
    //new output texture for next filter
    if (filterProgram.threadGroupSize.width == 0 || filterProgram.threadGroupSize.height == 0 || filterProgram.threadGroupCount.depth == 0) {
        
        NSInteger w = filterProgram.computePipeline.threadExecutionWidth;
        NSInteger h = filterProgram.computePipeline.maxTotalThreadsPerThreadgroup / w;
        filterProgram.threadGroupSize = MTLSizeMake(w, h, 1);
        
    }
    
    //calculate compute kenel's width and height
    NSUInteger nthreadWidthSteps  = (_inputTexture.size.width + filterProgram.threadGroupSize.width - 1) / filterProgram.threadGroupSize.width;
    NSUInteger nthreadHeightSteps = (_inputTexture.size.height + filterProgram.threadGroupSize.height - 1 )/ filterProgram.threadGroupSize.height;
    
    filterProgram.threadGroupCount = MTLSizeMake(nthreadWidthSteps, nthreadHeightSteps, 1);
    
    
    
    if (weightsTexture) {
        
        
        id<MTLCommandBuffer> commandBuffer = [[MetalContext defaultContext].commandQueue commandBuffer];
        
        id<MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    
    
        //水平
        [commandEncoder setComputePipelineState:filterProgram.computePipeline];
        [commandEncoder setTexture: _inputTexture.texture atIndex:0];
        [commandEncoder setTexture: TempoutputTexture.texture atIndex:1];
        [commandEncoder setTexture: weightsTexture atIndex:2];
        [commandEncoder dispatchThreadgroups:filterProgram.threadGroupCount threadsPerThreadgroup:filterProgram.threadGroupSize];
        [commandEncoder endEncoding];
        
        
        //垂直
        id<MTLComputeCommandEncoder> commandEncoderV = [commandBuffer computeCommandEncoder];
        [commandEncoderV  setComputePipelineState:vertical_Caculatepipeline];
        [commandEncoderV setTexture: TempoutputTexture.texture atIndex:0];
        [commandEncoderV setTexture: outputTexture.texture atIndex:1];
        [commandEncoderV setTexture: weightsTexture atIndex:2];
        [commandEncoderV dispatchThreadgroups:filterProgram.threadGroupCount threadsPerThreadgroup:filterProgram.threadGroupSize];
        [commandEncoderV endEncoding];
        
        [commandBuffer commit];
        
        [self produceAtTime];
    }
    else{
        NSLog(@"MetalGasussianFilter WightTexture is Nil!");
    }
    
   
}

@end
