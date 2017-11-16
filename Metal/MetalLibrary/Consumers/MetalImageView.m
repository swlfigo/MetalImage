//
//  MetalImageView.m
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalImageView.h"

@implementation MetalImageView
{
@private
    __weak  CAMetalLayer *_metalLayer;
    BOOL _layerSizeDidUpdate;
    MetalProgram *filterProgram;
    MetalImageRotationMode inputRotation;
    MetalTexture *_inputTexture;
}

@synthesize currentDrawable         = _currentDrawable;

+(Class)layerClass
{
    return [CAMetalLayer class];
}

-(id)initWithFrame:(CGRect)frame
{
    self =  [super initWithFrame:frame];
    if (self )
    {
        [self initCommon];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self  = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initCommon];
    }
    return self;
}

-(void)initCommon
{
    filterProgram = [[MetalProgram alloc]initWithVertexShaderName:@"defaultShaderVertex"  fragmentShaderName:@"defaultShaderFragment"];
    self.opaque                     = YES;
    self.backgroundColor            = nil;
    _metalLayer                     = (CAMetalLayer*) self.layer;
    _metalLayer.device              = [MetalContext defaultContext].device;
    _metalLayer.pixelFormat         = MTLPixelFormatBGRA8Unorm;
    _metalLayer.framebufferOnly     = YES;

    //纹理方向
    inputRotation                   = kMetalImageFlipHorizonal;
    
}


//顶点坐标
-(id <MTLBuffer>)verticesBuffer{
    static const vector_float4 imageVertices[6] = {
        { -1.0f,  -1.0f, 0.0f, 1.0f },
        {  1.0f,  -1.0f, 0.0f, 1.0f },
        { -1.0f,   1.0f, 0.0f, 1.0f },
        
        {  1.0f,  -1.0f, 0.0f, 1.0f },
        { -1.0f,   1.0f, 0.0f, 1.0f },
        {  1.0f,   1.0f, 0.0f, 1.0f },
    };
    id<MTLDevice> device = [MetalContext defaultContext].device;
    
    id<MTLBuffer> verticesBuffer = [device newBufferWithBytes:imageVertices length:sizeof(imageVertices) options:MTLResourceOptionCPUCacheModeDefault];
    verticesBuffer.label = @"quad vertices";
    return verticesBuffer;
}


-(void)setInputTexture:(MetalTexture *)inputTexture{
    if (_inputTexture != inputTexture) {
        _inputTexture = nil ;
        _inputTexture = inputTexture;
    }
}

-(void)render{
    //绘制
    if (!_inputTexture) {
        return;
    }
    
    @autoreleasepool{
        if(_layerSizeDidUpdate)
        {
            // set the metal layer to the drawable size in case orientation or size changes
            CGSize drawableSize = self.bounds.size;
            drawableSize.width  *= self.contentScaleFactor;
            drawableSize.height *= self.contentScaleFactor;
            if (drawableSize.width == 0 || drawableSize.height == 0) {
                drawableSize.width = 1;
                drawableSize.height = 1;
            }
            _metalLayer.drawableSize = drawableSize;
            _layerSizeDidUpdate = NO;
        }
    }
    
    
    
    [self getRenderPassDescriptor];
    
    dispatch_semaphore_wait([MetalContext getSemaphore], DISPATCH_TIME_FOREVER);
    
    if (filterProgram.renderPassDescriptor) {
        id<MTLCommandBuffer> commandBuffer = [[MetalContext defaultContext].commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:filterProgram.renderPassDescriptor];
        [commandEncoder pushDebugGroup:@"encodequad"];
        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [commandEncoder setRenderPipelineState:filterProgram.renderPipelineState];
        [commandEncoder setFragmentTexture: _inputTexture.texture atIndex:0];
        [commandEncoder setVertexBuffer:[self verticesBuffer]  offset:0  atIndex: 0 ];
//        _inputTexture.orientation = kMetalImageRotateRightFlipHorizontal;
        [commandEncoder setVertexBuffer:_inputTexture.textureCoordinate offset:0  atIndex: 1];
        
        
        // tell the render context we want to draw our primitives
        [commandEncoder drawPrimitives: MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
        
        [commandEncoder endEncoding];
        [commandEncoder popDebugGroup];
        [commandBuffer presentDrawable:self.currentDrawable];
        __block dispatch_semaphore_t dispatchSemaphore = [MetalContext getSemaphore];
        [commandBuffer addCompletedHandler:^(id <MTLCommandBuffer> cmdb){
            NSLog(@"****************fresh another commderbuffer for display!!!********************");
            dispatch_semaphore_signal(dispatchSemaphore);
        }];
        [commandBuffer commit];
        _currentDrawable = nil;
    }
}


- (void)getRenderPassDescriptor{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    if(!drawable)
    {
        NSLog(@">> ERROR: Failed to get a drawable!");
        [filterProgram setupProgramRenderPassDescriptor: nil];
    }else{
        MTLRenderPassDescriptor *renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
        MTLRenderPassColorAttachmentDescriptor    *colorAttachment  = renderPassDescriptor.colorAttachments[0];
        colorAttachment.texture         = [drawable texture];
        colorAttachment.loadAction      = MTLLoadActionClear;
        colorAttachment.clearColor      = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);//black
        colorAttachment.storeAction     = MTLStoreActionStore;
        [filterProgram setupProgramRenderPassDescriptor:renderPassDescriptor];
    }
    
}

- (id <CAMetalDrawable>)currentDrawable
{
    if (_currentDrawable == nil)
        _currentDrawable = [_metalLayer nextDrawable];
    
    return _currentDrawable;
}

-(void)didMoveToWindow
{
    self.contentScaleFactor         = self.window.screen.nativeScale;
}
- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:contentScaleFactor];
    
    _layerSizeDidUpdate = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _layerSizeDidUpdate = YES;
}
@end
