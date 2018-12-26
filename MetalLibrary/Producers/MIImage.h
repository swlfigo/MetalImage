//
//  MIImage.h
//  MetalImage
//
//  Created by Sylar on 2018/12/26.
//  Copyright © 2018年 Sylar. All rights reserved.
//

#import "MIProducer.h"
#import <UIKit/UIKit.h>


@interface MIImage : MIProducer

- (instancetype)initWithUIImage:(UIImage *)image;

@property (nonatomic, strong) UIImage *sourceImage;

- (void)processingImage;

@end


