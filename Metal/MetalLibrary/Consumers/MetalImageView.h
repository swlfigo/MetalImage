//
//  MetalImageView.h
//  Metal
//
//  Created by Sylar on 2017/10/12.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MetalImageView : UIView<MetalConsumer>

@property(nonatomic, readonly) id<CAMetalDrawable>          currentDrawable;

@end
