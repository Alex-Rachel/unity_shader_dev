# Unity URP Shader Pitfalls Reference

<!-- GENERATED:NOTICE:START -->
> Execution status: legacy deep reference.
> Treat code blocks in this file as algorithm-first GLSL notes unless a section explicitly says Unity URP Executable.
> For runnable Unity output, start from [the authoring contract](pipeline/authoring-contract.md) and the templates in [assets/templates](../assets/templates).
<!-- GENERATED:NOTICE:END -->







## Unity URP Context
This reference supports [webgl-pitfalls](../techniques/webgl-pitfalls.md) and focuses on real failure modes in Unity URP integration rather than browser-specific shader setup.
## Failure Matrix
| Symptom | Root Cause | Verification |
|---|---|---|
| Pink material or pass | Invalid ShaderLab tags, missing URP include, unsupported pragma, or pass not recognized by URP | Inspect console compile output and verify URP-compatible tags/includes |
| Fullscreen effect draws nothing | Renderer feature injection point or source/destination binding is wrong | Check render pass order and inspect bound source texture |
| Inspector sliders do nothing | Property name/type mismatch between Properties and UnityPerMaterial | Compare ShaderLab property block with HLSL declarations |
| History-based effect flickers or freezes | Ping-pong swap or history invalidation is wrong | Log current/next target identities and clear on resize |
| World-space effect swims with camera | Mixed object, world, view, or screen spaces incorrectly | Trace every coordinate transform explicitly |
| Blur radius changes by resolution | Offsets are in pixels instead of texels | Compute offsets from inverse texture size |
| Fluid or CA solver explodes | Delta time, pointer force, or boundary logic is unstable | Clamp external forces and inspect each simulation stage independently |
| Output is clipped or banded | Render texture format is too small for the stored range | Upgrade format or add explicit encode/decode |
## URP-Specific Translation Notes
### Prototype Uniform Mapping
| Prototype name | URP replacement |
|---|---|
| iResolution | _ScreenParams.xy, _ScaledScreenParams.xy, or explicit texture size |
| iTime | _Time.y or custom time property |
| iMouse | C#-provided pointer or gameplay interaction parameters |
| iFrame | C# frame counter or history index |
| iChannel0..n | Material textures, camera textures, RenderTextures, or RTHandles |
| ragCoord | Screen UV or interpolated clip-space/screen-space position |
### Common Resource Mistakes
- Sampling camera depth without enabling the URP depth texture.
- Assuming a fullscreen pass has access to normals or motion vectors without configuring them.
- Reusing a temporary target across frames when persistent history was required.
- Clearing a persistent target every frame by accident during allocation.
### Material vs Fullscreen Split
Ask this first:
- If the effect belongs to a mesh, decal, terrain, water surface, or object-local raymarch, implement it as a material shader.
- If the effect transforms camera color, accumulates history, or depends on screen-space buffers, implement it as a fullscreen/custom pass.
Most broken ports come from choosing the wrong path and then compensating with fragile hacks.
## Debug Workflow
### 1. Prove pass execution
- Add a constant color output.
- Confirm the pass appears in Frame Debugger / RenderDoc capture.
- Only then reintroduce texture sampling and lighting.
### 2. Prove inputs
- Visualize UV, normals, depth, or history directly as colors.
- If the debug view is wrong, the effect logic is not the first problem.
### 3. Prove resource lifetime
- For ping-pong systems, log which target is current and next each frame.
- Reset history on camera resize, pipeline changes, and scene reloads when appropriate.
### 4. Prove numeric range
- Visualize intermediate fields such as pressure, dye, AO, or shadow terms before tone mapping.
- If values are saturating, check format and scale before adjusting equations.
## Code Smells
- One shader trying to behave as both a material and a fullscreen pass without a clear abstraction boundary.
- Hidden dependence on _ScreenParams in code that actually samples a lower-resolution simulation texture.
- Implicit assumption that a texture survives across frames without explicit ownership on the C# side.
- Property names prefixed differently between ShaderLab and HLSL.
- Multiple passes writing logically different data into one texture without documented channel layout.
## Recommended Baseline Patterns
- Use TEXTURE2D and SAMPLE_TEXTURE2D for bound textures.
- Use RTHandle for camera-relative intermediate targets.
- Use persistent RenderTexture objects for history that must survive across frames.
- Keep solver pass, visualization pass, and gameplay input code separate.
- Document channel packing whenever a state buffer carries more than one logical field.