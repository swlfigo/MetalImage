//
//  MetalTexture.m
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "MetalTexture.h"

@implementation MetalTexture

static void MBEReleaseDataCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}



- (instancetype)initWithInputImage:(UIImage *)image
{
    
    self = [self init];
    if (self) {
        _texture = [self textureForImage:image];
        if (_texture) {
            _size = CGSizeMake([_texture width], [_texture height]);
        }
        
    }
    return self;
}



-(instancetype)initWithTexturePixelFormat:(MTLPixelFormat)pixelFormat TextureWidth:(NSUInteger)width TextureHeight:(NSUInteger)height{
    self = [self init];
    if (self) {
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat
                                                                                                     width:width
                                                                                                    height:height
                                                                                                 mipmapped:NO];
        
        _texture = [[MetalContext defaultContext].device newTextureWithDescriptor:textureDescriptor];
        
        if (_texture) {
            _size = CGSizeMake([_texture width], [_texture height]);
            //默认纹理方向
            self.orientation = kMetalImageFlipVertical;
        }
        
    }
    return self;
}


- (id<MTLTexture>)textureForImage:(UIImage *)image
{
    CGImageRef imageRef = [image CGImage];
    
    // Create a suitable bitmap context for extracting the bits of the image
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef bitmapContext = CGBitmapContextCreate(rawData, width, height,
                                                       bitsPerComponent, bytesPerRow, colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    // Flip the context so the positive Y axis points down
    CGContextTranslateCTM(bitmapContext, 0, height);
    CGContextScaleCTM(bitmapContext, 1, -1);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(bitmapContext);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                                 width:width
                                                                                                height:height
                                                                                             mipmapped:NO];
    id<MTLTexture> texture = [[MetalContext defaultContext].device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    
    free(rawData);
    
    return texture;
}

-(UIImage *)imageFromCurrentTexture{
    return [MetalTexture imageWithMTLTexture:self.texture];
}

+ (UIImage *)imageWithMTLTexture:(id<MTLTexture>)texture
{
    //        NSAssert([texture pixelFormat] == MTLPixelFormatRGBA8Unorm, @"Pixel format of texture must be MTLPixelFormatBGRA8Unorm to create UIImage");
    
    CGSize imageSize = CGSizeMake([texture width], [texture height]);
    size_t imageByteCount = imageSize.width * imageSize.height * 4;
    void *imageBytes = malloc(imageByteCount);
    NSUInteger bytesPerRow = imageSize.width * 4;
    MTLRegion region = MTLRegionMake2D(0, 0, imageSize.width, imageSize.height);
    [texture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imageBytes, imageByteCount, MBEReleaseDataCallback);
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(imageSize.width,
                                        imageSize.height,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpaceRef,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        false,
                                        renderingIntent);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:UIImageOrientationDownMirrored];
    
    CFRelease(provider);
    CFRelease(colorSpaceRef);
    CFRelease(imageRef);
    
    return image;
}


+(id<MTLBuffer>)textureOrien:(MetalImageRotationMode)rotationMode{
    static const vector_float2 noRotationTextureCoordinates[] = {
        {0.0f, 0.0f},
        {1.0f, 0.0f},
        {0.0f, 1.0f},
        
        {1.0f, 0.0f},
        {0.0f, 1.0f},
        {1.0f, 1.0f}
    };
    
    static const vector_float2 rotateLeftTextureCoordinates[] = {
        {1.0f, 0.0f},
        {1.0f, 1.0f},
        {0.0f, 0.0f},
        
        {1.0f, 1.0f},
        {0.0f, 0.0f},
        {0.0f, 1.0f},
    };
    
    static const vector_float2 rotateRightTextureCoordinates[] = {
        {0.0f, 1.0f},
        {0.0f, 0.0f},
        {1.0f, 1.0f},
        
        {0.0f, 0.0f},
        {1.0f, 1.0f},
        {1.0f, 0.0f},
    };
    
    static const vector_float2 verticalFlipTextureCoordinates[] = {
        {0.0f, 1.0f},
        {1.0f, 1.0f},
        {0.0f, 0.0f},
        
        {1.0f,  1.0f},
        {0.0f,  0.0f},
        {1.0f,  0.0f},
    };
    
    static const vector_float2 horizontalFlipTextureCoordinates[] = {
        {1.0f,  0.0f},
        {0.0f,  0.0f},
        {1.0f,  1.0f},
        
        {0.0f,  0.0f},
        {1.0f,  1.0f},
        {0.0f,  1.0f},
    };
    
    static const vector_float2 rotateRightVerticalFlipTextureCoordinates[] = {
        {0.0f, 0.0f},
        {0.0f, 1.0f},
        {1.0f, 0.0f},
        
        {0.0f, 1.0f},
        {1.0f, 0.0f},
        {1.0f, 1.0f},
    };
    
    static const vector_float2 rotateRightHorizontalFlipTextureCoordinates[] = {
        {1.0f, 1.0f},
        {1.0f, 0.0f},
        {0.0f, 1.0f},
        
        {1.0f, 0.0f},
        {0.0f, 1.0f},
        {0.0f, 0.0f},
    };
    
    static const vector_float2 rotate180TextureCoordinates[] = {
        {1.0f, 1.0f},
        {0.0f, 1.0f},
        {1.0f, 0.0f},
        
        {0.0f, 1.0f},
        {1.0f, 0.0f},
        {0.0f, 0.0f},
    };
    
    id<MTLDevice> device = [MetalContext defaultContext].device;
    
    switch(rotationMode)
    {
        case kMetalImageNoRotation:
            return [device newBufferWithBytes:noRotationTextureCoordinates length:sizeof(noRotationTextureCoordinates) options:MTLResourceOptionCPUCacheModeDefault];
        case kMetalImageRotateLeft:
            return [device newBufferWithBytes:rotateLeftTextureCoordinates length:sizeof(rotateLeftTextureCoordinates) options:MTLResourceOptionCPUCacheModeDefault];
        case kMetalImageRotateRight:
            return [device newBufferWithBytes:rotateRightTextureCoordinates length:sizeof(rotateRightTextureCoordinates) options:MTLResourceOptionCPUCacheModeDefault];
        case kMetalImageFlipVertical:
            return [device newBufferWithBytes:verticalFlipTextureCoordinates length:sizeof(verticalFlipTextureCoordinates) options:MTLResourceOptionCPUCacheModeDefault];
        case kMetalImageFlipHorizonal:
            return [device newBufferWithBytes:horizontalFlipTextureCoordinates length:sizeof(horizontalFlipTextureCoordinates) options:MTLResourceOptionCPUCacheModeDefault];
        case kMetalImageRotateRightFlipVertical:
            return [device newBufferWithBytes:rotateRightVerticalFlipTextureCoordinates length:sizeof(rotateRightVerticalFlipTextureCoordinates) options:MTLResourceOptionCPUCacheModeDefault];
        case kMetalImageRotateRightFlipHorizontal:
            return [device newBufferWithBytes:rotateRightHorizontalFlipTextureCoordinates length:sizeof(rotateRightHorizontalFlipTextureCoordinates) options:MTLResourceOptionCPUCacheModeDefault];
        case kMetalImageRotate180:
            return [device newBufferWithBytes:rotate180TextureCoordinates length:sizeof(rotate180TextureCoordinates) options:MTLResourceOptionCPUCacheModeDefault];
    }
}

-(id<MTLBuffer>)textureCoordinate{
    return [MetalTexture textureOrien:self.orientation];
}


@end
