//
//  MetalProgram.h
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MetalImageRenderType){
    MetalImageRenderFunctionType,   //ComputeFunciton
    MetalImageComputeFunctionType,  //RenderFunction
    
};


@interface MetalProgram : NSObject

//使用ComputePipleLine -> 不使用 RenderPipeLine
//Compute方法
@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;

//Compute Function
@property (nonatomic, strong) id<MTLFunction> kernelFunction;

//Compute Function中的运算组大小
@property (nonatomic,assign) MTLSize threadGroupSize;
@property (nonatomic,assign) MTLSize threadGroupCount;

//Compute渲染读取Metal shader 名字
-(instancetype)initWithFunctionName:(NSString *)functionName;




//使用MTLRenderPipelineState -> 不使用 ComputePipleLine
//Render方法
/*
 
 //渲染过程描述，该描述用来说明Metal在执行渲染前后所需要得操作。如下面代码，我们描述的一个渲染过程首先会将帧缓存清空成一个白色固体，然后执行绘制操作，最后将结果存储到帧缓存中用来展示：
 
 MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
 renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
 renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
 renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);
 renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
 
 */

@property(nonatomic,strong,readonly)MTLRenderPassDescriptor* renderPassDescriptor;


/*
 
 // MTLRenderPipelineState 对象来定义每个绘制命令的图形状态
 
 // 创建一个渲染管线 state 需要一个耗时的图形状态诊断并且可能伴随特定的着色程序编译
 
 //用于储存着色器
 */
@property(readonly, nonatomic)id <MTLRenderPipelineState>  renderPipelineState;


/*
 
 //为了使用 MTLRenderCommandEncoder 对象来编码渲染指令，必须先设置一个 MTLRenderPipelineState 对象来定义每个绘制命令的图形状态。一个渲染管线 state 对象是一个拥有长生命周期的对象，它可以在 render command encoder 对象生效范围外被创建，最后可以被缓存起来，然后被重用于多个 render command encoder 对象。当描述相同的图形状态，重用先前创建的渲染管线 state 对象，这样可以避免高成本的重新评估和转换操作（将特定状态转换成 GPU 指令）。
 
 */
@property(readonly,nonatomic)MTLRenderPipelineDescriptor *renderPipelineStateDescriptor;




//读取Metal shader 名字
- (id)initWithVertexShaderName:(NSString *)vShaderName fragmentShaderName:(NSString *)fShaderName;


//设置Program的 MTLRenderPassDescriptor
- (void)setupProgramRenderPassDescriptor:(MTLRenderPassDescriptor*)renderPassDescriptor;


@property(nonatomic,readonly)MetalImageRenderType renderType;
@end
