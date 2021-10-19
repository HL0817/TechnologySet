# GPU Driven Pipeline
*本周研讨 GPU 渲染管线，按照 [aaltonenhaar_siggraph2015_combined_final_footer_220dpi.pdf](./documents/aaltonenhaar_siggraph2015_combined_final_footer_220dpi.pdf) 的内容进行讨论*

## 目录
+ Mesh Cluster Rendering
    + Topic
    + Discussion
+ Rendering pipeline
    + 管线步骤
+ Static Triangle Backface Culling
    + 原理
    + 结果
+ Occlusion Depth Generation
    + 流程
    + 结果
+ Virtual Texturing
    + 简介
    + 在管线中的运用
    + 优劣
+ Two-Phase Occlusion Culling
    + 原理
    + 结果
+ 总结
    + GPU Driven Pipeline总结
    + 个人感受

## Mesh Cluster Rendering
### Topic
Mesh Cluster，网格块，指把一个模型以 cluster 为单位的进行细分，如下图：

![mesh_cluster](./images/mesh_cluster.png)

首先有几点需要说明或定义：
+ 固定的拓扑结构
    + 使用顶点带（vertex strips）组成的区域，被称为Cluster
    + 以 Assassin' Creed Unity(后面简称为AC) 为例，Cluster 固定为64个顶点，合计62个三角形（triangle strips）
+ 拆分和重排所有模型网格进 Cluster 里
    + 不足64个顶点，会插入 degenerate triangles 来将这个部分补齐到64个顶点
+ 需要我们自己在 VS 阶段从共享缓冲中获取顶点信息
    + 根据 Instance Id 和 Cluster Index 去索引得到需要的顶点数据
+ 使用间接绘制去按照 Cluster 的粒度进行绘制
    + 不再使用 DrawInstance 去绘制，转而使用 DrawInstancedIndirect
    + 使用间接绘制可以直接让我们在一个 drawcall 里绘制出任意数量的模型，而不必要去按不同 Instance 去绘制
+ Cluster 的剔除和绘制需要的信息都转到了 GPU 里进行，减少CPU的参与

我们通过 Mesh Cluster 能得到什么？
+ 一个 drawcall 画世界，可以使用一个 dc 绘制出任意数量的 meshes
+ 以 Cluster 的粒度（更小的粒度）进行GPU剔除
    ![mesh_cluster_occlusion_cull](./images/mesh_cluster_occlusion_cull.png)
+ 更快的顶点信息获取
+ 对 Cluster 进行深度排序
+ 使用 triangle strips 带来的问题
    + 当前划分的 Cluster ，顶点数量不够时，需要额外生成 degenerate triangles，这会增加内存消耗
    + 不确定的 Cluster 顺序，会造成 z-fighting（z 冲突）
+ 使用 MultiDrawInstancedIndirect 可以有效减缓上面的问题
    + GPU 内每个 sub-drawcall 负责绘制一个 Instance，Cluster 的绘制粒度过小

*第 5和 6点说得不是很清楚，我这里的理解是，使用间接绘制方法按 Cluster 的粒度去做绘制，在所有场景都挺有效的，但是对于 ACU 来说，会有一些问题。第一点，模型较多，需要补齐的没有64个顶点的 Cluster 比较多，补齐产生了很多额外数据，游戏使用会有很多内存上的压力；第二点，不定顺序的 Cluster 会和一些没有对齐的建筑模型发生 z冲突。他们的解决方法是，改成了 MultiDrawInstancedIndirect 的方式进行 drawcall 的命令提交，改变有两点，第一点，一个 sub-drawcall 就对应一个 Instance，把绘制的最小粒度提升了；第二点，把 Cluster 的64个固定的顶点数量，改为了64个三角形，将Cluster放大了一点。绘制粒度提升主要解决了 z冲突，Cluster 的大小提升主要减少了划分 Cluster 时需要生成的数据的量。由于变成了 Instance 的绘制粒度，绘制过程中就需要维护 index buffer。*

### Discussion
优点：
+ 提高剔除效率
    细化了剔除的粒度，如果一个模型部分遮挡，那么按照 Cluster 进行剔除，就能把遮挡的部分给剔除掉
+ 按照 wavefront（GPU调度的基本单位） 的大小去划分 Cluster，提高绘制的效率
+ Cluster 流式加载，减少加载时的压力
    模型细化成了 Cluster，粒度小了，不必一次性需要加载完整的模型，一块一块的加载也是可行的
    这里也配合了 GPU 按照 Cluster 的粒度进行绘制的想法，一个大模型不必等到完整数据加载后才进行绘制，只加载和绘制了需要的部分也是可以的

缺点：
+ Cluster 生成会产生额外数据，导致模型数据变大

个人看法：
+ Cluster 是对模型做了细化，把这个做细化的过程放到了数据处理阶段（提前烘焙得到），在我们的动态阶段，直接使用已经处理好的数据是非常节省时间的
    就我看来，可以尽可能多的优化管线，把可以做静态计算的部分给规划出来，动态阶段直接用是比较好的
+ 剔除的粒度是不是越小越好
    + 小粒度剔除是可以做到精细，剔除率高，绘制数量减少等
    + 但是剔除粒度越小，表明剔除的这个过程计算量越大，这里要考虑负优化问题

## Rendering pipeline
### Topic
![GPU_Driven_Pipeline](./images/GPU_Driven_Pipeline.png)
整个管线被分为 CPU 阶段和 GPU 阶段
这里简单说一下 CPU 的工作内容：
+ 视锥剔除（Frustum Culling)，剔除粒度应该是 Mesh 或者是 Instance
    使用四叉树剔除，粗略的先在 CPU 处理模型数据时，把视锥外的模型给剔除掉
+ 材质合批，准备 GPU 使用的 Instance 的数据
+ Drawcall 合批
    使用间接绘制，通过一个 drawcall 传递需要绘制参数（最少一个，也可能合批成好多个）

接下来按步骤，细讲一下 GPU 的工作内容：
+ Instance Culling(Frustum/Occlusion)
    ![instance_culling](./images/instance_culling.png)
    根据缓冲区拿到的每个实例的信息（变换、边界等）做剔除（视锥和遮挡剔除），然后生成可见的 Chunk 列表
    *对于一个模型来说，以 64为固定大小的 Cluster应该粒度太小了，Chunk应该就是中间的层次结构，Mesh-Chunk-Cluster这样类似的层级结构*
+ Cluster Chunk Expansion
    ![cluster_chunk_expansion](./images/cluster_chunk_expansion.png)
    把 Chunk 列表给展开成 Cluster 列表
    *这里指出了为什么不能直接展开成 Cluster列表，而是要通过 Chunk做中转。一个 mesh可以分成的 Cluster太多（0-1000~），如果直接这样去让 GPU展开，那么 Cluster的数量对于 GPU的 wavefront来说，不能使线程间达到大致平衡（不同线程间差距过大，无法进行 GPU优化）。这里把中间层级约束到了 Chunk，最大可以包含 64个 Cluster。*
+ Cluster Culling
    ![cluster_culling](./images/cluster_culling.png)
    根据 Cluster的信息（变换、边界等）做剔除（视锥和遮挡剔除），然后为每个 Cluster计算三角形背面剔除掩码（采样预先烘焙好的根据方向计算的三角形背面遮挡数据），把 Cluster剔除信息和三角形背面剔除掩码传递到下一个阶段，做 indexbuffer 压缩。
    *这里的 Triangle Mask是三角形背面剔除的采样结果，我们预先将三角形各个方向的可见性做了烘焙处理，存进 Cluster的信息里面，这里计算当前这个方向是否为背面，然后写入掩码即可。后文会展示如何烘焙三角形背面数据。*
+ Index Buffer Compaction
    ![index_buffer_compaction](./images/index_buffer_compaction.png)
    Indexbuffer 是跟着 Drawcall 一起传入 GPU 中的，它记录了所有实例的下标，这里我们根据 Cluster剔除信息和三角形背面剔除掩码将已经被剔除的 Cluster的下标以及背面剔除的三角形的下标给删除掉，把 Indexbuffer 压缩到只含有需要绘制的三角形下标。
    这里有两个点比较特殊：
    + 被压缩的 Indexbuffer 比较小（小于8mb），这样会让我们不能一次性处理非常大的 renderpass，我们必须把它分成多个 pass 来进行。这意味着，Indexbuffer 的压缩和 multi-draw 是交替进行的，不会发生所有的 Indexbuffer压缩完成才进行绘制。
    + 一个 wavefront 只会处理一个 Cluster 的 Indexbuffer 压缩计算，每个线程也就只能处理一个单独的三角形，不会和其他 wavefront 和线程有耦合。
+ Multi-Draw
    ![multi_draw](./images/multi_draw.png)
    这里使用 MultiDrawIndexInstancedIndirect 来绘制前几个步骤生成的 drawcall组。

### Discussion
优劣、以及结合项目谈实际

个人看法：