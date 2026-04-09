# Unity / URP Version Matrix

## Purpose

Use this file to choose a safe API shape before generating Unity URP code.

## Baseline Position

- Primary target: hand-written URP ShaderLab/HLSL plus C# integration
- Safe default assumption: Unity 2022 LTS through Unity 6 URP projects using compatibility-mode renderer features
- Prefer conservative API shapes when the project version is unknown

## Recommended Support Tiers

| Tier | Unity / URP shape | Status in this skill | Guidance |
| --- | --- | --- | --- |
| Tier A | Unity 2022 LTS URP | best supported | Prefer current templates as-is |
| Tier B | Unity 2023 URP | supported with caution | Verify camera target and RTHandle usage against project APIs |
| Tier C | Unity 6 URP in compatibility mode | supported with caution | Keep renderer-feature workflow explicit and call out compatibility-mode assumption |
| Tier D | Unity 6 URP RenderGraph-first workflows | boundary only | Narrow scope, explain limitations, and avoid pretending existing templates are native RenderGraph solutions |

## Template Applicability

| Template | Best-fit versions | Notes |
| --- | --- | --- |
| `assets/templates/urp-unlit-material.shader` | Tier A-C | Pure material shader path is the most stable across versions |
| `assets/templates/urp-forward-lit.shader` | Tier A-C | Treat as custom-lit starter, not a full URP Lit replacement |
| `assets/templates/urp-fullscreen.shader` | Tier A-C | Shader stays stable; integration risk is mostly in renderer hookup |
| `assets/templates/urp-renderer-feature.cs` | Tier A-B, Tier C with caution | Verify renderer feature APIs and camera color target access in the project |
| `assets/templates/urp-ping-pong-update.shader` | Tier A-C | Good for Blit-style update passes |
| `assets/templates/urp-ping-pong-simulation-driver.cs` | Tier A-C | Good for RenderTexture-driven history; not a compute-native path |
| `assets/templates/compute-simulation.compute` | Tier A-C | Minimal compute starter; verify platform support and project pipeline assumptions |
| `assets/templates/compute-simulation-driver.cs` | Tier A-C | Starter for explicit compute dispatch and buffer swap, not a production simulation framework |

## Version-Sensitive Hotspots

- `ScriptableRendererFeature` integration details
- `RTHandle` allocation and lifetime patterns
- camera color target access
- renderer feature compatibility mode versus RenderGraph path
- scene texture availability and renderer settings for opaque/depth textures

## SetupRenderPasses Conditional Compilation

Starting with Unity 2023.1, `ScriptableRendererFeature` introduces a virtual `SetupRenderPasses` method.
This method is the recommended location for acquiring `RTHandle` references (e.g., `renderer.cameraColorTargetHandle`).

**In Unity 2022 and earlier**, `AddRenderPasses` is the only injection point for setting render pass targets.

### Pattern

```csharp
#if UNITY_2023_1_OR_NEWER
public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
{
    // Acquire RTHandle references here
    pass.SetTarget(renderer.cameraColorTargetHandle);
}
#endif

public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
{
#if !UNITY_2023_1_OR_NEWER
    // Fallback for Unity 2022: acquire targets here
    pass.SetTarget(renderer.cameraColorTargetHandle);
#endif
    renderer.EnqueuePass(pass);
}
```

### Why

- In Unity 2023.1+, calling `renderer.cameraColorTargetHandle` inside `AddRenderPasses` may generate warnings about accessing camera targets at the wrong phase
- `SetupRenderPasses` runs at the correct phase for target acquisition
- Using `#if UNITY_2023_1_OR_NEWER` ensures backward compatibility with Unity 2022 LTS

## Default Decision Rule

When Unity or URP version is unknown:

1. Prefer material shader paths first.
2. Prefer compatibility-mode fullscreen integration over RenderGraph-specific advice.
3. Prefer RenderTexture ping-pong simulations over compute-first orchestration.
4. State the exact assumption in the answer.

## Required Output Note

Every non-trivial answer should state one of:

- `Assumed Unity 2022/2023 URP-compatible renderer feature workflow`
- `Assumed Unity 6 URP compatibility-mode workflow`
- `Version-specific RenderGraph workflow not covered by this skill; narrowing to supported path`
