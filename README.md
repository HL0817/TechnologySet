# TechnologySet
游戏引擎技术积累

## 简介

## 导航

##### [光照探针](./LightProbe/LightProbe.md)
+ **已完成** 通用——作用 & 原理 & 实现方案
+ **未完成** 细节——Visibility & Interpolation & Light Grid
##### [SH in Baking](./SH_in_Baking/SH_in_Baking.md)
+ **已完成** 为什么选用 SH
+ **已完成** 球谐辐照度函数——烘焙球谐系数 & 简化计算
##### [GPU Driven Pipelines 研讨](./GPU_Driven_Pipelines/GPU_Driven_Pipelines.md)
+ **已完成** Mesh Cluster Rendering——Topic & Discussion
+ **已完成** Rendering Pipeline——Topic & Discussion
+ **已完成** Static Triangle Backface Culling——原理 & 结果
+ **已完成** GPU Occlusion Culling——Occlusion Depth Generation & Two-Phase Occlusion Culling
+ **已完成** Shadow Occlusion Depth Generation——Topic & Camera Depth Reprojection & 个人看法
+ **已完成** 总结——GPU Driven Pipeline总结 & 个人看法
##### [SSAO](./SSAO/SSAO.md)
+ **已完成** SSAO——AO & SSAO基本原理
+ **未完成** 优化实现——HBAO & GTAO
##### [光照模型简介](./Lighting_Model/Lighting_Model.md)

## doc
*这里记录一些需要的资料*
+ Games101-现代计算机图形学入门-闫令琪
    + [视频](https://www.bilibili.com/video/av90798049)
    + [课件](https://sites.cs.ucsb.edu/~lingqi/teaching/games101.html)
    + [个人笔记](https://github.com/HL0817/Games101Notes)
+ 《Mathematics for 3D Game Programming and Computer》
+ 《RealTimeRendering》 4th
+ 《Physically Based Rendering》
+ 《Fundamentals of Computer Graphics》 4th
+ 《Ray tracing in one week》-光线追踪
+ 《Fluid Engine Development》-流体模拟
+ 图形学论文解析与复现
    + [目录：知乎链接](https://zhuanlan.zhihu.com/p/357265599)
    + [github](https://github.com/AngelMonica126/GraphicAlgorithm)

## 规划及时间节点
不定期进行整体规划
***
### 2021/11/16
+ 光照模型简介
    + 当前进度：完成目录+对应资料收集
    + 计划节点：
        + 2021/11/20，完成Lambert模型+Phong模型+Blinn-Phong模型初版
        + 2021/11/27，完成剩下几个模型的间接（不要求展开）
    + 提交节点：2021/11/30
+ 雨渲染——预研
    + 预研方案
        + 方案+基础需求整理
        + 和需求方沟通，整理出项目需求点
        + 结合预研方案和项目需求，梳理引擎工作量
    + 计划节点：
        + 2021/11/16 
            + 查阅资料了解基本实现思路+浏览各个部分效果+分解基础需求
        + 2021/11/17 
            + 方案+基础需求总结成文档（性能与效果汇总）
            + 和项目对齐基本需求，对汇总文档的内容做取舍（如果有新增，需要更新）
        + 2021/11/18
            + 结合当前引擎的流程，梳理需要的工作量
            + 在组内确认工作量，并分解到不同阶段
+ 光照探针——细节
    + 未规划
+ 光照贴图
    + 未规划
+ 景深
    + 未规划
+ SSAO——GTAO & HBAO
    + 未规划

***