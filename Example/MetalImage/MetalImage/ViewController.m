//
//  ViewController.m
//  MetalImage
//
//  Created by Sylar on 2018/9/3.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "ViewController.h"

#import "MIVideoCaptor.h"
#import "MIView.h"
#import "MIFilter.h"
#import "MIHueFilter.h"
#import "MISaturationFilter.h"

@interface ViewController ()<MIVideoCaptorDelegate>

@property (nonatomic,strong)MIVideoCaptor *videoCaptor;
@property (nonatomic,strong)MIFilter *defaultFilter;
@property (nonatomic,strong)MIView *displayView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Display
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    _displayView = [[MIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [self.view addSubview:_displayView];
    _displayView.backgroundColor = [UIColor colorWithRed:0 green:104.0/255.0 blue:55.0/255.0 alpha:1.0];
    
    //VideoCamera
    _videoCaptor = [[MIVideoCaptor alloc] initWithCameraPosition:AVCaptureDevicePositionBack sessionPreset:AVCaptureSessionPresetPhoto];
    _videoCaptor.delegate = self;
    
    _defaultFilter = [[MIFilter alloc] init];
    
    NSInteger displayViewWidth = _displayView.contentSize.width;
    NSInteger displayViewHeight = _displayView.contentSize.height;
    _defaultFilter.outputFrame = CGRectMake(0,
                                            (int)((displayViewHeight - (displayViewWidth * 4.0/3)) * 0.5),
                                            displayViewWidth,
                                            (int)(displayViewWidth * 4.0/3));
    
        MIFilter *filter1 = [[MIFilter alloc]init];
        MIHueFilter *filter2 = [[MIHueFilter alloc]init];
        MIHueFilter *filter3 = [[MIHueFilter alloc]init];
        MISaturationFilter *filter4 = [[MISaturationFilter alloc]init];
        filter4.saturation = 2.0f;
        MIHueFilter *filter5 = [[MIHueFilter alloc]init];
        filter5.hue  = 180.0f;
        MIFilter *filter6 = [[MIFilter alloc]init];
        MIFilter *filter7 = [[MIFilter alloc]init];
        MIFilter *filter8 = [[MIFilter alloc]init];
        MIFilter *filter9 = [[MIFilter alloc]init];
        MIFilter *filter10 = [[MIFilter alloc]init];
        MIFilter *filter11 = [[MIFilter alloc]init];
        MIFilter *filter12 = [[MIFilter alloc]init];
    
        [_videoCaptor addConsumer:_defaultFilter];
        [_defaultFilter addConsumer:filter1];
        [filter1 addConsumer:filter2];
        [filter2 addConsumer:filter3];
        [filter3 addConsumer:filter4];
        [filter4 addConsumer:filter5];
        [filter5 addConsumer:filter6];
        [filter6 addConsumer:filter7];
        [filter7 addConsumer:filter8];
        [filter8 addConsumer:filter9];
        [filter9 addConsumer:filter10];
        [filter10 addConsumer:filter11];
        [filter11 addConsumer:filter12];
        [filter12 addConsumer:_displayView];
    
    
    
//    [_videoCaptor addConsumer:_defaultFilter];
//    [_defaultFilter addConsumer:_displayView];
    [_videoCaptor startRunning];
    
    
}



#pragma mark - Video Delegate

-(void)videoCaptor:(MIVideoCaptor *)videoCaptor willOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
}

@end
