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

return sin(WindFieldWidth * 3.1416 * x) * pow((1 - x), WindFieldWidth);

float result = 0.0f;
if (CreatedWindForce > LastWindForce || CreatedWindForce < 0.01f)
{
    result = LastWindForce * Attenuation;
}
if (result > Limitation * Attenuation)
{
    result = 0.0f;
}
result = CreatedWindForce + result;
if (result > Limitation)
{
    result = CreatedWindForce;
}
return result;