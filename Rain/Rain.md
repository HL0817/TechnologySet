# Rain

## 目录
+ [方案对比](#方案对比)
    + [雨粒子特效](#雨粒子特效)
    + [雨纹理UV动画](#雨纹理UV动画)
    + [方案选择](#方案选择)
+ [雨丝渲染](#雨丝渲染)
    + [梭体](#梭体)
    + [纹理的定义和使用](#纹理的定义和使用)
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
    + 场景使用 3,000,000 个雨粒子来模拟大雨

    ![rain_particles_heavy_rain](./images/rain_particles_heavy_rain.png)

+ 小雨
    + 场景使用 6,000 个雨粒子来模拟小雨
    + 尽管有 6,000 个粒子，其实这个时候的效果已经不是很好了
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

核心思路就是给屏幕挂一个全屏贴图，将雨丝的贴图滚动播放，以此来模拟雨滴滑落的效果。这种方案是基于后处理的思路而来的，我们在最后的阶段直接画上雨丝，不再考虑雨和其他物体碰撞关系。

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
    ~~【TODO：搭个例子，调一些对比图出来吧】~~

    + Rain Texture 不平行于镜头，仰视天空会出现雨从四周向中间汇聚的现象，俯视大地会出现雨从中间往四周发散的现象

    ![camera_lookat_ground_with_fix_rain_texture](./images/camera_lookat_ground_with_fix_rain_texture.png)
    ~~【TODO：搭个例子，调一些对比图出来吧】~~

+ 不好让雨丝叠加方向风
    + 最直观的场景就是，镜头朝着风的反方向看去，正确的情况下是雨往两边发散，仅适用面片无法模拟这个情况
    
    ![camera_lookat_the_the_oppsite_direction_of_the_wind_with_rain_texture](./images/camera_lookat_the_the_oppsite_direction_of_the_wind_with_rain_texture.png)
    ~~【TODO：搭个例子，调一些对比图出来吧】~~

+ 遮挡处理比较困难
    + 深度遮挡，我们往雨幕中看起，显然没有前景遮挡的地方雨丝多一些，有近景遮挡的地方雨丝少一些
    ~~【TODO：图片或者作图演示】~~
    + 高度遮挡，比如我们在屋内这种头顶有遮雨物的场景下，雨丝被房间等物体遮住，在窗口门口等地方就应该能看到雨丝
    ~~【TODO：图片或者作图演示】~~

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
本节主要记录雨丝渲染的实现细节，包括实现过程中的一些注意点和这个方案的自带问题的解决方法

### 梭体
首先是雨纹理贴图的载体，我们将纹理的载体从面片切换到了梭体
~~【TODO：图片或者作图演示】~~
梭体的结构为正反两个圆锥，一上一下组合在一起

#### 核心思路
我们把纹理贴图的载体从二维升级到了三维，自然不能再让其固定到镜头前面，现在我们将镜头放到梭体内部正中心，这样我们每次都会看到梭体的内部
~~【TODO：图片或者作图演示】~~

我们这么做，最主要的目的就是解决镜头俯视和仰视的问题。我们前面提到过，不管面片是垂直于地表固定角度，还是平行贴合镜头的 up 方向，都会在旋转镜头俯仰角时，造成雨丝的不自然显示（聚拢、分散、平行于天空跟地面等）。现在，将镜头放置于梭体内部的正中心，即设置梭体的位置一直与镜头同步，然后我们将纹理铺到梭体的内表面上，这样雨纹理就呈现到了镜头前。

那么，梭体是如何解决镜头俯仰视角的问题呢？镜头如果平视前方，会看到梭体的斜面，这不会影响雨纹理的呈现么？

#### 原理
我们现在来解决这几个疑惑点，我们分别从镜头平视、仰视和俯视三个角度来观察梭体，分析梭体对最终画面的影响

##### 平视梭体
我们以横切面的视角来观察相机和梭体：
+ 梭体的横截面

![shuttle_cross_section](./images/shuttle_cross_section.png)

+ 相机观察梭体的结果

![frame_of_camera_look_in_shuttle](./images/frame_of_camera_look_in_shuttle.png)

可以看到，最终相机观察到的梭体的的线框是由倾斜的，那么雨纹理覆盖到上面也是倾斜的，也就是说梭体的斜面是会影响雨纹理的呈现

如果解决？
+ 拉长梭体，减小梭体斜面的倾斜程度

    ![elongate_shuttle](./images/elongate_shuttle_1.png)

+ 在上下两个圆锥的中间加一个圆柱体，这样平视就会得到正确的画面（《Remember Me》使用这个 Mesh 作为雨纹理的载体）
    ![optimization_rain_cylinder_mesh](./images/optimization_rain_cylinder_mesh.png)

+ 不做处理，除非梭体太扁平了，否则在实际下雨过程中，看不出别特的瑕疵（我就没有做处理，只能说——开摆）

##### 仰视梭体

##### 俯视梭体

## 地表雨效果
