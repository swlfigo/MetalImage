//
//  MIVideoCaptor.m
//  MetalImage
//
//  Created by Sylar on 2018/9/29.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIVideoCaptor.h"
#import "MIContext.h"
#import "MITexture.h"

@interface MIVideoCaptor()
{
    CVMetalTextureCacheRef _cache;
}
@end

@implementation MIVideoCaptor

- (instancetype)init {
    self = [self initWithCameraPosition:AVCaptureDevicePositionBack sessionPreset:AVCaptureSessionPresetPhoto];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition sessionPreset:(NSString *)sessionPreset {
    if (self = [super init]) {
        CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                  nil,
                                  [MIContext defaultContext].device,
                                  nil,
                                  &_cache);
        
        
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == cameraPosition) {
                _camera = device;
            }
        }
        
        if (!_camera) {
            NSLog(@"MetalImage Error: %s",__FUNCTION__);
            return nil;
        }
        
        _cameraQueue = dispatch_queue_create("com.beauty.MetalImage.cameraQueue", NULL);
        _frameRate = 0;
        _focusMode = AVCaptureFocusModeContinuousAutoFocus;
        _focusPoint = CGPointMake(0.5f, 0.5f);
        _exposurePoint = CGPointMake(0.5f, 0.5f);
        _exposureTargetBias = 0.0;
        _position = cameraPosition;
        
        _outputTexture = [[MITexture alloc] init];
        [self setOutputTextureOrientationBasingOnCameraPosition:_position];
        
        _cameraSession = [[AVCaptureSession alloc] init];
        
        [_cameraSession beginConfiguration];
        NSError *error = nil;
        
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_camera error:&error];
        if ([_cameraSession canAddInput:_videoInput]) {
            [_cameraSession addInput:_videoInput];
        } else {
            NSLog(@"MetalImage Error : %s", __FUNCTION__);
            return nil;
        }
        
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoOutput.alwaysDiscardsLateVideoFrames = NO;
        _videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
        [_videoOutput setSampleBufferDelegate:self queue:_cameraQueue];
        
        if ([_cameraSession canAddOutput:_videoOutput]) {
            [_cameraSession addOutput:_videoOutput];
        } else {
            NSLog(@"MetalImage Error : %s", __FUNCTION__);
            return nil;
        }
        
        _sessionPreset = [sessionPreset copy];
        _cameraSession.sessionPreset = _sessionPreset;
        [_cameraSession commitConfiguration];
        
        _videoCaptorMotionManager = [[CMMotionManager alloc] init];
        if (_videoCaptorMotionManager.isDeviceMotionAvailable) {
            _videoCaptorMotionManager.accelerometerUpdateInterval = 0.5;
            [_videoCaptorMotionManager startDeviceMotionUpdates];
        }
    }
    return self;
}


#pragma mark - Camera Controllers

- (void)startRunning {
    if (![_cameraSession isRunning]) {
        [_cameraSession startRunning];
    }
}

- (void)stopRunning {
    if ([_cameraSession isRunning]) {
        [_cameraSession stopRunning];
    }
}

- (void)switchCamera {
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition newPosition;
    
    if (_position == AVCaptureDevicePositionBack) {
        newPosition = AVCaptureDevicePositionFront;
    } else {
        newPosition = AVCaptureDevicePositionBack;
    }
    
    AVCaptureDevice *device = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (device in devices) {
        if ([device position] == newPosition) {
            break;
        }
        device = nil;
    }
    
    if (!device) {
        return;
    }
    
    _camera = device;
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_camera error:&error];
    
    if (newVideoInput != nil) {
        [_cameraSession beginConfiguration];
        
        [_cameraSession removeInput:_videoInput];
        if ([_cameraSession canAddInput:newVideoInput]) {
            [_cameraSession addInput:newVideoInput];
            _videoInput = newVideoInput;
        } else {
            [_cameraSession addInput:_videoInput];
        }
        
        [_cameraSession commitConfiguration];
    }
    
    _position = newPosition;
    _frameRate = 0;
    
    [self setOutputTextureOrientationBasingOnCameraPosition:_position];
}

#pragma mark - Properties' Setters & Getters

- (void)setSessionPreset:(NSString *)sessionPreset {
    [_cameraSession beginConfiguration];
    _sessionPreset = [sessionPreset copy];
    if ([_cameraSession canSetSessionPreset:_sessionPreset]) {
        [_cameraSession setSessionPreset:_sessionPreset];
    }
    [_cameraSession commitConfiguration];
    _frameRate = 0;
}

- (void)setMinFrameDuration:(CMTime)minFrameDuration {
    NSError *error = nil;
    [_videoInput.device lockForConfiguration:&error];
    if (error) {
        NSLog(@"MetalImage Error : %@ %s",error.description, __FUNCTION__);
        return;
    }
    _videoInput.device.activeVideoMinFrameDuration = minFrameDuration;
    [_videoInput.device unlockForConfiguration];
}

- (CMTime)minFrameDuration {
    return _videoInput.device.activeVideoMinFrameDuration;
}

- (void)setMaxFrameDuration:(CMTime)maxFrameDuration {
    NSError *error = nil;
    [_videoInput.device lockForConfiguration:&error];
    if (error) {
        NSLog(@"MetalImage Error : %@ %s",error.description, __FUNCTION__);
        return;
    }
    _videoInput.device.activeVideoMaxFrameDuration = maxFrameDuration;
    [_videoInput.device unlockForConfiguration];
}

- (CMTime)maxFrameDuration {
    return _videoInput.device.activeVideoMaxFrameDuration;
}

- (void)setFrameRate:(int)frameRate {
    _frameRate = frameRate;
    NSError *error = nil;
    [_videoInput.device lockForConfiguration:&error];
    if (error) {
        NSLog(@"MetalImage Error : %@ %s",error.description, __FUNCTION__);
        return;
    }
    
    if (_frameRate > 0) {
        _videoInput.device.activeVideoMinFrameDuration = CMTimeMake(1, _frameRate);
        _videoInput.device.activeVideoMaxFrameDuration = CMTimeMake(1, _frameRate);
    } else {
        _videoInput.device.activeVideoMinFrameDuration = kCMTimeInvalid;
        _videoInput.device.activeVideoMaxFrameDuration = kCMTimeInvalid;
    }
    [_videoInput.device unlockForConfiguration];
}

- (void)setFocusPoint:(CGPoint)focusPoint {
    if ([_videoInput.device isFocusPointOfInterestSupported] && [_videoInput.device isFocusModeSupported:_focusMode]) {
        NSError *error;
        CGPoint adjustedPoint = focusPoint;
        if (_position == AVCaptureDevicePositionBack) {
            adjustedPoint = CGPointMake(adjustedPoint.y, 1.0f - adjustedPoint.x);
        }
        else if (_position == AVCaptureDevicePositionFront) {
            adjustedPoint = CGPointMake(adjustedPoint.y, adjustedPoint.x);
        }
        
        if ([_videoInput.device lockForConfiguration:&error]) {
            [_videoInput.device setFocusPointOfInterest:adjustedPoint];
            [_videoInput.device setFocusMode:_focusMode];
            [_videoInput.device unlockForConfiguration];
        } else {
            NSLog(@"MetalImage Error : %s", __FUNCTION__);
        }
        _focusPoint = focusPoint;
    } else {
        NSLog(@"MetalImage Error : %s", __FUNCTION__);
    }
}

- (void)setExposurePoint:(CGPoint)exposurePoint {
    if ([_videoInput.device isExposurePointOfInterestSupported] && [_videoInput.device isExposureModeSupported:_exposureMode]) {
        NSError *error;
        CGPoint adjustedPoint = exposurePoint;
        if (_position == AVCaptureDevicePositionBack) {
            adjustedPoint = CGPointMake(adjustedPoint.y, 1.0f - adjustedPoint.x);
        }
        else if (_position == AVCaptureDevicePositionFront) {
            adjustedPoint = CGPointMake(adjustedPoint.y, adjustedPoint.x);
        }
        
        if ([_videoInput.device lockForConfiguration:&error]) {
            [_videoInput.device setExposurePointOfInterest:adjustedPoint];
            [_videoInput.device setExposureMode:_exposureMode];
            [_videoInput.device unlockForConfiguration];
        } else {
            NSLog(@"MetalImage Error : %s", __FUNCTION__);
        }
        _exposurePoint = exposurePoint;
    } else {
        NSLog(@"MetalImage Error : %s", __FUNCTION__);
    }
}

- (void)setExposureTargetBias:(float)exposureTargetBias {
    _exposureTargetBias = exposureTargetBias > 8.0 ? 8.0 : (exposureTargetBias < -8.0 ? -8.0 : exposureTargetBias);
    
    NSError *error = nil;
    
    if ([_videoInput.device lockForConfiguration:&error]) {
        [_videoInput.device setExposureTargetBias:_exposureTargetBias completionHandler:nil];
        [_videoInput.device unlockForConfiguration];
    } else {
        NSLog(@"MetalImage Error : %@ %s", error.description, __FUNCTION__);
    }
    
}

- (float)ISO {
    return _camera.ISO;
}

- (BOOL)hasTorch {
    return _camera.hasTorch;
}

- (BOOL)hasFlash
{
    return _camera.hasFlash;
}

- (UIDeviceOrientation)orientation {
    UIDeviceOrientation orientation = UIDeviceOrientationUnknown;
    
    if (_videoCaptorMotionManager.isDeviceMotionActive && _videoCaptorMotionManager.deviceMotion) {
        float x = -_videoCaptorMotionManager.deviceMotion.gravity.x;
        float y =  _videoCaptorMotionManager.deviceMotion.gravity.y;
        float radian = atan2(y, x);
        
        if (radian >= -2.25 && radian <= -0.75) {
            if(orientation != UIDeviceOrientationPortrait) {
                orientation = UIDeviceOrientationPortrait;
            }
        } else if (radian >= -0.75 && radian <= 0.75) {
            if(orientation != UIDeviceOrientationLandscapeLeft) {
                orientation = UIDeviceOrientationLandscapeLeft;
            }
        } else if (radian >= 0.75 && radian <= 2.25) {
            if (orientation != UIDeviceOrientationPortraitUpsideDown) {
                orientation = UIDeviceOrientationPortraitUpsideDown;
            }
        } else if(radian <= -2.25 || radian >= 2.25) {
            if (orientation != UIDeviceOrientationLandscapeRight) {
                orientation = UIDeviceOrientationLandscapeRight;
            }
        }
        //        NSLog(@"x = %f, y = %f, radian = %f", x, y, radian);
    } else {
        NSLog(@"MetalImage Error : %s", __FUNCTION__);
    }
    
    return orientation;
}


- (void)setOutputTextureOrientationBasingOnCameraPosition:(AVCaptureDevicePosition)position {
    if (!_outputTexture) {
        return;
    }
    if (position == AVCaptureDevicePositionBack) {
        _outputTexture.orientation = MITextureOrientationRight;
    } else if (position == AVCaptureDevicePositionFront) {
        _outputTexture.orientation = MITextureOrientationLeftMirrored;
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!_cameraSession || !_cameraSession.isRunning) {
        return;
    }
    if (!self.isEnabled) {
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(videoCaptor:willOutputVideoSampleBuffer:)]) {
        [self.delegate videoCaptor:self willOutputVideoSampleBuffer:sampleBuffer];
    }
    
    CFRetain(sampleBuffer);
    CVImageBufferRef ref = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFRetain(ref);
    [_outputTexture setupContentWithCVBuffer:ref];
    if (CGRectEqualToRect(self.outputFrame, CGRectZero)) {
        self.outputFrame = CGRectMake(0, 0, _outputTexture.size.width, _outputTexture.size.height);
    }
    id<MTLCommandBuffer> commandBuffer = [[MIContext defaultContext].commandQueue commandBuffer];
    commandBuffer.label = @"MIVideoCaptorBuffer";
    [self produceAtTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer) commandBuffer:commandBuffer];

    //释放对应对象
    CFRelease(ref);
    CFRelease(sampleBuffer);


}

@end
