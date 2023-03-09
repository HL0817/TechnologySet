### 12月工作规划：
+ 子关卡划分和流程
+ HLOD：处理子关卡退化问题
+ 美术资源Budget，贴图、动画、Mesh等等
+ 性能优化
    + 显存问题，DX12开启nanite时显存过高，8GB显存容易包
        + https://zhuanlan.zhihu.com/p/578451632
        + 先按照文章第一点改了 D3D12Allocation.cpp 的内容，先使用工具测一下是否有效
+ 遗留问题
    + 风场接入技能系统
        + 跟策划对风场参数配置
        + 接入技能编辑系统
        + 参数配置可视化
    + BillBoard
        + 拆分基本部件，然后进行部件填充和 transform 设置
        + 基本实现

### 1月工作残留
+ World Composition
    + [World Composition User Guide](https://docs.unrealengine.com/4.27/en-US/BuildingWorlds/LevelStreaming/WorldBrowser/)
    + [【UE5】World Partition](https://www.jianshu.com/p/b8ab9b3223fa)
    + [完美世界丁许朋：UE4开放世界ARPG《幻塔》技术分享](http://www.gamelook.com.cn/2020/12/405988)
    + [How do I build correct Landscape HLODs in world partition?](https://forums.unrealengine.com/t/how-do-i-build-correct-landscape-hlods-in-world-partition/527124)
    + [UE4 World Composition Part 3 Streaming & LOD](https://www.youtube.com/watch?v=-IOdQwRElYU)
    + [SOLVED: World Compisition- Force Absolute Position of Tiles](https://forums.unrealengine.com/t/solved-world-compisition-force-absolute-position-of-tiles/148128)
    + [World Composition - Landscape Z-axis](https://forums.unrealengine.com/t/world-composition-landscape-z-axis/361591)
    + [World composition. Spawning character problem.](https://forums.unrealengine.com/t/world-composition-spawning-character-problem/113472)
    + [Tiled Landscape and World Machine](https://www.bilibili.com/video/BV1jt4y1S7A7/?p=27&vd_source=ed25f8cd46af3af17726f30e1b36d673)
    + [Unreal Engine 4 - World Composition](https://www.bilibili.com/video/av30443052/?vd_source=ed25f8cd46af3af17726f30e1b36d673)
+ Physical Based Lighting
    + [[UOD2022]气氛和调子-UE影调设计和实战解析 | Epic 李文磊](https://www.bilibili.com/video/BV1FD4y1x7RY/?spm_id_from=333.788&vd_source=ed25f8cd46af3af17726f30e1b36d673)
    + [自动曝光（眼部适应）](https://docs.unrealengine.com/4.27/zh-CN/RenderingAndGraphics/PostProcessEffects/AutomaticExposure/)
+ 局部天气系统扩充参数
+ 地表材质草扩充到静态模型材质
+ 游戏手机包打包

### 3月
+ Grass Fire
    + Fire BP chain
        + Example_BP
        + ExampleBurnSettingsInfo_BP
        + FireStarter_BP
        + FireStarterLimiter_BP
        + BurningPreInstance_BP
        + BurnGround_DECAL_BP
        + Smoke_BP
        + FireParticleMark_BP
        + Fire_BP
    + Grass Chunk
        + ExampleGrassSpawnInfo_BP
        + InteractiveFoliageChunk_BP
        + INTERACTIVE_FoliageComp_BP