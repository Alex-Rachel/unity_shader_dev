# Unity URP Shader Pitfalls

<!-- GENERATED:NOTICE:START -->
> Execution status: prototype algorithm reference.
> Treat code blocks in this file as GLSL-style algorithm notes unless a section explicitly says Unity URP Executable.
> For runnable Unity output, start from [the authoring contract](../reference/pipeline/authoring-contract.md) and the templates in [assets/templates](../assets/templates).
<!-- GENERATED:NOTICE:END -->







## Unity URP Note
Use this document when a shader compiles but renders incorrectly, when a fullscreen pass behaves differently from a material shader, or when a ShaderToy-style prototype needs to be translated into production URP code.
## Use Cases
- Debugging ShaderLab or HLSL compile failures
- Porting compact GLSL or ShaderToy-style snippets into URP
- Diagnosing black screens, pink materials, invalid blits, or broken history buffers
- Verifying that a fullscreen effect and a material shader use the correct URP inputs
## Critical URP Rules
### 1. Stop treating prototype snippets as final shader entry points
Prototype code often uses mainImage, ragCoord, iResolution, and iChannel0. In URP these are only conceptual placeholders.
- mainImage(...) becomes a normal fragment function
- ragCoord becomes screen UV or clip-space derived position
- iResolution becomes _ScreenParams.xy or _ScaledScreenParams.xy
- iChannel0..n become explicitly bound textures or RTHandles
- iTime becomes _Time.y or a custom property
### 2. Match ShaderLab properties to HLSL constant buffers
If a property exists in Properties, mirror it in CBUFFER_START(UnityPerMaterial) with matching name and type. Mismatches lead to values that appear stuck, random, or zero.
### 3. Use URP texture macros consistently
Prefer:
`glsl
TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
```
Do not mix old built-in pipeline sampling idioms with URP conventions unless the project already standardizes on a compatibility layer.
### 4. Do not sample and write the same render target in one pass
Fullscreen feedback effects must ping-pong between two targets. If a pass reads from the same target it writes to, the result is undefined.
### 5. Distinguish simulation resolution from presentation resolution
Physics, reaction-diffusion, fluid, and accumulation passes often run at fixed internal resolution. Final shading may run at camera resolution. Bugs appear when _ScreenParams is used where simulation texel size was required.
### 6. Treat camera-space data as opt-in URP resources
Depth, normals, motion vectors, and opaque textures are not implicit. If the effect needs them, document and enable the URP resource explicitly.
### 7. Rebuild history after camera or descriptor changes
Temporal AA, accumulation, reprojection, and simulation history become invalid after resolution changes, renderer reconfiguration, or camera switches. Clear or recreate history buffers when descriptors change.
## High-Frequency Failures
| Symptom | Likely Cause | Fix |
|---|---|---|
| Pink material | ShaderLab pass tags, includes, or pragmas incompatible with URP | Verify pipeline tags, includes, and target pragmas |
| Fullscreen pass renders black | Source texture not bound, wrong injection point, or pass order issue | Check renderer feature setup and source/destination wiring |
| Material ignores inspector values | Property and constant buffer names/types do not match | Align Properties with UnityPerMaterial |
| Simulation freezes after one frame | Read/write targets were not swapped | Swap ping-pong buffers in C# after each step |
| Severe stretching or offset | Screen UV built from the wrong coordinate space | Derive UV from URP varyings or _ScreenParams consistently |
| Noise or blur changes with resolution | Using pixel offsets instead of texel size | Multiply offsets by inverse texture size |
| Interaction feels explosive | Raw pointer delta fed directly into solver | Clamp and normalize in C#, then clamp again in shader if needed |
| Temporal trails persist after resize | History buffer reused across descriptor change | Reallocate or clear history on resize |
## Translation Checklist
When converting a prototype shader into URP:
1. Decide whether the effect is a material shader or a fullscreen/custom pass.
2. Replace prototype uniforms with URP properties and bound resources.
3. Build a proper Attributes/Varyings path or a fullscreen triangle input path.
4. Move frame orchestration, history swapping, and pointer handling into C#.
5. Validate render target ownership for every pass in the chain.
## Practical Debug Order
1. Confirm the shader compiles and the correct pass executes.
2. Confirm material properties and textures are actually bound.
3. Validate the render target descriptor and format.
4. Verify UV construction and texel size math.
5. Inspect whether the effect needs history, depth, or normals and whether URP is providing them.
6. For multi-pass effects, verify the pass order and ping-pong swap logic.
## Further Reading
See [reference/webgl-pitfalls.md](../reference/webgl-pitfalls.md) for a deeper URP-focused troubleshooting reference.