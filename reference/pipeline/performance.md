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
