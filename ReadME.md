# SYMetalImage

#### This library is highly inspired by famous library [GPUImage](https://github.com/BradLarson/GPUImage) && Colleague's [OpenglESImage](https://github.com/KwanYiuleung/OpenGLESImage)

#### Metal框架
实现了简单的镜头实时滤镜功能


#### Usage:

* 所有 `Filter` 均继承 `MetalImageFilter` , 使用时候 , 根据渲染方法 , 重写父类 `+(NSString *)functionName;` , `+ (NSString *)vertexShaderName;` , `+ (NSString *)fragmentShaderName;` , 返回Function或者Shader 名字;

* 框架可选择使用 `RenderFunctionType` 与 `ComputeFunctionType` ;

* 滤镜Render方法可重写 , 遵循 `MetalConsumer`  , 代理中定义了 `- (void)setInputTexture:(MetalTexture *)inputTexture;` 输入纹理方法, `- (void)render;`  渲染方法 ,只需要在自定义滤镜根据实际需要重写即刻

* `MetalProducer` 为生产类 , 作用于类似镜头的输出 . 滤镜作为消费者与生产类(类似滤镜链) .

#### 不足

* 添加12个普通滤镜以上 CPU 达到了 70% , 暂时感觉是每秒钟处理的图片太大(镜头图片1000+ * 1900+)，或者写法不对，欢迎提PR帮助改善;

* 太多功能还没有时间添加(图片处理，写入本地视频，GIF，滤镜....);


--
# Peace


