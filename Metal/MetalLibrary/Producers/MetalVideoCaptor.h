//
//  MetalVideoCaptor.h
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalProducer.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>
#import <CoreVideo/CVMetalTextureCache.h>


@interface MetalVideoCaptor : MetalProducer<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    
}



//开镜头
- (void)startRunning;
//关镜头
- (void)stopRunning;

@end
