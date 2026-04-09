# PBR / BRDF — Cook-Torrance GGX in URP

<!-- GENERATED:NOTICE:START -->
> Execution status: **Unity URP Executable**.
> Code blocks in this file are written in HLSL for Unity URP and can be directly integrated into a custom URP shader.
> For the full authoring workflow, start from [the authoring contract](../reference/pipeline/authoring-contract.md) and the templates in [assets/templates](../assets/templates).
<!-- GENERATED:NOTICE:END -->

<!-- GENERATED:TOC:START -->
## Table of Contents

- [Overview — 概述](#overview--概述)
- [HLSL Functions — HLSL 函数](#hlsl-functions--hlsl-函数)
  - [D_GGX — Normal Distribution Function / 法线分布函数](#d_ggx--normal-distribution-function--法线分布函数)
  - [V_SmithGGXCorrelated — Geometry Function / 几何函数](#v_smithggxcorrelated--geometry-function--几何函数)
  - [F_Schlick — Fresnel Equation / 菲涅尔方程](#f_schlick--fresnel-equation--菲涅尔方程)
  - [BRDFDirectLighting — Combined Direct BRDF / 组合直接光照 BRDF](#brdfdirectlighting--combined-direct-brdf--组合直接光照-brdf)
- [Implementation Steps — 实现步骤](#implementation-steps--实现步骤)
- [Variants — 变体](#variants--变体)
- [Further Reading — 延伸阅读](#further-reading--延伸阅读)
<!-- GENERATED:TOC:END -->

---

## Overview — 概述

Physically-Based Rendering (PBR) uses the Cook-Torrance microfacet specular BRDF model, which is the industry standard in real-time rendering. In URP, the built-in Lit shader already implements this model, but when writing custom shaders you need the individual functions yourself.

基于物理的渲染 (PBR) 使用 Cook-Torrance 微面元镜面 BRDF 模型，这是实时渲染的行业标准。URP 内置 Lit 着色器已实现此模型，但编写自定义着色器时需要自行实现各函数。

The Cook-Torrance specular BRDF is:

```
f_specular = D(h) * G(l, v) * F(v, h) / (4 * (NdotL) * (NdotV))
```

Where:
- **D** — Normal Distribution Function (NDF): probability that microfacets align with half-vector `h`.
- **G** — Geometry Function: self-shadowing and masking between microfacets.
- **F** — Fresnel Equation: ratio of light reflected vs refracted at the surface.

其中：
- **D** — 法线分布函数 (NDF)：微面元与半程向量 `h` 对齐的概率。
- **G** — 几何函数：微面元之间的自遮挡与遮蔽。
- **F** — 菲涅尔方程：表面反射光与折射光的比率。

---

## HLSL Functions — HLSL 函数

### D_GGX — Normal Distribution Function / 法线分布函数

GGX / Trowbridge-Reitz NDF. Produces a longer specular tail than Beckmann, which matches real-world materials more closely.

GGX / Trowbridge-Reitz 法线分布函数。比 Beckmann 产生更长的镜面拖尾，更贴近真实材质表现。

```hlsl
// GGX / Trowbridge-Reitz Normal Distribution Function
// NdotH  — dot(normal, halfVector)
// roughness — perceptual roughness [0..1]
real D_GGX(real NdotH, real roughness)
{
    real a  = roughness * roughness;       // alpha = roughness^2
    real a2 = a * a;                       // alpha^2
    real d  = (NdotH * a2 - NdotH) * NdotH + 1.0; // NdotH^2 * (a2 - 1) + 1
    return a2 / (PI * d * d + 1e-7);       // a2 / (PI * d^2), epsilon avoids division by zero
}
```

> **Note / 注意**: URP uses `real` which maps to `half` on mobile and `float` on desktop. If you prefer explicit precision, replace `real` with `half` or `float`.

### V_SmithGGXCorrelated — Geometry Function / 几何函数

Smith's method with Schlick-GGX approximation for correlated visibility. The correlated form accounts for the correlation between masking and shadowing, producing more accurate results than the separable Smith form.

Smith 方法配合 Schlick-GGX 近似的关联可见性函数。关联形式考虑了遮蔽与阴影之间的相关性，比可分离 Smith 形式产生更精确的结果。

```hlsl
// Smith GGX Correlated Geometry Function (visibility term)
// NdotV — dot(normal, viewDir)
// NdotL — dot(normal, lightDir)
// roughness — perceptual roughness [0..1]
real V_SmithGGXCorrelated(real NdotV, real NdotL, real roughness)
{
    real a  = roughness * roughness;
    real a2 = a * a;

    real lambdaV = NdotL * sqrt((NdotV - NdotV * a2) * NdotV + a2);
    real lambdaL = NdotV * sqrt((NdotL - NdotL * a2) * NdotL + a2);

    return 0.5 / (lambdaV + lambdaL + 1e-7);
}
```

> **Note / 注意**: This returns the full visibility term `G / (4 * NdotL * NdotV)`, i.e. the denominator of the Cook-Torrance equation is already folded in. Some references return `G` alone — make sure you use the matching convention.

> **注意**: 此函数返回完整的可见性项 `G / (4 * NdotL * NdotV)`，即 Cook-Torrance 公式的分母已并入。某些参考文献单独返回 `G`，请确保使用匹配的约定。

### F_Schlick — Fresnel Equation / 菲涅尔方程

Schlick's approximation of the Fresnel reflectance. Fast and accurate for dielectrics and conductors alike.

Schlick 菲涅尔反射率近似。对电介质和导体均快速且精确。

```hlsl
// Schlick Fresnel approximation
// cosTheta — dot(halfVector, viewDir) or dot(normal, viewDir)
// F0 — surface reflectance at normal incidence (base color for metals, 0.04 for dielectrics)
real3 F_Schlick(real cosTheta, real3 F0)
{
    return F0 + (1.0 - F0) * Pow5(1.0 - cosTheta);
}
```

> **Note / 注意**: URP provides `Pow5()` in `Common.hlsl`. If you are in a standalone context, define it as:
> ```hlsl
> real Pow5(real x) { return x * x * x * x * x; }
> ```

### BRDFDirectLighting — Combined Direct BRDF / 组合直接光照 BRDF

This function combines D, V, F into the final Cook-Torrance specular term and adds the Lambertian diffuse term. It returns the outgoing radiance for a single direct light.

此函数将 D、V、F 组合为最终的 Cook-Torrance 镜面项，并添加 Lambertian 漫反射项。返回单个直接光源的出射辐射度。

```hlsl
// Full direct lighting BRDF: Cook-Torrance specular + Lambertian diffuse
// N     — surface normal (unit vector)
// V     — view direction (from surface to camera, unit vector)
// L     — light direction (from surface to light, unit vector)
// lightColor  — RGB radiance of the light
// albedo      — base color / diffuse albedo
// metallic    — metallic parameter [0..1]
// roughness   — perceptual roughness [0..1]
real3 BRDFDirectLighting(
    real3 N, real3 V, real3 L,
    real3 lightColor,
    real3 albedo, real metallic, real roughness)
{
    real3 H = normalize(V + L);           // half vector / 半程向量

    real NdotL = max(dot(N, L), 0.0);
    real NdotV = max(dot(N, V), 0.0001);  // clamp to avoid artifacts
    real NdotH = max(dot(N, H), 0.0);
    real VdotH = max(dot(V, H), 0.0);

    // Derive F0: dielectrics ~0.04, metals use albedo / 推导 F0：电介质约 0.04，金属使用 albedo
    real3 F0 = lerp(0.04, albedo, metallic);

    // Specular BRDF / 镜面 BRDF
    real  D = D_GGX(NdotH, roughness);
    real  V = V_SmithGGXCorrelated(NdotV, NdotL, roughness);
    real3 F = F_Schlick(VdotH, F0);

    real3 specular = D * V * F;  // Cook-Torrance

    // Energy conservation: kD = 1 - F (only non-reflected light is diffuse)
    // 能量守恒：kD = 1 - F（仅有未被反射的光参与漫反射）
    real3 kD = (1.0 - F) * (1.0 - metallic); // metals have no diffuse / 金属无漫反射

    real3 diffuse = kD * albedo / PI;

    // Final outgoing radiance / 最终出射辐射度
    return (diffuse + specular) * lightColor * NdotL;
}
```

> **Note / 注意**: To loop over multiple lights, accumulate the result per-light in your fragment function. URP's `GetAdditionalLightsCount()` / `GetAdditionalLight()` API provides the light data.

> **注意**: 要遍历多个光源，在片元函数中按光源累加结果。URP 的 `GetAdditionalLightsCount()` / `GetAdditionalLight()` API 提供光源数据。

---

## Implementation Steps — 实现步骤

### Step 1: Include URP headers / 包含 URP 头文件

In your custom shader's HLSL block, include the URP common headers:

```hlsl
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
```

`Lighting.hlsl` provides `GetMainLight()`, `GetAdditionalLightsCount()`, `GetAdditionalLight()`, shadow coordinates, and more.

### Step 2: Declare material properties / 声明材质属性

In the shader's `Properties` block and `CBUFFER`:

```hlsl
// Properties
_BaseMap("Albedo Map", 2D) = "white" {}
_BaseColor("Base Color", Color) = (1,1,1,1)
_Metallic("Metallic", Range(0,1)) = 0.0
_Smoothness("Smoothness", Range(0,1)) = 0.5

// CBUFFER (SRP Batcher compatible)
CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    half4 _BaseColor;
    half _Metallic;
    half _Smoothness;
CBUFFER_END
```

> Convert `_Smoothness` to roughness: `roughness = 1.0 - _Smoothness`.

### Step 3: Define the BRDF functions / 定义 BRDF 函数

Copy the `D_GGX`, `V_SmithGGXCorrelated`, `F_Schlick`, and `BRDFDirectLighting` functions above into your shader, or place them in a shared include file (e.g., `assets/includes/PBRBRDF.hlsl`) and `#include` it.

### Step 4: Integrate in fragment shader / 在片元着色器中集成

```hlsl
half4 Frag(Varyings input) : SV_Target
{
    // Surface setup / 表面设置
    half3 albedo    = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb * _BaseColor.rgb;
    half  metallic  = _Metallic;
    half  roughness = 1.0 - _Smoothness;
    half3 N         = normalize(input.normalWS);
    half3 V         = normalize(_WorldSpaceCameraPos - input.positionWS);

    // Main light / 主光源
    Light mainLight = GetMainLight(input.shadowCoord);
    half3 L = mainLight.direction;
    half3 color = BRDFDirectLighting(N, V, L, mainLight.color, albedo, metallic, roughness);

    // Additional lights / 附加光源
    uint lightsCount = GetAdditionalLightsCount();
    for (uint i = 0; i < lightsCount; i++)
    {
        Light addLight = GetAdditionalLight(i, input.positionWS);
        color += BRDFDirectLighting(N, V, addLight.direction, addLight.color, albedo, metallic, roughness);
    }

    // Ambient / 环境光 (simplified — see IBL technique for full solution)
    half3 ambient = half3(0.03, 0.03, 0.03) * albedo;
    color += ambient;

    return half4(color, 1.0);
}
```

### Step 5: Validate / 验证

- Compare with URP's built-in Lit shader using the same material parameters.
- 使用相同材质参数与 URP 内置 Lit 着色器对比。
- Verify energy conservation: the reflected + diffuse energy should not exceed the incoming energy at grazing angles.
- 验证能量守恒：在掠射角度下，反射 + 漫反射能量不应超过入射能量。
- Test with metallic = 0 (dielectric) and metallic = 1 (metal) to confirm F0 behavior.
- 测试 metallic = 0（电介质）和 metallic = 1（金属）以确认 F0 行为。

---

## Variants — 变体

| Variant | NDF (D) | Geometry (G) | Fresnel (F) | Notes / 说明 |
|---|---|---|---|---|
| **Cook-Torrance GGX** (本文) | GGX/Trowbridge-Reitz | Smith GGX Correlated | Schlick | 行业标准，URP/SRP 默认选择 |
| Beckmann | Beckmann | Smith-Beckmann | Schlick | 更短镜面拖尾，较少用于实时 |
| Kelemen | GGX | Kelemen (approx.) | Schlick | 更简单的几何近似，性能略好但精度降低 |
| Charlie sheen | Charlie | Smith-Correlated | Schlick | 适用于布料 (cloth) 材质的各向异性 NDF |
| GGX Anisotropic | GGX Anisotropic | Smith Anisotropic | Schlick | 各向异性高光，需要 tangent 方向 |
| Burley diffuse | — | — | — | 替代 Lambertian 漫反射的 Disney 漫反射模型 |

### Roughness remapping variants / 粗糙度重映射变体

Some engines remap perceptual roughness differently:

```hlsl
// Disney remapping (URP default)
real alpha = roughness * roughness;

// Epic Games remapping (used in Unreal)
real alpha = (roughness + 1) * 0.5;
real alpha = alpha * alpha;
```

Choose the remapping that matches your asset pipeline.

选择与你的资产管线匹配的重映射方式。

---

## Further Reading — 延伸阅读

- [Real-Time Rendering, 4th Edition](https://www.realtimerendering.com/) — Chapter 9 on PBR materials.
- [Filament Material Guide](https://google.github.io/filament/Filament.html) — Excellent reference for Cook-Torrance GGX implementation details.
- [The PBR Theory](https://learnopengl.com/PBR/Theory) — LearnOpenGL PBR tutorial series.
- [Moving Frostbite to PBR](https://seblagarde.wordpress.com/2015/07/14/siggraph-2014-moving-frostbite-to-physically-based-rendering/) — Frostbite's adoption of PBR.
- [IBL technique](ibl.md) — Image-Based Lighting for indirect specular/diffuse.
