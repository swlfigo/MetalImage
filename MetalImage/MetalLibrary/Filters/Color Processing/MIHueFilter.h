//
//  MIHueFilter.h
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIFilter.h"

@interface MIHueFilter : MIFilter
{
    id<MTLBuffer> _hueAdjustBuffer;
}

@property (nonatomic) float hue;

@end
