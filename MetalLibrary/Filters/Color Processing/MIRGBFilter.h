//
//  MISolarizeFilter.h
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIFilter.h"

@interface MIRGBFilter : MIFilter
{
    id<MTLBuffer> _redBuffer;
    id<MTLBuffer> _greenBuffer;
    id<MTLBuffer> _blueBuffer;
}
// Normalized values by which each color channel is multiplied. The range is from 0.0 up, with 1.0 as the default.
@property  (nonatomic) float red;
@property  (nonatomic) float green;
@property  (nonatomic) float blue;

@end

