# Unity Shader Authoring Contract

## Purpose

This file defines what counts as an acceptable deliverable for this skill.

## Final Output Requirements

A valid Unity implementation from this skill must include executable code and integration guidance.

Minimum acceptable output:

- At least one runnable ShaderLab/HLSL or C# file shape
- The delivery path being used
- The Unity-side ownership model
- Validation steps

## Code Classification

Use these labels internally when reading the repository:

- `Executable Unity code`: ready to place in a Unity project with normal adaptation
- `Prototype GLSL`: math-first snippet that must be translated before use
- `Pseudocode`: orchestration outline, not shippable code

## Translation Rules

When converting prototype GLSL into Unity output:

- `vec2/vec3/vec4` -> `float2/float3/float4`, `half*` only when precision is proven safe
- `mix` -> `lerp`
- `fract` -> `frac`
- `mod` -> `fmod`
- `mainImage` -> explicit URP fragment function
- `gl_FragCoord` -> UV or clip-space derived values
- `iResolution` -> `_ScreenParams` or explicit property
- `iChannel*` -> bound textures, camera textures, RTHandles, or RenderTextures
- `iMouse` / `iFrame` -> C# driven parameters

## Required Unity Details

### Material shaders

- `Properties`
- `UnityPerMaterial` CBUFFER alignment
- URP include paths
- vertex + fragment entrypoints

### Fullscreen passes

- source texture binding contract
- renderer feature or driver ownership
- pass event choice
- validation in Frame Debugger

### Persistent simulations

- buffer count
- buffer lifetime
- resize behavior
- invalidation behavior
- read/write separation

## Red Flags

Reject or rewrite answers that:

- return only prototype GLSL when the user asked for Unity code
- mix GLSL syntax into files claimed to be executable HLSL
- omit `Properties` / `CBUFFER_START(UnityPerMaterial)` pairing for material shaders
- describe history buffers without specifying ownership or swap order
- rely on vague phrases like “hook this into URP somehow”
