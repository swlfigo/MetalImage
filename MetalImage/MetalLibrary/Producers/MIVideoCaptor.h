//
//  MIVideoCaptor.h
//  MetalImage
//
//  Created by Sylar on 2018/9/29.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIProducer.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@class MIVideoCaptor;
@protocol MIVideoCaptorDelegate <NSObject>

@optional
- (void)videoCaptor:(MIVideoCaptor *)videoCaptor willOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)videoCaptor:(MIVideoCaptor *)videoCaptor willOutputVideoMTLTexture:(id<MTLTexture>)texture;
@end

@interface MIVideoCaptor : MIProducer <AVCaptureVideoDataOutputSampleBufferDelegate, UIAccelerometerDelegate>{
    dispatch_queue_t _cameraQueue;
    
    AVCaptureSession *_cameraSession;
    AVCaptureDevice *_camera;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureVideoDataOutput *_videoOutput;
    
    AVCaptureDevicePosition _position;
    NSString *_sessionPreset;
    int _frameRate;
    AVCaptureFocusMode _focusMode;
    CGPoint _focusPoint;
    AVCaptureExposureMode _exposureMode;
    CGPoint _exposurePoint;
    float _exposureTargetBias;
    
    CMMotionManager *_videoCaptorMotionManager;
    UIDeviceOrientation _orientation;
}

@property (nonatomic, weak) id <MIVideoCaptorDelegate> delegate;
@property (nonatomic, readonly) AVCaptureDevicePosition position;
@property (nonatomic, copy) NSString *sessionPreset;
@property (nonatomic, readwrite) CMTime minFrameDuration;  // Default value is kCMTimeInvalid.
@property (nonatomic, readwrite) CMTime maxFrameDuration;  // Default value is kCMTimeInvalid.
@property (nonatomic, readwrite) int frameRate;
@property (nonatomic, readwrite) AVCaptureFocusMode focusMode;
@property (nonatomic, readwrite) CGPoint focusPoint;
@property (nonatomic, readwrite) AVCaptureExposureMode exposureMode;
@property (nonatomic, readwrite) CGPoint exposurePoint;
@property (nonatomic, readwrite) float exposureTargetBias;
@property (nonatomic, readonly) UIDeviceOrientation orientation;
@property (nonatomic, readonly) float ISO;
@property (nonatomic, readonly) BOOL hasTorch;

- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition sessionPreset:(NSString *)sessionPreset;

- (void)startRunning;
- (void)stopRunning;
- (void)switchCamera;
@end
