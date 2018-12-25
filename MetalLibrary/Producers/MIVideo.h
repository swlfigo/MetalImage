//
//  MIVideo.h
//  MetalImage
//
//  Created by Sylar on 2018/12/25.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIProducer.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, MIVideoStatus) {
    MIVideoStatusWaiting,
    MIVideoStatusPlaying,
    MIVideoStatusPaused,
};

typedef NS_ENUM(NSUInteger, MIVideoOrientation) {
    MIVideoOrientationUnknown            ,
    MIVideoOrientationPortrait           ,
    MIVideoOrientationPortraitUpsideDown ,
    MIVideoOrientationLandscapeLeft      ,
    MIVideoOrientationLandscapeRight
};

@class MIVideo;
@protocol MIVideoDelegate <NSObject>

@optional
- (void)video:(MIVideo *)video willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)videoDidEnd:(MIVideo *)video;

@end


@interface MIVideo : MIProducer

@property (nonatomic, readonly) CGSize size;    //视频尺寸

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, readonly) MIVideoStatus status;
@property (nonatomic) MIVideoOrientation orientation;   //视频方向
@property (nonatomic, readonly) double duration;    //时长
@property (nonatomic, readonly) float frameRate;    //帧率
@property (nonatomic, assign) BOOL playAtActualSpeed;
@property (nonatomic) double progress;
@property (nonatomic, weak)id<MIVideoDelegate> delegate;

- (instancetype)initWithAsset:(AVAsset *)asset;
- (instancetype)initWithURL:(NSURL *)url;

- (BOOL)play;
- (void)stop;
- (void)pause;

- (CMSampleBufferRef)copyNextAudioSampleBuffer;
@end
