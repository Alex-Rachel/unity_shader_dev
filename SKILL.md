---
name: unity-shader-dev
description: URP-first Unity shader engineering for building, porting, debugging, and optimizing ShaderLab/HLSL material shaders, fullscreen effects, renderer features, custom render passes, RenderTexture/RTHandle pipelines, and persistent GPU simulations. Use when: (1) writing or modifying Unity URP shader code (ShaderLab/HLSL/C#), (2) porting GLSL/ShaderToy prototypes to Unity URP, (3) creating fullscreen post-processing effects with renderer features, (4) building ping-pong or compute-driven GPU simulations, (5) debugging URP shader compile errors, pink materials, or missing passes, (6) implementing object-space raymarching or water surfaces in URP, (7) choosing between hand-written HLSL vs Shader Graph. Do NOT use for pure GLSL/ShaderToy prototyping (use shader-dev skill instead), Built-in RP, or HDRP work.
---

# Unity Shader Dev

Deliver production-oriented Unity URP shader work. Runnable artifacts first, explanation second.

## Delivery Paths

### 1. Material / Surface Path

Mesh-local shading, triplanar/terrain surfaces, stylized/custom-lit materials, water, object-space raymarching.

Templates: `assets/templates/urp-unlit-material.shader` | `assets/templates/urp-forward-lit.shader` | `assets/templates/urp-transparent.shader`
Includes: `assets/includes/SDFPrimitives.hlsl` | `assets/includes/WaveFunctions.hlsl` | `assets/includes/Noise.hlsl`
Recipe: `reference/recipes/mesh-surface-effect.md` | `reference/recipes/object-space-raymarch.md` | `reference/recipes/water-surface.md`

### 2. Fullscreen / Post Path

Camera-space effects, color grading, distortion, blur, edge detection, screen-space ambient effects.

Templates: `assets/templates/urp-fullscreen.shader` | `assets/templates/urp-renderer-feature.cs`
Recipe: `reference/recipes/fullscreen-post-effect.md`

### 3. Persistent Simulation Path

Fluids, cellular automata, reaction-diffusion, GPU particles with history, compute-driven grid updates.

Templates: `assets/templates/urp-ping-pong-update.shader` + `assets/templates/urp-ping-pong-simulation-driver.cs` (pixel path) | `assets/templates/compute-simulation.compute` + `assets/templates/compute-simulation-driver.cs` (compute path)
Recipes: `reference/recipes/persistent-simulation.md` | `reference/recipes/compute-simulation.md`

## Routing Table

| User asks for | Recipe | Primary template | Legacy technique sources |
| --- | --- | --- | --- |
| Stylized surface shader | `mesh-surface-effect.md` | `urp-unlit-material.shader` | lighting-model, color-palette, texture-sampling |
| Custom lit material | `mesh-surface-effect.md` | `urp-forward-lit.shader` | lighting-model, shadow-techniques, ambient-occlusion |
| Transparent / alpha blend | `mesh-surface-effect.md` | `urp-transparent.shader` | lighting-model, color-palette, texture-sampling |
| Fullscreen post effect | `fullscreen-post-effect.md` | `urp-fullscreen.shader` + `urp-renderer-feature.cs` | post-processing, camera-effects, anti-aliasing |
| Cross-frame simulation | `persistent-simulation.md` | `urp-ping-pong-update.shader` + driver | fluid-simulation, cellular-automata, simulation-physics |
| Compute-driven simulation | `compute-simulation.md` | `compute-simulation.compute` + driver | fluid-simulation, simulation-physics, multipass-buffer |
| Raymarched object | `object-space-raymarch.md` | `urp-unlit-material.shader` | ray-marching, sdf-3d, normal-estimation |
| Water surface | `water-surface.md` | `urp-forward-lit.shader` | water-ocean, lighting-model, atmospheric-scattering |

## Read Order

1. Classify request by delivery path.
2. Load matching recipe from `reference/recipes/`.
3. Reuse closest template from `assets/templates/`.
4. Pull algorithm detail from `techniques/` and `reference/` only as needed.

## Source-of-Truth Hierarchy

1. `reference/pipeline/*.md` → 2. `reference/recipes/*.md` → 3. `assets/templates/*` → 4. `SKILL.md` → 5. `techniques/*.md` → 6. `reference/*.md` (legacy)

## Pipeline References

Load from `reference/pipeline/` before non-trivial work. Key files by scenario:

- **API shape / version**: `version-matrix.md`, `compatibility.md`
- **Renderer integration**: `rendergraph-compatibility.md`, `rendering-path-boundaries.md`
- **Porting GLSL**: `porting-rules.md`, `authoring-contract.md`
- **Debugging**: `debugging.md`
- **Performance**: `performance.md`
- **Shader Graph requests**: `shadergraph-boundary.md`

## Prototype vs Executable Rule

- `techniques/*.md` and `reference/*.md` contain algorithm notes, not shippable Unity code.
- Translate GLSL idioms before shipping: `vec*` → `float*`, `mix` → `lerp`, `fract` → `frac`, `mod` → `fmod`, `mainImage` → URP fragment, `gl_FragCoord` → UV/clip-space, `iResolution` → `_ScreenParams`, `iChannel*` → bound textures/RTHandles, `iMouse`/`iFrame` → C# driven params.
- Return raw GLSL only when user explicitly asks for prototype math.

## Output Contract

Every substantial implementation must specify:

- **Output type**: `material shader` | `fullscreen shader` | `renderer feature` | `render pass` | `simulation driver` | `supporting include`
- **Files** to create or modify
- **Template basis** and **governing recipe**
- **Legacy technique sources** for the math
- **URP assumptions** and package expectations
- **Material properties** and CBUFFER alignment (material shaders)
- **Render target ownership** when history/ping-pong state is involved (simulations)
- **Unity validation steps**

## Engineering Rules

- Final output in HLSL and ShaderLab syntax.
- Keep `Properties` and `UnityPerMaterial` aligned.
- For fullscreen work: describe renderer feature or driver ownership explicitly.
- For persistent simulation: state buffer ownership, update order, resize policy, invalidation conditions.
- Mention unsupported or cautionary paths when the request needs APIs not covered by current templates.

## Relationship to shader-dev Skill

The `shader-dev` skill covers GLSL/ShaderToy prototyping with 36 technique files. This skill (`unity-shader-dev`) is the Unity URP execution layer. When a request involves both prototyping and Unity deployment:

1. Use `shader-dev` techniques for algorithm exploration and GLSL prototyping.
2. Use this skill to port and integrate into Unity URP.
3. Never return ShaderToy-style GLSL when the user asked for Unity code.
