//
//  MIVideoTwoInputViewController.m
//  MetalImage
//
//  Created by Sylar on 2018/12/26.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIVideoTwoInputViewController.h"
#import "MIVideoCaptor.h"
#import "MIView.h"
#import "MIFilter.h"
#import "MITwoInputFilter.h"
#import "MIImage.h"

@interface MIVideoTwoInputViewController ()<MIVideoCaptorDelegate>

@property (nonatomic,strong)MIVideoCaptor *videoCaptor;
@property (nonatomic,strong)MIFilter *defaultFilter;
@property (nonatomic,strong)MIView *displayView;
@property (nonatomic,strong)MITwoInputFilter *twoInputFilter;
@property (nonatomic,strong)MIImage *inputImageSource;

@end

@implementation MIVideoTwoInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
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
    
    
    
    _inputImageSource = [[MIImage alloc]initWithUIImage:[UIImage imageNamed:@"corgis.jpg"]];
    _twoInputFilter = [[MITwoInputFilter alloc]init];
    

    [_videoCaptor addConsumer:_defaultFilter];
    [_defaultFilter addConsumer:_twoInputFilter];
    
    
    MIFilter *scaleFilter = [[MIFilter alloc]init];
    //创造一个与视频纹理一样大的纹理画布
    scaleFilter.contentSize = CGSizeMake(displayViewWidth,(int)(displayViewWidth * 4.0/3));
    [_inputImageSource addConsumer:scaleFilter];
    [scaleFilter addConsumer:_twoInputFilter];
    

    
    [_twoInputFilter addConsumer:_displayView];
    [_videoCaptor startRunning];
}

-(void)videoCaptor:(MIVideoCaptor *)videoCaptor willOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    [_inputImageSource processingImage];
}



@end
