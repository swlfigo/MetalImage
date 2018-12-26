//
//  MIVideoViewController.m
//  MetalImage
//
//  Created by Sylar on 2018/12/25.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIVideoViewController.h"
#import "MIView.h"
#import "MIVideo.h"
#import "MIFilter.h"
@interface MIVideoViewController ()<MIVideoDelegate>

@property (nonatomic,strong)MIView *displayView;
@property (nonatomic,strong)MIVideo *sourceVideo;
@end

@implementation MIVideoViewController

- (void)dealloc
{
    [_sourceVideo stop];
    [_sourceVideo removeAllConsumers];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //Display
    self.edgesForExtendedLayout = UIRectEdgeNone;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    _displayView = [[MIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [self.view addSubview:_displayView];
    _displayView.backgroundColor = [UIColor colorWithRed:0 green:104.0/255.0 blue:55.0/255.0 alpha:1.0];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"corgis" ofType:@"mp4"];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    _sourceVideo = [[MIVideo alloc] initWithURL:fileURL];
    _sourceVideo.delegate = self;
    _sourceVideo.playAtActualSpeed = YES;

    
    MIFilter *filter = [[MIFilter alloc]init];
    [_sourceVideo addConsumer:filter];
    [filter addConsumer:_displayView];
    filter.outputFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale, [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale * _sourceVideo.size.height / _sourceVideo.size.width );

    [_sourceVideo play];
}

-(void)videoDidEnd:(MIVideo *)video{
    [_sourceVideo play];
}

- (void)video:(MIVideo *)video willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{

}

@end
