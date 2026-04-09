# Technique Index — 技术索引

This index maps every keyword, include file, template, and recipe to its source file and the recommended delivery path in the URP authoring pipeline.

本索引将每个关键词、include 文件、模板和配方映射到其源文件路径及 URP 创作管线中的推荐交付路径。

| Keyword | File Path | Delivery Path |
|---|---|---|
| Ray marching / SDF | techniques/ray-marching.md | Material / Surface Path |
| 3D SDF primitives | techniques/sdf-3d.md | Material / Surface Path |
| Normal estimation | techniques/normal-estimation.md | Material / Surface Path |
| SDF Primitives include | assets/includes/SDFPrimitives.hlsl | Material / Surface Path |
| Wave functions include | assets/includes/WaveFunctions.hlsl | Material / Surface Path |
| Noise include | assets/includes/Noise.hlsl | All paths |
| Lighting model | techniques/lighting-model.md | Material / Surface Path |
| PBR / BRDF | techniques/pbr-brdf.md | Material / Surface Path |
| IBL | techniques/ibl.md | Material / Surface Path |
| Shadow techniques | techniques/shadow-techniques.md | Material / Surface Path |
| Ambient occlusion | techniques/ambient-occlusion.md | Material / Surface Path |
| Post-processing | techniques/post-processing.md | Fullscreen / Post Path |
| Camera effects | techniques/camera-effects.md | Fullscreen / Post Path |
| Anti-aliasing | techniques/anti-aliasing.md | Fullscreen / Post Path |
| Fluid simulation | techniques/fluid-simulation.md | Persistent Simulation Path |
| Cellular automata | techniques/cellular-automata.md | Persistent Simulation Path |
| Simulation physics | techniques/simulation-physics.md | Persistent Simulation Path |
| Water / Ocean | techniques/water-ocean.md | Material / Surface Path |
| Color palette | techniques/color-palette.md | Material / Surface Path |
| Texture sampling | techniques/texture-sampling.md | Material / Surface Path |
| Atmospheric scattering | techniques/atmospheric-scattering.md | Material / Surface Path |
| Multipass buffer | techniques/multipass-buffer.md | Persistent Simulation Path |
| Forward Lit template | assets/templates/urp-forward-lit.shader | Material / Surface Path |
| Unlit template | assets/templates/urp-unlit-material.shader | Material / Surface Path |
| Transparent template | assets/templates/urp-transparent.shader | Material / Surface Path |
| Fullscreen template | assets/templates/urp-fullscreen.shader | Fullscreen / Post Path |
| Renderer Feature template | assets/templates/urp-renderer-feature.cs | Fullscreen / Post Path |
| Ping-pong simulation | assets/templates/urp-ping-pong-update.shader | Persistent Simulation Path |
| Ping-pong driver | assets/templates/urp-ping-pong-simulation-driver.cs | Persistent Simulation Path |
| Compute simulation | assets/templates/compute-simulation.compute | Persistent Simulation Path |
| Compute driver | assets/templates/compute-simulation-driver.cs | Persistent Simulation Path |
| Object raymarch recipe | reference/recipes/object-space-raymarch.md | Material / Surface Path |
| Mesh surface recipe | reference/recipes/mesh-surface-effect.md | Material / Surface Path |
| Fullscreen post recipe | reference/recipes/fullscreen-post-effect.md | Fullscreen / Post Path |
| Persistent sim recipe | reference/recipes/persistent-simulation.md | Persistent Simulation Path |
| Compute sim recipe | reference/recipes/compute-simulation.md | Persistent Simulation Path |
| Water surface recipe | reference/recipes/water-surface.md | Material / Surface Path |

## Delivery Paths — 交付路径说明

| Delivery Path | Description | 典型用途 |
|---|---|---|
| Material / Surface Path | Forward-lit or unlit shader on a mesh renderer. Runs per-fragment in the URP forward pass. | 材质渲染、SDF 雕刻、水面着色、PBR 光照 |
| Fullscreen / Post Path | Fullscreen shader injected via a Renderer Feature. Runs as a post-processing pass over the screen. | 后处理特效、屏幕空间效果、摄像机效果 |
| Persistent Simulation Path | Multi-pass ping-pong or compute shader driven by a MonoBehaviour. State persists across frames. | 流体模拟、元胞自动机、物理仿真、Compute 计算 |
| All paths | Utility include usable from any delivery path. | 通用噪声函数、数学工具库 |
