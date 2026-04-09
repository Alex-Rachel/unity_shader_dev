# Image-Based Lighting (IBL) in URP

<!-- GENERATED:NOTICE:START -->
> Execution status: **Unity URP Executable**.
> Code blocks in this file are written in HLSL for Unity URP and can be directly integrated into a custom URP shader.
> For the full authoring workflow, start from [the authoring contract](../reference/pipeline/authoring-contract.md) and the templates in [assets/templates](../assets/templates).
<!-- GENERATED:NOTICE:END -->

<!-- GENERATED:TOC:START -->
## Table of Contents

- [Overview — 概述](#overview--概述)
- [HLSL Functions — HLSL 函数](#hlsl-functions--hlsl-函数)
  - [SpecularIBL — 镜面环境反射](#specularibl--镜面环境反射)
  - [BRDFIntegration — BRDF 积分查找](#brdfintegration--brdf-积分查找)
  - [AmbientSpecular — 组合环境镜面光照](#ambientspecular--组合环境镜面光照)
- [Implementation Steps — 实现步骤](#implementation-steps--实现步骤)
- [Variants — 变体](#variants--变体)
- [Further Reading — 延伸阅读](#further-reading--延伸阅读)
<!-- GENERATED:TOC:END -->

---

## Overview — 概述

Image-Based Lighting (IBL) uses environment maps to provide indirect (ambient) lighting for PBR materials. The standard split-integral approach separates IBL into two parts:

基于图像的光照 (IBL) 使用环境贴图为 PBR 材质提供间接（环境）光照。标准的分部积分方法将 IBL 分为两部分：

1. **Specular IBL** — Pre-filtered environment map sampled with roughness-dependent LOD, combined with a BRDF integration LUT.
2. **Diffuse IBL** — Irradiance map (convolved environment map) or ambient probe.

1. **镜面 IBL** — 根据粗糙度选择 LOD 采样预过滤环境贴图，结合 BRDF 积分 LUT。
2. **漫反射 IBL** — 辐照度图（卷积后的环境贴图）或环境探针。

In URP, the built-in Lit shader handles IBL through the `GlossyEnvironmentReflection` and `IndirectSpecular` functions. For custom shaders, you need to sample these manually.

URP 中内置 Lit 着色器通过 `GlossyEnvironmentReflection` 和 `IndirectSpecular` 函数处理 IBL。自定义着色器需要手动采样。

---

## HLSL Functions — HLSL 函数

### SpecularIBL — 镜面环境反射

Samples the pre-filtered environment map at a mip level determined by roughness. URP's `GlossyEnvironmentReflection` internally uses the same approach.

根据粗糙度确定的 mip 层级采样预过滤环境贴图。URP 的 `GlossyEnvironmentReflection` 内部使用相同的方法。

```hlsl
// Specular IBL: sample pre-filtered environment map
// R — reflection vector (reflect(-V, N))
// roughness — perceptual roughness [0..1]
// perceptualRoughness — roughness before squaring (optional, pass roughness^2 if pre-computed)
real3 SpecularIBL(real3 R, real roughness, real perceptualRoughness)
{
    // Unity's pre-filtered environment map is stored in the skybox cubemap
    // Unity 的预过滤环境贴图存储在天空盒立方体贴图中
    // LOD mapping: roughness 0 → mip 0, roughness 1 → max mip
    half mip = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness) * UNITY_SPECCUBE_LOD_STEPS;
    // UNITY_SPECCUBE_LOD_STEPS is typically 6 in URP

    // Sample the pre-filtered environment cubemap
    // 采样预过滤环境立方体贴图
    real4 envSample = SAMPLE_TEXTURECUBE_LOD(
        _GlossyEnvironmentCubeMap,   // pre-filtered cubemap / 预过滤立方体贴图
        sampler_GlossyEnvironmentCubeMap,
        R,
        mip
    );

    // Decode HDR if needed (URP stores as RGBM or HDR format)
    // 如有需要解码 HDR（URP 以 RGBM 或 HDR 格式存储）
    return DecodeHDREnvironment(envSample, _GlossyEnvironmentCubeMap_HDR);
}
```

> **Note / 注意**: In URP you can alternatively use the built-in `GlossyEnvironmentReflection()` which handles the cubemap lookup and decode automatically:
> ```hlsl
> real3 specIBL = GlossyEnvironmentReflection(R, perceptualRoughness, 1.0);
> ```
> The explicit version above is provided for clarity and for cases where you need custom cubemap sources.

> **注意**: 在 URP 中你也可以使用内置的 `GlossyEnvironmentReflection()` 自动处理立方体贴图查找和解码。上面的显式版本用于说明原理，或在需要自定义立方体贴图来源时使用。

### BRDFIntegration — BRDF 积分查找

Samples the BRDF integration LUT (2D texture) to recover the scale and bias for the Fresnel term. This LUT encodes the integral of the Cook-Torrance BRDF over the hemisphere for varying roughness and view angles.

采样 BRDF 积分 LUT（2D 纹理）以恢复菲涅尔项的缩放和偏移。此 LUT 编码了 Cook-Torrance BRDF 在半球上的积分，针对不同粗糙度和视角。

```hlsl
// BRDF Integration LUT lookup
// NdotV — dot(normal, viewDir) clamped to [0..1]
// roughness — perceptual roughness [0..1]
// Returns: scale and bias for F_Schlick (x = scale, y = bias)
real2 BRDFIntegration(real NdotV, real roughness)
{
    // The LUT is a 2D texture where:
    //   U axis = NdotV (cosine of view angle)
    //   V axis = roughness
    // LUT 是一张 2D 纹理，其中：
    //   U 轴 = NdotV（视角余弦）
    //   V 轴 = 粗糙度

    // Use the built-in LUT provided by URP / 使用 URP 提供的内置 LUT
    return SAMPLE_TEXTURE2D(
        _BRDFLut,           // BRDF integration LUT texture / BRDF 积分 LUT 纹理
        sampler_BRDFLut,
        real2(NdotV, roughness)
    ).rg;
}
```

> **Note / 注意**: The LUT texture `_BRDFLut` must be declared and assigned. URP provides this texture internally. If you need a standalone version, you can generate the LUT with a compute shader or pre-bake it as an asset.

> **注意**: LUT 纹理 `_BRDFLut` 必须声明并赋值。URP 内部提供此纹理。如需独立版本，可通过计算着色器生成或预烘焙为资产。

### AmbientSpecular — 组合环境镜面光照

Combines SpecularIBL and BRDFIntegration into the final ambient specular term. This is the complete indirect specular contribution for a PBR material.

将 SpecularIBL 和 BRDFIntegration 组合为最终的环境镜面项。这是 PBR 材质的完整间接镜面贡献。

```hlsl
// Full ambient specular: pre-filtered env map + BRDF integration LUT
// N — surface normal (unit vector)
// V — view direction (from surface to camera, unit vector)
// F0 — surface reflectance at normal incidence
// roughness — perceptual roughness [0..1]
// perceptualRoughness — roughness^2 (or roughness depending on your convention)
real3 AmbientSpecular(real3 N, real3 V, real3 F0, real roughness, real perceptualRoughness)
{
    real  NdotV = max(dot(N, V), 0.0001);
    real3 R     = reflect(-V, N);

    // Specular IBL sample / 镜面 IBL 采样
    real3 prefilteredColor = SpecularIBL(R, roughness, perceptualRoughness);

    // BRDF integration LUT / BRDF 积分 LUT
    real2 brdfLut = BRDFIntegration(NdotV, roughness);

    // Combine: F_Schlick with LUT scale/bias
    // 组合：F_Schlick 配合 LUT 缩放/偏移
    // F_Schlick(NdotV, F0) ≈ F0 * brdfLut.x + brdfLut.y
    real3 specular = prefilteredColor * (F0 * brdfLut.x + brdfLut.y);

    return specular;
}
```

### Complete IBL function (specular + diffuse) / 完整 IBL 函数（镜面 + 漫反射）

```hlsl
// Full IBL: ambient specular + ambient diffuse
// N — surface normal
// V — view direction (surface to camera)
// albedo — base color
// metallic — metallic parameter [0..1]
// roughness — perceptual roughness [0..1]
real3 IBLAmbient(real3 N, real3 V, real3 albedo, real metallic, real roughness)
{
    real3 F0 = lerp(0.04, albedo, metallic);
    real  perceptualRoughness = roughness * roughness;
    real  NdotV = max(dot(N, V), 0.0001);

    // --- Specular IBL / 镜面 IBL ---
    real3 specular = AmbientSpecular(N, V, F0, roughness, perceptualRoughness);

    // --- Diffuse IBL / 漫反射 IBL ---
    // Use the irradiance map (URP's baked ambient probe)
    // 使用辐照度图（URP 烘焙的环境探针）
    real3 irradiance = SAMPLE_TEXTURECUBE(
        _GlossyEnvironmentCubeMap,
        sampler_GlossyEnvironmentCubeMap,
        N
    ).rgb;
    irradiance = DecodeHDREnvironment(real4(irradiance, 1.0), _GlossyEnvironmentCubeMap_HDR);

    // Or use URP's built-in ambient:
    // 或使用 URP 内置环境光：
    // real3 irradiance = _GlossyEnvironmentColor.rgb; // from ambient probe

    // Fresnel for diffuse / 漫反射菲涅尔
    real3 F = F_Schlick(NdotV, F0);
    real3 kD = (1.0 - F) * (1.0 - metallic);

    real3 diffuse = kD * albedo * irradiance;

    return specular + diffuse;
}
```

---

## Implementation Steps — 实现步骤

### Step 1: Include URP headers / 包含 URP 头文件

```hlsl
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
```

`Lighting.hlsl` and `ShaderVariablesFunctions.hlsl` provide `GlossyEnvironmentReflection`, `DecodeHDREnvironment`, and the cubemap/sampler declarations.

### Step 2: Declare the LUT and cubemap textures / 声明 LUT 和立方体贴图纹理

If using the built-in URP resources, they are already declared in the URP includes. For a fully custom setup:

```hlsl
TEXTURECUBE(_GlossyEnvironmentCubeMap);
SAMPLER(sampler_GlossyEnvironmentCubeMap);
float4 _GlossyEnvironmentCubeMap_HDR;

TEXTURE2D(_BRDFLut);
SAMPLER(sampler_BRDFLut);
```

> **Note / 注意**: In practice, URP's `_GlossyEnvironmentCubeMap` is set automatically by the pipeline when a skybox is present. Ensure your URP asset has "Environment Lighting" configured.

> **注意**: 实际上，URP 的 `_GlossyEnvironmentCubeMap` 在存在天空盒时由管线自动设置。确保 URP 资产已配置"环境光照"。

### Step 3: Include BRDF helper functions / 包含 BRDF 辅助函数

You need the `F_Schlick` function from the [PBR / BRDF technique](pbr-brdf.md). Either include it from your shared include file or copy it inline:

```hlsl
real Pow5(real x) { return x * x * x * x * x; }
real3 F_Schlick(real cosTheta, real3 F0)
{
    return F0 + (1.0 - F0) * Pow5(1.0 - cosTheta);
}
```

### Step 4: Integrate in fragment shader / 在片元着色器中集成

```hlsl
half4 Frag(Varyings input) : SV_Target
{
    half3 albedo    = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb * _BaseColor.rgb;
    half  metallic  = _Metallic;
    half  roughness = 1.0 - _Smoothness;
    half3 N         = normalize(input.normalWS);
    half3 V         = normalize(_WorldSpaceCameraPos - input.positionWS);

    // Direct lighting (see PBR/BRDF technique)
    // 直接光照（参见 PBR/BRDF 技术）
    Light mainLight = GetMainLight(input.shadowCoord);
    half3 color = BRDFDirectLighting(N, V, mainLight.direction, mainLight.color,
                                      albedo, metallic, roughness);

    // Additional lights / 附加光源
    uint lightsCount = GetAdditionalLightsCount();
    for (uint i = 0; i < lightsCount; i++)
    {
        Light addLight = GetAdditionalLight(i, input.positionWS);
        color += BRDFDirectLighting(N, V, addLight.direction, addLight.color,
                                     albedo, metallic, roughness);
    }

    // IBL ambient / IBL 环境光
    color += IBLAmbient(N, V, albedo, metallic, roughness);

    return half4(color, 1.0);
}
```

### Step 5: Ensure environment setup / 确保环境设置

- In your URP Asset, set **Environment Lighting** to use a skybox or custom environment map.
- 在 URP 资产中，将"环境光照"设置为使用天空盒或自定义环境贴图。
- Bake lighting or use real-time reflections if needed.
- 如有需要，烘焙光照或使用实时反射。
- For custom cubemaps, assign them via a C# script to `_GlossyEnvironmentCubeMap`.
- 对于自定义立方体贴图，通过 C# 脚本将其赋值给 `_GlossyEnvironmentCubeMap`。

### Step 6: Validate / 验证

- Place a sphere with your custom shader next to a URP Lit sphere with the same material parameters.
- 将使用自定义着色器的球体与使用相同材质参数的 URP Lit 球体并排放置。
- Both should produce visually similar reflections and ambient coloring.
- 两者应产生视觉上相似的反射和环境着色。
- Test at extreme roughness values (0 and 1) to verify the LUT sampling range.
- 在极端粗糙度值（0 和 1）下测试以验证 LUT 采样范围。

---

## Variants — 变体

### Convolution quality levels / 卷积质量级别

| Level | Mip count | Description | 适用场景 |
|---|---|---|---|
| Low | 4 mips | Fewer pre-filtered mip levels, faster bake | 移动端、性能受限 |
| Standard | 6 mips | URP default, `UNITY_SPECCUBE_LOD_STEPS = 6` | 桌面端、标准质量 |
| High | 8 mips | More mip levels, smoother roughness transitions | 高端桌面、影视 |
| Ultra | 10+ mips | Maximum quality, expensive to pre-filter | 离线渲染、参考对比 |

### Approximation variants / 近似变体

| Variant | Description | Trade-off / 权衡 |
|---|---|---|
| **Split-sum (本文)** | Pre-filtered env + BRDF LUT. Industry standard (Epic 2013). | 精确度高，需要预计算 LUT |
| Analytical fit | Use an analytical approximation for the BRDF integral instead of the LUT. | 省去 LUT 纹理采样，精度略低 |
| Single-sample ambient | Use a single `SAMPLE_TEXTURECUBE` at mip 0 without pre-filtering. | 最快，但无粗糙度变化 |
| Spherical Harmonics (SH) | Use SH coefficients for diffuse IBL instead of irradiance cubemap. | 更低带宽，URP 内置的 `_GlossyEnvironmentColor` 即基于 SH |
| Ambient probe only | Use only the baked ambient probe (no specular cubemap). | 最简单，适合低端移动设备 |

### Analytical BRDF integration approximation / 解析 BRDF 积分近似

For environments where LUT texture sampling is undesirable (e.g., very constrained platforms), the following approximation can replace the LUT lookup:

在不适合 LUT 纹理采样的环境（如非常受限的平台），以下近似可替代 LUT 查找：

```hlsl
// Analytical approximation of BRDF integration (Karis 2013)
// 解析近似 BRDF 积分（Karis 2013）
real2 BRDFIntegrationApprox(real NdotV, real roughness)
{
    // See "Real Shading in Unreal Engine 4" by Brian Karis
    // 参见 Brian Karis 的 "Real Shading in Unreal Engine 4"
    real c = (1.0 - roughness) * 5.0;
    real4 r = real4(1.0, 0.0, 0.0, 0.0);
    r.x = 1.0 - roughness * roughness * 0.45;
    r.y = 0.1 + roughness * 0.42;
    r.z = roughness * roughness * 0.52;
    r.w = roughness * roughness * 0.24;

    real2 AB;
    AB.x = r.x + r.y * NdotV;
    AB.y = r.z + r.w * NdotV;
    return AB;
}
```

---

## Further Reading — 延伸阅读

- [Real Shading in Unreal Engine 4 (Karis 2013)](http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf) — The seminal paper on the split-sum IBL approach.
- [PBR / BRDF technique](pbr-brdf.md) — Cook-Torrance GGX direct lighting.
- [LearnOpenGL: IBL](https://learnopengl.com/PBR/IBL/Diffuse-irradiance) — Step-by-step IBL tutorial.
- [Filament: Image-Based Lighting](https://google.github.io/filament/Filament.html#lighting/imagebasedlights) — Detailed IBL math and implementation.
- [Unity URP Documentation](https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@latest) — Official URP lighting pipeline reference.
