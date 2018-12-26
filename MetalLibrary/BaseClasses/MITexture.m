//
//  MITexture.m
//  MetalImage
//
//  Created by Sylar on 2018/9/5.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MITexture.h"
#import "MIContext.h"

@interface MITexture(){
    CGSize _size;
    id<MTLBuffer> _textureCoordinateBuffer;
    CVPixelBufferRef _renderTarget;
}
@end

@implementation MITexture

+ (NSInteger)maximumTextureSizeForCurrentDevice {
    return 4096;
}

- (void)dealloc {
    if (_renderTarget) {
        CFRelease(_renderTarget);
        _renderTarget = NULL;
    }
}


#pragma mark - 初始化方法

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (instancetype)initWithSize:(CGSize)size {
    self = [self initWithSize:size orientation:MITextureOrientationUp];
    return self;
}

- (instancetype)initWithCVBuffer:(CVBufferRef)CVBuffer {
    self = [self initWithCVBuffer:CVBuffer orientation:MITextureOrientationUp];
    return self;
}

- (instancetype)initWithCGImage:(CGImageRef)image {
    self = [self initWithCGImage:image orientation:MITextureOrientationUp];
    return self;
}

- (instancetype)initWithUIImage:(UIImage *)image {
    self = [self initWithCGImage:image.CGImage];
    return self;
}

- (instancetype)initWithCALayer:(CALayer *)caLayer {
    self = [self init];
    if (self) {
        [self setupContentWithCALayer:caLayer];
    }
    return self;
}

- (instancetype)initWithSize:(CGSize)size orientation:(MITextureOrientation)orientation {
    self = [self init];
    if (self) {
        [self setupContentWithSize:size];
        _orientation = orientation;
    }
    return self;
}


- (instancetype)initWithCGImage:(CGImageRef)image orientation:(MITextureOrientation)orientation {
    if (self = [self init]) {
        [self setupContentWithCGImage:image];
        _orientation = orientation;
    }
    return self;
}

- (instancetype)initWithUIImage:(UIImage *)image orientation:(MITextureOrientation)orientation {
    self = [self initWithCGImage:image.CGImage orientation:orientation];
    return self;
}

#pragma mark - 设置纹理内容方法

- (void)setupContentWithSize:(CGSize)size {
    _mtlTexture = nil;
    CGSize intSize = [self scaleSizeBasingOnMaxTextureSize:size];
    _size = CGSizeMake((NSInteger)intSize.width, (NSInteger)intSize.height);
    
    if (_size.width >= 1 && _size.height >= 1) {
        [self createMTLTextureWithSize:size];
    }
}

- (void)setupContentWithCGImage:(CGImageRef)cgImage {
    CGFloat widthOfImage = CGImageGetWidth(cgImage);
    CGFloat heightOfImage = CGImageGetHeight(cgImage);
    _size = [self scaleSizeBasingOnMaxTextureSize:CGSizeMake(widthOfImage, heightOfImage)];
    
    NSUInteger width = _size.width;
    NSUInteger height = _size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *imageData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, width, height,
                                                      bitsPerComponent, bytesPerRow, colorSpace,
                                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, width, height), cgImage);
    
    CGContextRelease(imageContext);
    CGColorSpaceRelease(colorSpace);
    
    [self updateMTLTextureWithImageData:imageData size:_size];
    
    free(imageData);
}

- (void)setupContentWithUIImage:(UIImage *)image {
    [self setupContentWithCGImage:image.CGImage];
}

- (void)setupContentWithCALayer:(CALayer *)caLayer {
    _size = [self scaleSizeBasingOnMaxTextureSize:CGSizeMake(caLayer.contentsScale * caLayer.bounds.size.width, caLayer.contentsScale * caLayer.bounds.size.height)];
    
    NSUInteger width = _size.width;
    NSUInteger height = _size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint8_t *imageData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, width, height,
                                                      bitsPerComponent, bytesPerRow, colorSpace,
                                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGContextTranslateCTM(imageContext, 0.0f, height);
    CGContextScaleCTM(imageContext, caLayer.contentsScale, -caLayer.contentsScale);
    [caLayer renderInContext:imageContext];
    
    CGContextRelease(imageContext);
    CGColorSpaceRelease(colorSpace);
    
    [self updateMTLTextureWithImageData:imageData size:_size];
    free(imageData);
}

-(void)setupContentWithCVBuffer:(CVBufferRef)CVBuffer{
    if (CVPixelBufferGetWidth(CVBuffer) > [[self class] maximumTextureSizeForCurrentDevice] || CVPixelBufferGetHeight(CVBuffer) > [[self class] maximumTextureSizeForCurrentDevice]) {
        CGSize scaledSize = [self scaleSizeBasingOnMaxTextureSize:CGSizeMake(CVPixelBufferGetWidth(CVBuffer), CVPixelBufferGetHeight(CVBuffer))];
        
        _size = scaledSize;
        [self udpateResizedMTLTextureWithBuffer:CVBuffer newSize:scaledSize];
    } else {
        _size = CGSizeMake(CVPixelBufferGetWidth(CVBuffer), CVPixelBufferGetHeight(CVBuffer));
        [self updateMTLTextureWithCVBuffer:CVBuffer size:_size];
    }
}
#pragma mark - 属性方法

- (CGSize)size {
    if (_orientation == MITextureOrientationLeft
        || _orientation == MITextureOrientationLeftMirrored
        || _orientation == MITextureOrientationRight
        || _orientation == MITextureOrientationRightMirrored) {
        return CGSizeMake(_size.height, _size.width);
    }
    return _size;
}

- (void)setOrientation:(MITextureOrientation)orientation {
    _orientation = orientation;
    [self updateTextureCoordinateBuffer];
}

- (id<MTLBuffer>)textureCoordinateBuffer {
    if (!_textureCoordinateBuffer) {
        _textureCoordinateBuffer = [MIContext createBufferWithLength:4 * sizeof(vector_float2)];
        [self updateTextureCoordinateBuffer];
    }
    return _textureCoordinateBuffer;
}

- (void)updateTextureCoordinateBuffer {
    if (!_textureCoordinateBuffer) {
        return;
    }
    
    static const vector_float2 orientationUpTextureCoordinate[4] = {
        { 0.0, 1.0 },
        { 1.0, 1.0 },
        { 0.0, 0.0 },
        { 1.0, 0.0 }
    };
    
    static const vector_float2 orientationDownTextureCoordinate[4] = {
        { 1.0, 0.0 },
        { 0.0, 0.0 },
        { 1.0, 1.0 },
        { 0.0, 1.0 }
    };
    
    static const vector_float2 orientationLeftTextureCoordinate[4] = {
        { 0.0, 0.0 },
        { 0.0, 1.0 },
        { 1.0, 0.0 },
        { 1.0, 1.0 }
    };
    
    static const vector_float2 orientationRightTextureCoordinate[4] = {
        { 1.0, 1.0 },
        { 1.0, 0.0 },
        { 0.0, 1.0 },
        { 0.0, 0.0 }
    };
    
    static const vector_float2 orientationUpMirroredTextureCoordinate[4] = {
        { 1.0, 1.0 },
        { 0.0, 1.0 },
        { 1.0, 0.0 },
        { 0.0, 0.0 }
    };
    
    static const vector_float2 orientationDownMirroredTextureCoordinate[4] = {
        { 0.0, 0.0 },
        { 1.0, 0.0 },
        { 0.0, 1.0 },
        { 1.0, 1.0 }
    };
    
    static const vector_float2 orientationLeftMirroredTextureCoordinate[4] = {
        { 1.0, 0.0 },
        { 1.0, 1.0 },
        { 0.0, 0.0 },
        { 0.0, 1.0 }
    };
    
    static const vector_float2 orientationRightMirroredTextureCoordinate[4] = {
        { 0.0, 1.0 },
        { 0.0, 0.0 },
        { 1.0, 1.0 },
        { 1.0, 0.0 }
    };
    
    const vector_float2 *textureCoordinate;
    
    switch (_orientation) {
        case MITextureOrientationUp:
            textureCoordinate = orientationUpTextureCoordinate;
            break;
            
        case MITextureOrientationDown:
            textureCoordinate = orientationDownTextureCoordinate;
            break;
            
        case MITextureOrientationLeft:
            textureCoordinate = orientationLeftTextureCoordinate;
            break;
            
        case MITextureOrientationRight:
            textureCoordinate = orientationRightTextureCoordinate;
            break;
            
        case MITextureOrientationUpMirrored:
            textureCoordinate = orientationUpMirroredTextureCoordinate;
            break;
            
        case MITextureOrientationDownMirrored:
            textureCoordinate = orientationDownMirroredTextureCoordinate;
            break;
            
        case MITextureOrientationLeftMirrored:
            textureCoordinate = orientationLeftMirroredTextureCoordinate;
            break;
            
        case MITextureOrientationRightMirrored:
            textureCoordinate = orientationRightMirroredTextureCoordinate;
            break;
            
        default:
            textureCoordinate = orientationUpTextureCoordinate;
    }
    
    vector_float2 *textureCoordinateContent = _textureCoordinateBuffer.contents;
    
    textureCoordinateContent[0] = textureCoordinate[0];
    textureCoordinateContent[1] = textureCoordinate[1];
    textureCoordinateContent[2] = textureCoordinate[2];
    textureCoordinateContent[3] = textureCoordinate[3];
}


#pragma mark - 创建MTLTexture

- (void)createMTLTextureWithSize:(CGSize)size {
    NSInteger width = size.width;
    NSInteger height = size.height;
    if (width < 1 && height < 1) {
        return;
    }
    MTLTextureDescriptor *txtDescrp = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:size.width height:size.height mipmapped:NO];
    txtDescrp.textureType = MTLTextureType2D;
    txtDescrp.usage = MTLTextureUsageRenderTarget & MTLTextureUsageShaderRead & MTLTextureUsageShaderWrite;
    self.mtlTexture = [[MIContext defaultContext].device newTextureWithDescriptor:txtDescrp];
    
}

- (void)updateMTLTextureWithImageData:(uint8_t *)imageData size:(CGSize)bufferSize {
    if (!_mtlTexture || _mtlTexture.width != (NSInteger)bufferSize.width
        || _mtlTexture.height != (NSInteger)bufferSize.height) {
        [self createMTLTextureWithSize:bufferSize];
    }
    NSInteger width = bufferSize.width;
    NSInteger height = bufferSize.height;
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    NSUInteger bytesPerRow = 4 * width;
    [_mtlTexture replaceRegion:region mipmapLevel:0 withBytes:imageData bytesPerRow:bytesPerRow];
}

- (void)updateMTLTextureWithCVBuffer:(CVBufferRef)buffer size:(CGSize)bufferSize {
#if !TARGET_IPHONE_SIMULATOR
    CVMetalTextureRef textureRef;
    // cost to much time
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              [MIContext defaultContext].videoTextureCache,
                                              buffer,
                                              NULL,
                                              MTLPixelFormatBGRA8Unorm,
                                              bufferSize.width,
                                              bufferSize.height,
                                              0,
                                              &textureRef);
    
    
    id<MTLTexture> metalTexture = CVMetalTextureGetTexture(textureRef);
    _mtlTexture = metalTexture;
    CFRelease(textureRef);
#endif
}

- (void)udpateResizedMTLTextureWithBuffer:(CVBufferRef)buffer newSize:(CGSize)newSize {
    CGSize originalSize = CGSizeMake(CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer));
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *sourceImageBytes =  CVPixelBufferGetBaseAddress(buffer);
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, sourceImageBytes, CVPixelBufferGetBytesPerRow(buffer) * originalSize.height, NULL);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImageFromBytes = CGImageCreate((int)originalSize.width, (int)originalSize.height, 8, 32, CVPixelBufferGetBytesPerRow(buffer), genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    uint8_t *imageData = (uint8_t *) calloc(1, (int)newSize.width * (int)newSize.height * 4);
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)newSize.width, (int)newSize.height, 8, (int)newSize.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, (int)newSize.width, (int)newSize.height), cgImageFromBytes);
    
    [self updateMTLTextureWithImageData:imageData size:newSize];
    
    CGImageRelease(cgImageFromBytes);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    CGDataProviderRelease(dataProvider);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    free(imageData);
}

- (CGSize)scaleSizeBasingOnMaxTextureSize:(CGSize)size {
    NSInteger maxTextureSize = [[self class] maximumTextureSizeForCurrentDevice];
    if ((size.width < maxTextureSize) && (size.height < maxTextureSize)) {
        return size;
    }
    
    CGSize scaledSize;
    if (size.width > size.height) {
        scaledSize.width = (CGFloat)maxTextureSize;
        scaledSize.height = ((CGFloat)maxTextureSize / size.width) * size.height;
    } else {
        scaledSize.height = (CGFloat)maxTextureSize;
        scaledSize.width = ((CGFloat)maxTextureSize / size.height) * size.width;
    }
    
    return scaledSize;
}


#pragma mark -

- (UIImage *)imageFromMTLTexture {
    id<MTLTexture> imageTexture = self.mtlTexture;
    CGSize imageSize = CGSizeMake([imageTexture width], [imageTexture height]);
    size_t imageByteCount = imageSize.width * imageSize.height * 4;
    void *imageBytes = malloc(imageByteCount);
    NSUInteger bytesPerRow = imageSize.width * 4;
    MTLRegion region = MTLRegionMake2D(0, 0, imageSize.width, imageSize.height);
    [imageTexture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imageBytes, imageByteCount, MITextureReleaseDataCallback);
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(imageSize.width, imageSize.height, bitsPerComponent, bitsPerPixel, bytesPerRow,
                                        colorSpaceRef, bitmapInfo, provider, NULL, false, renderingIntent);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
    
    CFRelease(provider);
    CFRelease(colorSpaceRef);
    CFRelease(imageRef);
    
    return image;
}


#pragma mark - CVPixelBuffer Release Bytes Callback

void MITextureReleaseDataCallback(void *info, const void *data, size_t size) {
    if (data) {
        free((void *)data);
    }
}


#pragma mark - Description
-(NSString *)description{
    return [NSString stringWithFormat:@"TextureSize:%@",NSStringFromCGSize(self.size)];
}

@end
