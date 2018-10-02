//
//  MISolarizeFilter.h
//  MetalImage
//
//  Created by Sylar on 2018/10/2.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIFilter.h"

@interface MILevelsFilter : MIFilter
{
    id<MTLBuffer> _minBuffer;
    id<MTLBuffer> _midBuffer;
    id<MTLBuffer> _maxBuffer;
    id<MTLBuffer> _minOutputBuffer;
    id<MTLBuffer> _maxOutputBuffer;
    
    vector_float3 _minVector;
    vector_float3 _midVector;
    vector_float3 _maxVector;
    vector_float3 _minOutputVector;
    vector_float3 _maxOutputVector;
}


/** Set levels for the red channel */
- (void)setRedMin:(float)min gamma:(float)mid max:(float)max minOut:(float)minOut maxOut:(float)maxOut;

- (void)setRedMin:(float)min gamma:(float)mid max:(float)max;

/** Set levels for the green channel */
- (void)setGreenMin:(float)min gamma:(float)mid max:(float)max minOut:(float)minOut maxOut:(float)maxOut;

- (void)setGreenMin:(float)min gamma:(float)mid max:(float)max;

/** Set levels for the blue channel */
- (void)setBlueMin:(float)min gamma:(float)mid max:(float)max minOut:(float)minOut maxOut:(float)maxOut;

- (void)setBlueMin:(float)min gamma:(float)mid max:(float)max;

/** Set levels for all channels at once */
- (void)setMin:(float)min gamma:(float)mid max:(float)max minOut:(float)minOut maxOut:(float)maxOut;
- (void)setMin:(float)min gamma:(float)mid max:(float)max;


@end
