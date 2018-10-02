//
//  MISaturationFilter.h
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIFilter.h"

@interface MISaturationFilter : MIFilter

{
    id<MTLBuffer> _saturationBuffer;
}

/** Saturation ranges from 0.0 (fully desaturated) to 2.0 (max saturation), with 1.0 as the normal level
 */
@property (nonatomic) float saturation;

@end
