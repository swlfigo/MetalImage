//
//  MetalTexture.h
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kMetalImageNoRotation,
    kMetalImageRotateLeft,
    kMetalImageRotateRight,
    kMetalImageFlipVertical,
    kMetalImageFlipHorizonal,
    kMetalImageRotateRightFlipVertical,
    kMetalImageRotateRightFlipHorizontal,
    kMetalImageRotate180
} MetalImageRotationMode;


@interface MetalTexture : NSObject

- (instancetype)initWithInputImage:(UIImage *)image;

//Default: mipmapped = NO;
- (instancetype)initWithTexturePixelFormat:(MTLPixelFormat)pixelFormat TextureWidth:(NSUInteger)width TextureHeight:(NSUInteger)height;

//获取当前纹理的图片
- (UIImage *)imageFromCurrentTexture;

//纹理生成图片
+ (UIImage *)imageWithMTLTexture:(id<MTLTexture>)texture;


//纹理
@property (nonatomic, strong) id<MTLTexture> texture;

//Size
@property(readonly,nonatomic)CGSize size;

//纹理方向
@property(nonatomic,readwrite)MetalImageRotationMode orientation;

//Orien Buffer
+(id <MTLBuffer>)textureOrien:(MetalImageRotationMode)rotationMode;

//
//返回纹理坐标 Buffer
-(id <MTLBuffer>)textureCoordinate;

@end
