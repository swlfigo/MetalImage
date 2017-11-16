//
//  MetalVideoCaptor.m
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalVideoCaptor.h"



@implementation MetalVideoCaptor
{
    //AVSession
    AVCaptureSession*               _captureSession;
    id <MTLDevice>                  videoDevice;
    AVCaptureDevice *videoCaptureDevice;
    AVCaptureDeviceInput   *videoInput;
    AVCaptureVideoDataOutput * dataOutput;
    CVMetalTextureCacheRef          videoTextureCache;
    dispatch_queue_t                cameraQueue;
    
    MetalProgram                    *cameraProgram;
    MetalImageRotationMode          cameraInputRotation;
    MetalImageRotationMode          outputTextureRotation;
    int                             videoWidth;
    int                             videoHeight;
    __block dispatch_semaphore_t _inflight_semaphore;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        _inflight_semaphore = dispatch_semaphore_create(3);
        cameraProgram =  [[MetalProgram alloc]initWithVertexShaderName:@"defaultShaderVertex"  fragmentShaderName:@"defaultShaderFragment"];
        cameraInputRotation = kMetalImageRotateRightFlipHorizontal;
        
        videoWidth =  videoHeight = 0;
        videoTextureCache = nil;
        videoDevice = [MetalContext defaultContext].device;
        [self setupVideo];
    }
    return self;
}


-(void)setupVideo
{
    CVMetalTextureCacheFlush(videoTextureCache, 0);
    CVReturn textCachRes = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, videoDevice, NULL, &videoTextureCache);
    if(textCachRes)
    {
        NSLog(@"ERROR: Can not create a video texture cache!!! ");
        assert(0);
    }
    
    //init a video capture session
    _captureSession     = [[AVCaptureSession alloc] init];
    if (!_captureSession)
    {
        NSLog(@"Can not create a video capture session!!!");
        assert(0);
    }
    
    videoCaptureDevice  = nil;
    NSArray* deviceArr = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice* device  in deviceArr)
    {
        if ([device position] == AVCaptureDevicePositionBack)
        {
            videoCaptureDevice  = device;
        }
    }
    
    if (videoCaptureDevice == nil)
    {
        videoCaptureDevice     = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    if (videoCaptureDevice == nil)
    {
        NSLog(@">>>>>>>>>>Error: Can not create a video capture device!!!");
        assert(0);
    }
    
    [_captureSession beginConfiguration];
    [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    
    
    
    //create video input with owned device
    NSError  *videoErr = nil;
    videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&videoErr];
    if (videoErr)
    {
        NSLog(@">> ERROR: Couldnt create AVCaptureDeviceInput");
        assert(0);
    }
    if ([_captureSession canAddInput:videoInput]) {
        [_captureSession addInput:videoInput];
    }else{
        NSLog(@"Can't not add VideoInput");
    }
    
    ///create video output for process image
    dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    // Set the color space.
    [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    // Set dispatch to be on the main thread to create the texture in memory and allow Metal to use it for rendering
    cameraQueue = dispatch_queue_create("com.MetalImage.cameraQueue", NULL);
    [dataOutput setSampleBufferDelegate:self queue:cameraQueue];
    
    if ([_captureSession canAddOutput:dataOutput]) {
        [_captureSession addOutput:dataOutput];
    }else{
        NSLog(@"Can't not add VideoOutput");
    }
    
    [_captureSession commitConfiguration];

}



///samplebuffer delegate func
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVReturn error;
    
    CVImageBufferRef sourceImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(sourceImageBuffer);
    size_t height = CVPixelBufferGetHeight(sourceImageBuffer);
    
    __block CVMetalTextureRef textureRef;
    error = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, videoTextureCache, sourceImageBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &textureRef);
    
    if (error)
    {
        NSLog(@">> ERROR: Couldnt create texture from image");
        assert(0);
    }
    
    @autoreleasepool{
        outputTexture = [[MetalTexture alloc]initWithTexturePixelFormat:MTLPixelFormatBGRA8Unorm TextureWidth:(uint32_t)height TextureHeight:(uint32_t)width];
        
        
        MetalTexture *cameraTexture = [[MetalTexture alloc]initWithTexturePixelFormat:MTLPixelFormatBGRA8Unorm TextureWidth:(uint32_t)width TextureHeight:(uint32_t)height];
        cameraTexture.texture = CVMetalTextureGetTexture(textureRef);
        cameraTexture.orientation = cameraInputRotation;
        
        
        MTLRenderPassDescriptor *renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
        MTLRenderPassColorAttachmentDescriptor    *colorAttachment  = renderPassDescriptor.colorAttachments[0];
        colorAttachment.texture         = outputTexture.texture;
        colorAttachment.loadAction      = MTLLoadActionClear;
        colorAttachment.clearColor      = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);//black
        colorAttachment.storeAction     = MTLStoreActionStore;
        [cameraProgram setupProgramRenderPassDescriptor:renderPassDescriptor];
        
        
        dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
        
        id<MTLCommandBuffer> commandBuffer = [[MetalContext defaultContext].commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:cameraProgram.renderPassDescriptor];
        [commandEncoder pushDebugGroup:@"Camera Encodequad"];
        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [commandEncoder setRenderPipelineState:cameraProgram.renderPipelineState];
        [commandEncoder setFragmentTexture: cameraTexture.texture atIndex:0];
        [commandEncoder setVertexBuffer:[self verticesBuffer]  offset:0  atIndex: 0 ];
        
        [commandEncoder setVertexBuffer:cameraTexture.textureCoordinate offset:0  atIndex: 1];
        
        
        // tell the render context we want to draw our primitives
        [commandEncoder drawPrimitives: MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
        
        [commandEncoder endEncoding];
        [commandEncoder popDebugGroup];
        
        __weak typeof(self)weakSelf = self;
        [commandBuffer addCompletedHandler:^(id <MTLCommandBuffer> cmdb){
            NSLog(@"****************fresh another commderbuffer for display!!!********************");
            
            [weakSelf videoSampleBufferProcessing:kCMTimeZero];
            
            CVBufferRelease(textureRef);
            
            dispatch_semaphore_signal(_inflight_semaphore);
            
        }];
        [commandBuffer commit];
    }
    
    
    
    
    /*
    outputTexture = [[MetalTexture alloc]initWithTexturePixelFormat:MTLPixelFormatBGRA8Unorm TextureWidth:(uint32_t)width TextureHeight:(uint32_t)height];
    
    outputTexture.texture = CVMetalTextureGetTexture(textureRef);
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    
    if (!outputTexture)
    {
        NSLog(@">> ERROR: Couldn't get texture from texture ref");
        assert(0);
    }
    [self videoSampleBufferProcessing:currentTime];
    
    CVBufferRelease(textureRef);
    */
}


-(void)videoSampleBufferProcessing:(CMTime)frameTime
{
    //生成纹理给下一级
    [self produceAtTime];

}

-(void)produceAtTime{
    
    [MetalContext performSynchronouslyOnImageProcessingQueue:^{
        if (outputTexture && [consumers count]) {
            for (id <MetalConsumer> consumer in consumers) {
                [consumer setInputTexture:outputTexture];
//                [consumer setTextureOrien:kMetalImageFlipVertical];
                [consumer render];
            }
        }
    }];
    
}


- (void)startRunning
{
    [_captureSession startRunning];
    
}

- (void)stopRunning
{
    if ([_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
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
    verticesBuffer.label = @"Camera Quad vertices";
    return verticesBuffer;
}

@end
