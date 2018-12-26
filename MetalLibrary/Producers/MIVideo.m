//
//  MIVideo.m
//  MetalImage
//
//  Created by Sylar on 2018/12/25.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIVideo.h"
#import "MITexture.h"
#import "MIContext.h"

@interface MIVideo()
{
    NSThread *_videoProcessingThread;
    NSCondition *_stopCompletionCondition;
    float _frameRate;
    CADisplayLink *_videoDisplayLink;
    CGSize _size;
    BOOL _shouldStopPlaying;
    BOOL _decodingDidEnd;
    AVAssetReader *_assetReader;
    AVAssetReaderTrackOutput *_readerVideoTrackOutput;  //视轨
    AVAssetReaderTrackOutput *_readerAudioTrackOutput;  //音轨
    
    CFAbsoluteTime _processingStartTime;//开始处理的时间
        
}

@end

@implementation MIVideo
- (void)dealloc {
    if (_videoDisplayLink) {
        [_videoDisplayLink invalidate];
    }
    
    if (_videoProcessingThread) {
        if (_videoProcessingThread.isExecuting) {
            [_videoProcessingThread cancel];
        }
    }
    [self deleteAssetReader];
}

- (instancetype)init {
    if (self = [super init]) {
        _outputTexture = [[MITexture alloc] init];
        _stopCompletionCondition = [[NSCondition alloc] init];
        _playAtActualSpeed = YES;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [self init]) {
        self.url = url;
    }
    return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset {
    if (self = [self init]) {
        self.asset = asset;
    }
    return self;
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:_url options:options];
    self.asset = urlAsset;
    
}

- (void)setAsset:(AVAsset *)asset {
    _asset = asset;
    NSArray *tracks = [_asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = tracks[0];
        
        //获取视频轨道帧率
        _frameRate = videoTrack.nominalFrameRate;
        
        //获取视频轨道方向
        CGAffineTransform t = videoTrack.preferredTransform;
        if (t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
            _orientation = MIVideoOrientationPortrait;
        } else if (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
            _orientation = MIVideoOrientationPortraitUpsideDown;
        } else if (t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {
            _orientation = MIVideoOrientationLandscapeLeft;
        } else if (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
            _orientation = MIVideoOrientationLandscapeRight;
        }
        
        //获取视频轨道分辨率
        if (_orientation == MIVideoOrientationPortrait || _orientation == MIVideoOrientationPortraitUpsideDown) {
            _size = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
        } else {
            _size = videoTrack.naturalSize;
        }
    }
}

- (double)duration {
    double duration = 0.0;
    
    if (self.asset) {
        duration = CMTimeGetSeconds(self.asset.duration);
    }
    
    return duration;
}


#pragma mark - 创建assetReader

- (void)configAssetReader {
    NSError *error = nil;
    _assetReader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
    
    if (error) {
        NSLog(@"MetalImage Error: %s,", __FUNCTION__);
    }
    
    NSArray *videoTracks = [_asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count) {
        NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey :@(kCVPixelFormatType_32BGRA)};
        _readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTracks[0] outputSettings:outputSettings];
        _readerVideoTrackOutput.alwaysCopiesSampleData = NO;
        [_assetReader addOutput:_readerVideoTrackOutput];
    }
    
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count) {
        _readerAudioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTracks[0] outputSettings:nil];
        _readerAudioTrackOutput.alwaysCopiesSampleData = NO;
        if ([_assetReader canAddOutput:_readerAudioTrackOutput]) {
            [_assetReader addOutput:_readerAudioTrackOutput];
        }
    }
}


#pragma mark - 播放控制

- (BOOL)play {
    if (self.status == MIVideoStatusPaused) {
        _status = MIVideoStatusPlaying;
        _videoDisplayLink.paused = NO;
        return YES;
    }
    
    if (self.status != MIVideoStatusWaiting || !self.asset) {
        return NO;
    }
    
    _status = MIVideoStatusPlaying;
    
    [self configAssetReader];
    
    if (!_assetReader) {
        NSLog(@"Metal Error at %s.", __FUNCTION__);
        return NO;
    }
    
    if (![_assetReader startReading]) {
        return NO;
    }
    
    if (!_videoProcessingThread) {
        _videoProcessingThread = [[NSThread alloc] initWithTarget:self selector:@selector(startProcessVideo) object:nil];
        [_videoProcessingThread start];
    }
    
    return YES;
}

- (void)stop {
    if (_videoProcessingThread && _videoProcessingThread.isExecuting) {
        [_stopCompletionCondition lock];
        _shouldStopPlaying = YES;
        [_stopCompletionCondition wait];
        [_stopCompletionCondition unlock];
    }
}

- (void)pause {
    if (self.status != MIVideoStatusPlaying || !_videoDisplayLink) {
        return;
    }
    _status = MIVideoStatusPaused;
    _videoDisplayLink.paused = YES;
}


#pragma mark Start Processing Video

-(void)startProcessVideo{
    //子线程读取AssetTracker
    [NSThread currentThread].name = @"MIVideoProcessingThread";
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    _processingStartTime = CFAbsoluteTimeGetCurrent();
    _decodingDidEnd = NO;
    _shouldStopPlaying = NO;
    if (!_videoDisplayLink) {
        _videoDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(processVideo:)];
        [_videoDisplayLink addToRunLoop:runloop forMode:NSRunLoopCommonModes];
    }
    
    while (!_decodingDidEnd && !_shouldStopPlaying && [runloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    if (_videoDisplayLink) {
        [_videoDisplayLink invalidate];
        _videoDisplayLink = nil;
    }
    
    [self deleteAssetReader];
    if (_videoProcessingThread) {
        if (_videoProcessingThread.isExecuting) {
            [_videoProcessingThread cancel];
        }
        _videoProcessingThread = nil;
    }
    
    _status = MIVideoStatusWaiting;
    _progress = 0.0;
    
    if (_shouldStopPlaying) {
        [_stopCompletionCondition lock];
        [_stopCompletionCondition signal];
        [_stopCompletionCondition unlock];
    }
    
    if (_decodingDidEnd) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoDidEnd:)]) {
            [self.delegate videoDidEnd:self];
        }
    }
}


- (void)processVideo:(CADisplayLink *)displaylink {
    if (_shouldStopPlaying || !_assetReader) {
        return;
    }
    
    if (_assetReader.status == AVAssetReaderStatusReading) {
        CMSampleBufferRef videoSampleBuffer = [_readerVideoTrackOutput copyNextSampleBuffer];
        if (videoSampleBuffer == NULL) {
            _decodingDidEnd = YES;
            _shouldStopPlaying = YES;
            return;
        }
        
        CMTime frameTime = CMSampleBufferGetOutputPresentationTimeStamp(videoSampleBuffer);
        _progress = CMTimeGetSeconds(frameTime) / self.duration;
        if (_playAtActualSpeed) {
            CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
            CGFloat actualTimeDifference = currentTime - _processingStartTime;
            
            if (CMTimeGetSeconds(frameTime) > actualTimeDifference) {
                usleep(1000000.0 * (CMTimeGetSeconds(frameTime) - actualTimeDifference));
            }
        }
        
        if (!_shouldStopPlaying && self.delegate && [self.delegate respondsToSelector:@selector(video:willOutputSampleBuffer:)]) {
            [self.delegate video:self willOutputSampleBuffer:videoSampleBuffer];
        }
        
        [MIContext performSynchronouslyOnImageProcessingQueue:^{

            id<MTLCommandBuffer> commandBuffer = [[MIContext defaultContext].commandQueue commandBuffer];
            commandBuffer.label = @"MIVideo";
            [self processVideoSampleBuffer:videoSampleBuffer commandBuffer:commandBuffer];
            [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
                CMSampleBufferInvalidate(videoSampleBuffer);
                CFRelease(videoSampleBuffer);
            }];
            [commandBuffer commit];
        }];
    }
}


- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
    CVImageBufferRef sourceImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(sourceImageBuffer, 0);
    [_outputTexture setupContentWithCVBuffer:sourceImageBuffer];
    
    if (CGRectEqualToRect(self.outputFrame, CGRectZero)) {
        self.outputFrame = CGRectMake(0, 0, _outputTexture.size.width, _outputTexture.size.height);
    }
    
    [self produceAtTime:CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer) commandBuffer:commandBuffer];
    CVPixelBufferUnlockBaseAddress(sourceImageBuffer, 0);
}

- (CMSampleBufferRef)copyNextAudioSampleBuffer {
    if (!self.isEnabled || self.status != MIVideoStatusPlaying || !_readerAudioTrackOutput) {
        return NULL;
    }
    
    CMSampleBufferRef sampleBuffer = [_readerAudioTrackOutput copyNextSampleBuffer];

    return sampleBuffer;
}

- (void)deleteAssetReader {
    if (_assetReader) {
        if (_assetReader.status == AVAssetReaderStatusReading) {
            [_assetReader cancelReading];
        }
        _assetReader = nil;
    }
    if (_readerVideoTrackOutput) {
        _readerVideoTrackOutput = nil;
    }
    if (_readerAudioTrackOutput) {
        _readerAudioTrackOutput = nil;
    }
}


@end
