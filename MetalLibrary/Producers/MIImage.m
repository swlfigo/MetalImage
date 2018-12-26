//
//  MIImage.m
//  MetalImage
//
//  Created by Sylar on 2018/12/26.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIImage.h"
#import "MITexture.h"
#import "MIContext.h"
@implementation MIImage

- (instancetype)initWithUIImage:(UIImage *)image {
    if (self = [self init]) {
        self.sourceImage = image;
    }
    return self;
}

- (void)setSourceImage:(UIImage *)sourceImage {
    if (_sourceImage != sourceImage) {
        _sourceImage = sourceImage;
        _outputTexture = [[MITexture alloc] initWithUIImage:_sourceImage];
        self.outputFrame = CGRectMake(0, 0, _outputTexture.size.width, _outputTexture.size.height);
    }
}

- (void)processingImage{
    id<MTLCommandBuffer> commandBuffer = [[MIContext defaultContext].commandQueue commandBuffer];
    commandBuffer.label = @"MIImage";
    [self produceAtTime:kCMTimeInvalid commandBuffer:commandBuffer];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

@end
