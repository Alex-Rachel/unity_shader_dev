# Unity Shader Dev

`unity_shader_dev` 是一个面向 Unity URP 的 shader 工程化 skill。

它的目标是把原型级 GLSL / ShaderToy 思路，转化成可交付的 Unity URP 实现。

## 这个仓库是什么

- 一个 URP-first 的 shader 交付工作流
- 一套模板、recipe 和 pipeline 规则库
- 一套带边界意识的参考体系，用于处理版本、RenderGraph、compute、XR、Shader Graph 决策

## 它优先解决什么

- 可运行的 ShaderLab / HLSL
- URP 全屏效果集成路径
- RenderTexture / RTHandle / compute simulation 起步模板
- 明确的假设、ownership 和验证说明

## 快速开始

1. 先读 [SKILL.md](I:\CustomWorkSpace\unity_shader_dev\SKILL.md)。
2. 再读 [authoring-contract.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\authoring-contract.md) 和 [version-matrix.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\version-matrix.md)。
3. 选择与你任务匹配的 recipe。
4. 从对应模板起步。
5. 只有在宿主路径确定后，再从 `techniques/*.md` 提取算法细节。

## 主要路径

| 路径 | 适用场景 | 起步文件 |
| --- | --- | --- |
| Material / Surface | 风格化材质、自定义光照材质、物体空间 raymarch | [mesh-surface-effect.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\mesh-surface-effect.md) |
| Fullscreen / Post | 色调映射、扭曲、模糊、边缘检测 | [fullscreen-post-effect.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\fullscreen-post-effect.md) |
| Persistent Simulation | 反馈效果、元胞自动机、反应扩散 | [persistent-simulation.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\persistent-simulation.md) |
| Compute Simulation | compute 驱动的 grid update | [compute-simulation.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\compute-simulation.md) |
| Transparent / Alpha Blend | 透明材质、Alpha Clipping | [mesh-surface-effect.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\mesh-surface-effect.md) |

## 支持边界

- 最佳支持：Unity 2022 LTS URP
- 谨慎支持：Unity 2023 URP
- 需显式假设支持：Unity 6 URP compatibility mode
- 仅提供边界说明：Unity 6 RenderGraph-first 工作流

在承诺高级路径前先读：

- [compatibility.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\compatibility.md)
- [rendergraph-compatibility.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\rendergraph-compatibility.md)
- [rendering-path-boundaries.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\rendering-path-boundaries.md)
- [shadergraph-boundary.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\shadergraph-boundary.md)

## 校验

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\normalize_legacy_docs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\validate_skill_docs.ps1
python "C:\Users\Administrator\.codex\skills\.system\skill-creator\scripts\quick_validate.py" .
```

## 仓库说明

<details>
<summary><strong>仓库结构</strong></summary>

### 核心入口

- [SKILL.md](I:\CustomWorkSpace\unity_shader_dev\SKILL.md)
  - 给另一个 Codex / agent 使用的运行时说明
  - 定义 delivery path、routing table、source-of-truth hierarchy、输出要求

### Pipeline 规则

- [reference/pipeline](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline)
  - 工程规则、版本边界、兼容性、性能和调试说明

重点文件：

- [authoring-contract.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\authoring-contract.md)
- [version-matrix.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\version-matrix.md)
- [porting-rules.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\porting-rules.md)
- [debugging.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\debugging.md)
- [performance.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\performance.md)
- [compatibility.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\compatibility.md)
- [rendergraph-compatibility.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\rendergraph-compatibility.md)
- [rendering-path-boundaries.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\rendering-path-boundaries.md)
- [shadergraph-boundary.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\shadergraph-boundary.md)

### Recipes

- [reference/recipes](I:\CustomWorkSpace\unity_shader_dev\reference\recipes)
  - 任务形态文档，告诉你从哪里起步、交付时必须说明什么

### Templates

- [assets/templates](I:\CustomWorkSpace\unity_shader_dev\assets\templates)
  - 可执行起步骨架，不是完整生产框架

### Examples

- [assets/examples](I:\CustomWorkSpace\unity_shader_dev\assets\examples)
  - 用于说明文件形态和组合方式的参考示例

### Shared Includes

- [assets/includes](I:\CustomWorkSpace\unity_shader_dev\assets\includes)
  - SDF、波浪、噪声等可复用 .hlsl include 文件
  - [SDFPrimitives.hlsl](I:\CustomWorkSpace\unity_shader_dev\assets\includes\SDFPrimitives.hlsl)：sdSphere、sdBox、sdTorus、sdCapsule、opUnion、opSubtraction、opIntersection、smin、rot2D
  - [WaveFunctions.hlsl](I:\CustomWorkSpace\unity_shader_dev\assets\includes\WaveFunctions.hlsl)：SampleWaveHeight、SampleWaveNormal
  - [Noise.hlsl](I:\CustomWorkSpace\unity_shader_dev\assets\includes\Noise.hlsl)：hash21、hash22、valueNoise、fbm

### 知识库索引

- [technique-index.md](I:\CustomWorkSpace\unity_shader_dev\reference\technique-index.md)
  - 关键词→文件路径→配送路径的快速映射表

### Legacy 技法库

- [techniques](I:\CustomWorkSpace\unity_shader_dev\techniques)
- [reference](I:\CustomWorkSpace\unity_shader_dev\reference)

这些内容主要是算法资料，不应默认当作 Unity 宿主代码直接复制。

</details>

<details>
<summary><strong>工作流细节</strong></summary>

### Material / Surface

用于风格化材质、自定义光照材质、地表/三平面效果、物体空间 raymarch。

从这里起步：

- [mesh-surface-effect.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\mesh-surface-effect.md)
- [urp-unlit-material.shader](I:\CustomWorkSpace\unity_shader_dev\assets\templates\urp-unlit-material.shader)
- [urp-forward-lit.shader](I:\CustomWorkSpace\unity_shader_dev\assets\templates\urp-forward-lit.shader)
- [urp-transparent.shader](I:\CustomWorkSpace\unity_shader_dev\assets\templates\urp-transparent.shader)

### Fullscreen / Post

用于色调映射、扭曲、模糊、边缘检测和屏幕空间构图。

从这里起步：

- [fullscreen-post-effect.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\fullscreen-post-effect.md)
- [urp-fullscreen.shader](I:\CustomWorkSpace\unity_shader_dev\assets\templates\urp-fullscreen.shader)
- [urp-renderer-feature.cs](I:\CustomWorkSpace\unity_shader_dev\assets\templates\urp-renderer-feature.cs)

如果项目涉及 Unity 6 / RenderGraph，先读 [rendergraph-compatibility.md](I:\CustomWorkSpace\unity_shader_dev\reference\pipeline\rendergraph-compatibility.md)。

### Persistent Simulation

用于反馈效果、元胞自动机、反应扩散和时间累积。

从这里起步：

- [persistent-simulation.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\persistent-simulation.md)
- [urp-ping-pong-update.shader](I:\CustomWorkSpace\unity_shader_dev\assets\templates\urp-ping-pong-update.shader)
- [urp-ping-pong-simulation-driver.cs](I:\CustomWorkSpace\unity_shader_dev\assets\templates\urp-ping-pong-simulation-driver.cs)

### Compute Simulation

用于明确要求 compute 驱动的更新路径。

从这里起步：

- [compute-simulation.md](I:\CustomWorkSpace\unity_shader_dev\reference\recipes\compute-simulation.md)
- [compute-simulation.compute](I:\CustomWorkSpace\unity_shader_dev\assets\templates\compute-simulation.compute)
- [compute-simulation-driver.cs](I:\CustomWorkSpace\unity_shader_dev\assets\templates\compute-simulation-driver.cs)

当前 compute 路径仍是最小 starter，不是完整仿真框架。

</details>

<details>
<summary><strong>维护规则</strong></summary>

### 不要做的事

- 不要把 legacy GLSL 宣称为 Unity 可执行代码。
- 不要把 compatibility-mode 模板宣称为原生 RenderGraph 实现。
- 不要在没有 ownership 说明的情况下描述 history buffer 或 RTHandle 流程。
- 不要把当前 compute starter 宣称为完整仿真框架。

### 优先修改哪里

- 工程规则：`reference/pipeline/*`
- 任务形态：`reference/recipes/*`
- 起步骨架：`assets/templates/*`
- 算法知识：`techniques/*` 或 legacy `reference/*`

### 最低维护标准

- 保持 `SKILL.md` 与 `agents/openai.yaml` 定位一致。
- 不要把大段细节重新塞回 `SKILL.md`。
- 新增模板时同步补对应 recipe 或边界文档。
- 扩边界能力时，先写假设和限制，再写实现指导。

</details>

## 定位总结

这个仓库不是一个泛泛的 Unity shader 资料合集。

它是一个 Unity URP shader 工程 skill，通过 recipe、pipeline 规则、模板和边界文档，把原型 shader 知识转化为可交付的 Unity 实现。

