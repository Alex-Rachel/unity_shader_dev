# Fullscreen Post Effect Recipe

## Use This Recipe For

- screen distortions
- blur and bloom-style stages
- color transforms
- edge detection
- camera-space composition

## Default File Set

- Shader: `../../assets/templates/urp-fullscreen.shader`
- Renderer feature: `../../assets/templates/urp-renderer-feature.cs`

## Workflow

1. Keep the shader focused on one fullscreen pass.
2. Bind the source texture explicitly.
3. Inject the pass through a renderer feature.
4. Choose the pass event based on required inputs.
5. If more than one stage is needed, document the intermediate render target ownership.

## Unity Validation

- feature is present on the active renderer
- material is assigned
- effect appears in Frame Debugger
- source and output look correct in RenderDoc or Frame Debugger

## Good Legacy Inputs

- `techniques/post-processing.md`
- `techniques/camera-effects.md`
- `techniques/anti-aliasing.md`
