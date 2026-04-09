# Unity URP Performance Notes

## Primary Risks

- too many texture samples per pixel
- excessive fullscreen passes
- overdraw on translucent surfaces
- history buffers at full resolution when half resolution is acceptable
- too many shader keywords or variants

## Material Shader Guidance

- keep interpolators tight
- use `half` only after verifying visual stability
- avoid redundant world-space recomputation in fragment stage
- use packed mask textures when the art pipeline supports it

## Fullscreen Guidance

- prefer half or quarter resolution for blur-like effects
- avoid multiple readbacks of the same full-resolution texture when one prepass can cache it
- document whether the effect is bandwidth-bound or ALU-bound

## Simulation Guidance

- define a fixed simulation resolution independent from camera resolution when possible
- invalidate history on resolution changes or topology changes
- keep channel ownership explicit to avoid extra buffers

## Unity-Specific Concerns

- keep material properties SRP Batcher friendly by avoiding ad hoc global state when per-material values are sufficient
- minimize multi_compile usage unless the variant is genuinely required
- review mobile precision separately from desktop assumptions

## Mobile Precision Strategy

### half vs float Decision Tree

1. **Use `half` (16-bit) for:**
   - Color values (albedo, light color, ambient)
   - UV coordinates in fragment shader
   - Normal map samples and derived normals
   - Fresnel terms, rim lighting factors
   - Smoothness and roughness parameters

2. **Use `float` (32-bit) for:**
   - World-space positions (positionWS)
   - Clip-space positions (positionCS)
   - Shadow coordinate calculations
   - Ray origin and direction in raymarching
   - SDF distance fields (precision affects convergence)
   - Any value used as a loop termination condition

3. **Platform-dependent behavior:**
   - Desktop (D3D11/Vulkan/Metal): `half` is often promoted to `float` — no actual precision loss but also no performance gain
   - Mobile (GLES3/Vulkan): `half` maps to `mediump` — real 16-bit, significant ALU and register savings
   - Console: varies by platform, test empirically

### Precision Issue Case Studies

- **Banding in smooth gradients**: Smooth lighting transitions may show banding when computed in `half`. Fix: use `float` for the lighting accumulation and convert to `half` only for the final output.
- **SDF step artifacts**: Raymarching with `half` distance values causes visible stepping errors. Fix: keep all SDF calculations in `float`.
- **World-space UV distortion**: Large meshes with world-space UVs computed in `half` show visible texture swimming. Fix: use `float` for positionWS before computing UV.

### Platform Precision Differences

| Platform | half precision | float precision | Impact |
| --- | --- | --- | --- |
| D3D11 Desktop | 32-bit (promoted) | 32-bit | No visible difference; use half for documentation |
| Vulkan Desktop | 32-bit (promoted) | 32-bit | Same as D3D11 |
| Metal Desktop | 32-bit (promoted) | 32-bit | Same as D3D11 |
| GLES3 Mobile | 16-bit (real) | 32-bit | half saves bandwidth and ALU; verify visually |
| Vulkan Mobile | 16-bit (real) | 32-bit | Same as GLES3 |
| Metal Mobile | 16-bit (real) | 32-bit | Same as GLES3 |

## FallBack / QueueOffset / Cull Best Practices

### FallBack

- Always declare `FallBack "Hidden/Universal Render Pipeline/FallbackError"` at the end of every SubShader
- This ensures a sensible error shader instead of the default magenta when compilation fails
- Without FallBack, broken shaders render as hot pink — confusing for debugging and unacceptable in production

### QueueOffset

- Use `[HideInInspector] _QueueOffset("Queue Offset", Range(-50, 50)) = 0.0` as a material property
- Adjust `material.renderQueue` in a custom editor script or via code: `material.renderQueue = baseQueue + offset`
- Common use cases:
  - Rendering decals slightly after geometry: `_QueueOffset = 1`
  - Ensuring an object renders before others for special effects: `_QueueOffset = -1`
- Do NOT modify the SubShader Tags Queue string dynamically — ShaderLab does not support variable interpolation in Tags

### Cull Mode

- Use `[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2.0` for a dropdown in the Inspector
- Apply with `Cull [_Cull]` in each Pass (except Meta, which should always use `Cull Off`)
- Default value 2.0 = Back culling (standard for opaque)
- Value 0.0 = Off (double-sided, useful for foliage, thin geometry)
- Value 1.0 = Front culling (rare, used for inside-out effects or depth prepass tricks)
