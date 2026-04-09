---
name: unity-shader-dev
description: URP-first Unity shader engineering skill for building, porting, debugging, and optimizing executable ShaderLab/HLSL material shaders, fullscreen effects, renderer features, custom render passes, RenderTexture/RTHandle pipelines, and persistent GPU simulations. Use when Codex must ship runnable Unity URP shader code instead of prototype GLSL snippets.
---

# Unity Shader Dev

Use this skill to deliver production-oriented Unity URP shader work. Treat it as an engineering workflow, not a shader scrapbook.

## Scope

- Target pipeline: Unity URP
- Primary output: executable ShaderLab, HLSL, C#, and project integration steps
- Secondary output: technique selection, math explanation, and prototype algorithm notes

## Non-Goals

- Do not treat this skill as a Built-in RP or HDRP authority.
- Do not paste legacy technique snippets directly into Unity unless the section explicitly says `Unity URP Executable`.
- Do not answer with only ShaderToy-style GLSL when the user asked for Unity code.

## Execution Contract

When using this skill, produce runnable Unity artifacts first and explanation second.

Every substantial implementation should specify:

- Output type: `material shader`, `fullscreen shader`, `renderer feature`, `render pass`, `simulation driver`, or `supporting include`
- Required files to create or modify
- URP assumptions and package expectations
- Material properties and CBUFFER alignment
- Render target ownership when history or ping-pong state is involved
- Validation steps in Unity

## Delivery Paths

### 1. Material / Surface Path

Use for:

- Mesh-local shading
- Triplanar or terrain surface work
- Stylized or custom-lit materials
- Water surface shading
- Object-space raymarching inside bounds

Start from:

- `assets/templates/urp-unlit-material.shader`
- `assets/templates/urp-forward-lit.shader`
- `assets/templates/urp-transparent.shader`
- `assets/includes/SDFPrimitives.hlsl`
- `assets/includes/WaveFunctions.hlsl`
- `assets/includes/Noise.hlsl`
- `reference/recipes/mesh-surface-effect.md`
- `reference/recipes/object-space-raymarch.md`

### 2. Fullscreen / Post Path

Use for:

- Camera-space effects
- Color grading, distortion, blur, edge detection
- Screen-space ambient effects
- Post-processing style prototypes

Start from:

- `assets/templates/urp-fullscreen.shader`
- `assets/templates/urp-renderer-feature.cs`
- `reference/recipes/fullscreen-post-effect.md`

### 3. Persistent Simulation Path

Use for:

- Fluids
- Cellular automata
- Reaction-diffusion
- GPU particles with history
- Accumulation and temporal feedback
- Compute-driven grid updates when the request explicitly needs a kernel-based path

Start from:

- `assets/templates/urp-ping-pong-update.shader`
- `assets/templates/urp-ping-pong-simulation-driver.cs`
- `assets/templates/compute-simulation.compute`
- `assets/templates/compute-simulation-driver.cs`
- `reference/recipes/persistent-simulation.md`
- `reference/recipes/compute-simulation.md`

## Read Order

1. Classify the user request by delivery path.
2. Load the matching recipe from `reference/recipes/`.
3. Reuse the closest executable template from `assets/templates/`.
4. Pull formulas or algorithm detail from `techniques/` and `reference/` only as needed.
5. Convert algorithm snippets into Unity URP code that matches the selected template.

## Source-of-Truth Hierarchy

When documents disagree, use this priority:

1. `reference/pipeline/*.md`
2. `reference/recipes/*.md`
3. `assets/templates/*`
4. `SKILL.md`
5. `techniques/*.md`
6. `reference/*.md` legacy deep references

## Prototype vs Executable Rule

The repository intentionally contains two classes of content:

- `Executable Unity content`: templates, recipes, and pipeline references
- `Prototype algorithm content`: most legacy `techniques/*.md` and `reference/*.md` snippets

Interpretation rules:

- Treat legacy `glsl` code blocks as algorithm notes.
- Translate `vec*`, `mix`, `fract`, `mod`, `mainImage`, `gl_FragCoord`, `iChannel*`, and `iResolution` into Unity URP equivalents before shipping code.
- Only return raw GLSL when the user explicitly asks for prototype math rather than Unity implementation.

## Routing Table

| User asks for | Recipe | Primary template | Common legacy sources |
| --- | --- | --- | --- |
| Stylized surface shader | `reference/recipes/mesh-surface-effect.md` | `assets/templates/urp-unlit-material.shader` | `lighting-model`, `color-palette`, `texture-sampling` |
| Custom lit material | `reference/recipes/mesh-surface-effect.md` | `assets/templates/urp-forward-lit.shader` | `lighting-model`, `shadow-techniques`, `ambient-occlusion` |
| Transparent / alpha blend material | `reference/recipes/mesh-surface-effect.md` | `assets/templates/urp-transparent.shader` | `lighting-model`, `color-palette`, `texture-sampling` |
| Fullscreen distortion or post effect | `reference/recipes/fullscreen-post-effect.md` | `assets/templates/urp-fullscreen.shader` + `assets/templates/urp-renderer-feature.cs` | `post-processing`, `camera-effects`, `anti-aliasing` |
| Cross-frame simulation | `reference/recipes/persistent-simulation.md` | `assets/templates/urp-ping-pong-update.shader` + `assets/templates/urp-ping-pong-simulation-driver.cs` | `fluid-simulation`, `cellular-automata`, `simulation-physics` |
| Compute-driven simulation | `reference/recipes/compute-simulation.md` | `assets/templates/compute-simulation.compute` + `assets/templates/compute-simulation-driver.cs` | `fluid-simulation`, `simulation-physics`, `multipass-buffer` |
| Raymarched object | `reference/recipes/object-space-raymarch.md` | `assets/templates/urp-unlit-material.shader` | `ray-marching`, `sdf-3d`, `normal-estimation` |
| Water surface | `reference/recipes/water-surface.md` | `assets/templates/urp-forward-lit.shader` | `water-ocean`, `lighting-model`, `atmospheric-scattering` |

## Pipeline References

Load these files before implementing non-trivial work:

- `reference/pipeline/authoring-contract.md`
- `reference/pipeline/version-matrix.md`
- `reference/pipeline/porting-rules.md`
- `reference/pipeline/debugging.md`
- `reference/pipeline/performance.md`
- `reference/pipeline/compatibility.md`
- `reference/pipeline/rendergraph-compatibility.md`
- `reference/pipeline/rendering-path-boundaries.md`
- `reference/pipeline/shadergraph-boundary.md`

## Legacy Knowledge Base

The large `techniques/*.md` and `reference/*.md` files are still useful for:

- Formula derivation
- Variant comparison
- Troubleshooting edge cases
- Effect ideation

They are not the first place to copy code from.

## Required Output Shape

When producing a Unity implementation, include:

- File list
- Which template the solution is based on
- Which recipe governs the integration
- Which legacy technique files supplied the math
- Unity validation steps

## Engineering Rules

- Prefer HLSL and ShaderLab syntax in final output.
- Keep `Properties` and `UnityPerMaterial` aligned.
- For fullscreen work, describe the renderer feature or driver ownership explicitly.
- For persistent simulation, state buffer ownership, update order, resize policy, and invalidation conditions.
- Check `reference/pipeline/version-matrix.md` before committing to a URP API shape.
- Check `reference/pipeline/rendering-path-boundaries.md` before promising RenderGraph, compute-heavy, HDRP, or XR-specific work.
- Check `reference/pipeline/shadergraph-boundary.md` before choosing pure HLSL output for a Shader Graph-oriented request.
- Mention unsupported or cautionary paths when the request implicitly needs APIs or workflows not covered by the current templates.

## Validation

When editing this skill, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\normalize_legacy_docs.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\validate_skill_docs.ps1
```

Do not claim the skill is cleaned up until validation passes.
