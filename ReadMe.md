# MetalImage Library

### OverView

#### This library is highly inspired by famous library [GPUImage](https://github.com/BradLarson/GPUImage) && Colleague's [OpenglESImage](https://github.com/KwanYiuleung/OpenGLESImage)

一个基于苹果 `Metal` 搭建的图片处理库.用于实时镜头滤镜处理,图片效果处理等.

### Usage

#### Base Filter
与 `GPUImage` 使用方法类似,基于滤镜链形式实现效果.

```objective-c

MIFilter *filter = [[MIFilter alloc]init];

//或者

MIFilter *filter = [[MIFilter alloc] initWithContentSize:Size];

```

`MIFilter` 是最基本的滤镜基类，使用者可以根据基类滤镜扩展所需要的自定义滤镜(库中包含了几个滤镜Filter可供使用).

#### ContentSize 与 OutputFrame

`OutputFrame` 与 `ContentSize`  的概念来源于上一级滤镜纹理大小与下一级滤镜画布大小，然后计算出 **相对的顶点坐标** , 如上一级输出纹理(如摄像头),输出纹理比下一级初始化的画布要大，那么就将上一级纹理按比例缩小绘制到下一级画布大小上，可以通过调节 `OutputFrame` 的 `x`、`y` 坐标计算 **相对顶点坐标**.默认是(0,0);意思就是以下一级画布左上角点开始绘制，相对比例画上去.
若 `MIFilter` 不指定 `ContentSize` 初始化, 则默认的画布大小(`ContentSize`) 为上一级纹理输出的大小.


#### Filter Chain

滤镜链使用与 `GPUImage` 相似

```objective-c

MIFilter *filterOne = [[MIFilter alloc]init];

MIFilter *filterTwo= [[MIFilter alloc]init];

[filterOne addConsumer:filterTwo];

```

#### Shader

`Metal` 的 `Shader` 语言与 `OpenGLES` 不一样，他是基于类 `C++` 语言。
由于不是图像处理领域方面，库中很多算法都是参考网上，不做更多深究。

`Shader` 使用起来也是非常方便,只需要新建 `Shader` 的文件 `xxx.metal` , 在里面编写图像处理算法.新建一个继承与 `MIFilter` 的滤镜类，重写里面读取 `Shader` 方法:

```objective-c

+ (NSString *)vertexShaderFunction {
    static NSString *vFunction = @"此处写着色器中Vertex的Function名字";
    return vFunction;
}

+ (NSString *)fragmentShaderFunction {
    static NSString *fFunction = @"此处写着色器中Fragment的Function名字";
    return fFunction;
}

```

然后重写 `- (void)setVertexFragmentBufferOrTexture:(id<MTLRenderCommandEncoder>)commandEncoder ` 方法，可自定义滤镜传入参数.




