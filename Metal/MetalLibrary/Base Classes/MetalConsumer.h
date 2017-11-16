//
//  MetalConsumer.h
//  Metal
//
//  Created by Sylar on 2017/10/11.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MetalConsumer <NSObject>

@required
//传入纹理
- (void)setInputTexture:(MetalTexture *)inputTexture;

//渲染
- (void)render;

@optional
-(void)setTextureOrien:(MetalImageRotationMode)orien;


@end
