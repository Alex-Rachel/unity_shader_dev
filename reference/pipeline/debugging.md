# Unity URP Debugging Workflow

## Compile Failures

Check in this order:

1. Wrong include path
2. GLSL syntax left in HLSL file
3. `Properties` and `UnityPerMaterial` mismatch
4. Wrong semantic names such as missing `SV_POSITION` or `SV_Target`
5. Missing texture/sampler declarations

## Pink Material or Missing Pass

Check:

- shader `RenderPipeline` tag is `UniversalPipeline`
- pass `LightMode` matches intended use
- shader asset actually assigned to the material
- console compile error details

## Fullscreen Effect Not Visible

Check:

- renderer feature is added to the active renderer
- pass event is late enough for the desired source texture
- material is assigned
- `_SourceTexture` or camera source is bound
- Frame Debugger shows the pass executing

## Simulation Not Persisting

Check:

- different read and write targets are used each update
- textures are not recreated every frame
- resolution stays stable across frames
- clear/reset only happens on initialization or explicit invalidation

## Recommended Debug Sequence

1. Confirm shader compiles
2. Confirm pass executes in Frame Debugger
3. Confirm source texture contains expected data
4. Confirm output target changes after the pass
5. Confirm material parameters are non-default

## Tools

- Unity Console
- Frame Debugger
- RenderDoc when the frame graph is non-obvious
- Temporary debug color output in fragment shader
