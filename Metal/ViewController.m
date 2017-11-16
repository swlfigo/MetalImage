//
//  ViewController.m
//  Metal
//
//  Created by Sylar on 2017/10/11.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "ViewController.h"
#import "MetalImage.h"
#import "MetalGaussianFilter.h"

@interface ViewController ()
{
    MetalVideoCaptor *videoCaptor;
    MetalGaussianFilter *gFilter;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    videoCaptor = [[MetalVideoCaptor alloc]init];
    MetalImageView *metalView = [[MetalImageView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:metalView];

    gFilter = [[MetalGaussianFilter alloc]initWithMetalRenderType:MetalImageComputeFunctionType];
    [videoCaptor addConsumer:gFilter];
    [gFilter addConsumer:metalView];
    

    
    [videoCaptor startRunning];
    


}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"Begin");
}

-(void)ChangeRadius{
    
    int x = arc4random() % 7;
    gFilter.radius = x / 1.0f;
}

@end
