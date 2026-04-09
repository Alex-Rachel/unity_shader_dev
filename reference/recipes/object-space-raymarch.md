# Object-Space Raymarch Recipe

## Use This Recipe For

- SDF objects rendered inside mesh bounds
- portal/window bound raymarching
- local-space procedural solids

## Default File Set

- Shader: `../../assets/templates/urp-unlit-material.shader`

## Workflow

1. Use a bounded mesh, usually cube or proxy volume.
2. Compute object-space ray origin and direction.
3. March inside object space.
4. Convert hit normal and shading into the chosen output model.
5. Keep step counts and bailout conditions explicit.

## Why This Recipe Exists

Raymarching in Unity is stable when the object owns its bounds. It becomes much harder when treated like a fullscreen effect by default.

## Good Legacy Inputs

- `techniques/ray-marching.md`
- `techniques/sdf-3d.md`
- `techniques/normal-estimation.md`
