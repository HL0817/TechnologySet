# Rain

## 目录
+ [方案对比](#方案对比)
    + [雨粒子特效](#雨粒子特效)
    + [雨纹理UV动画](#雨纹理UV动画)
    + [方案选择](#方案选择)
+ [雨丝渲染](#雨丝渲染)
    + [纺锤体](#纺锤体)
    + [贴图的定义和使用](#贴图的定义和使用)
    + [风的影响](#风的影响)
    + [雨的层次效果](#雨的层次效果)
    + [雨的深度遮挡](#雨的深度遮挡)
    + [雨的高度遮挡](#雨的高度遮挡)
+ [地表雨效果](#地表雨效果)
    + [潮湿](#潮湿)
    + [积水](#积水)
    + [涟漪](#涟漪)
    + [水珠](#水珠)

## 方案对比
雨渲染从整体实现上，大致可以分为两种：
+ 雨粒子特效
+ 雨纹理UV动画

### 雨粒子特效
先看一下雨粒子特效的效果，这是 [NVIDIA Direct3D SDK 10 Code Samples](https://developer.download.nvidia.cn/SDK/10.5/direct3d/samples.html#rain) 里雨的例子，使用粒子系统实现了简单的 [雨场景（视频例子）](./images/Rain.wmv)

+ 大雨
    + 场景使用 3000000 个雨粒子来模拟大雨

    ![rain_particles_heavy_rain](./images/rain_particles_heavy_rain.png)

+ 小雨
    + 场景使用 6000 个雨粒子来模拟小雨
    + 尽管有 6000 个粒子，其实这个时候的效果已经不是很好了
    + 如果要有朦胧细雨的那种密度，粒子数量需要提升至少一个量级

    ![rain_particles_light_rain](./images/rain_particles_light_rain.png)

+ 雨叠加风向
    + 雨叠加风的影响，模拟风雨交加的情况
    + 粒子叠加风向还是比较容易的，比较好实现，不过计算量嘛（每个粒子都需要计算一次风向叠加？）

    ![rain_particles_with_direction_winds](./images/rain_particles_with_direction_winds.png)

+ 雨花
    + 雨落到地面，溅起水花
    + 粒子碰撞的效果，看起来还是很好的

    ![rain_particles_rain_splashed_on_the_ground](./images/rain_particles_rain_splashed_on_the_ground.png)

+ 雨叠加点光
    + 雨和光线的叠加
    + 很容易给每滴雨计算各自的光照，不过还是计算量的问题

    ![rain_particles_with_point_light](./images/rain_particles_with_point_light.png)

优点：
+ 实现起来简单直接
    + 使用现成的粒子系统和粒子碰撞
+ 效果好
    + 大雨小雨模拟都很真实
    + 雨水落下和地面互动的效果很真实
    + 容易计算不同光照的影响

缺点：
+ 使用粒子系统，消耗巨大
    + 小雨情况下，仍然使用了 6000 个粒子来模拟，但小雨的雨点看上去过于稀疏，效果不好
    + 风向计算、光照计算、地面的粒子碰撞计算，整体计算量都会随着粒子的增加而增加
    + 粒子系统本身就算是一个比较耗的模块，上万的粒子数量就已经受不了了

总结起来就一句话：它很好，是我电脑不够好

### 雨纹理UV动画
看一下这种方案的雨渲染的经典例子——[AMD ATI Toyshop video demo](https://www.youtube.com/watch?v=LtxvpS5AYHQ)

![ATI_toyshop_video_demo](./images/ATI_toyshop_video_demo.png)

核心思路就是给屏幕挂一个全屏贴图，将雨丝的贴图滚动播放，以此来模拟雨滴滑落的效果

![rain_uv_texture](./images/rain_uv_texture.png)

优点：
+ 消耗低，计算量小
    + 仅仅用个面片，把雨丝的纹理画上去，然后计算UV偏移
+ 效果不错，就视频中的效果来说，看上去比较真实不错

缺点：
+ 雨纹理UV动画仅仅表现了雨滴滑落的效果，地面的水花，涟漪等碰撞效果需要单独处理
+ 必须固定镜头，让视角不要仰视或者俯视，不然会看到雨从奇怪的地方落下或者雨水平行于天空或者地面
    + Rain Texture 平行于镜头，会在俯仰角发现雨和天空、大地等平行

    ![camera_lookat_the_ground_or_the_sky_with_rain_texture](./images/camera_lookat_the_ground_or_the_sky_with_rain_texture.png)

    + Rain Texture 不平行于镜头，仰视天空会出现雨从四周向中间汇聚的现象，俯视大地会出现雨从中间往四周发散的现象【TODO：图片或者作图演示】
+ 不好让雨丝叠加方向风
    + 最直观的场景就是，镜头朝着风的反方向看去，正常情况是雨往两边发散，这个方案无法模拟出来
    
    ![camera_lookat_the_the_oppsite_direction_of_the_wind_with_rain_texture](./images/camera_lookat_the_the_oppsite_direction_of_the_wind_with_rain_texture.png)

+ 遮挡处理比较困难
    + 深度遮挡，我们往雨幕中看起，显然没有前景遮挡的地方雨丝多一些，有近景遮挡的地方雨丝少一些【TODO：图片或者作图演示】
    + 高度遮挡，比如我们在屋内这种头顶有遮雨物的场景下，雨丝被房间等物体遮住，在窗口门口等地方就应该能看到雨丝【TODO：图片或者作图演示】

### 方案选择
尽管雨纹理UV动画有这样那样的缺点，尽管雨粒子模拟有非常好的效果，但是我们更需要的是，性能！性能！还TM是性能！！！

最终选择了雨纹理UV动画来实现雨渲染，原因如下：
+ 雨去牺牲性能太不划算，收益和性能消耗比太低
+ 雨的缺点可以使用一些这样那样的方法解决

既然选择了雨纹理UV动画方案实现雨渲染，那么我们势必要把工作分为两个部分
+ 雨丝渲染
+ 地表雨效果

接下来也会按照这两个课题来研究如何实现效果不错，没有明显瑕疵，可以被接受的雨渲染效果

## 雨丝渲染
## 地表雨效果
