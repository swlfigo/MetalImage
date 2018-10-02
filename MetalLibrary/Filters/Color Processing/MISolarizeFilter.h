//
//  MISolarizeFilter.h
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIFilter.h"

@interface MISolarizeFilter : MIFilter

{
    id<MTLBuffer> _thresholdBuffer;
}

@property (nonatomic) float threshold;

@end
