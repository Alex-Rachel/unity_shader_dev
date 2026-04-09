# Mesh Surface Effect Recipe

## Use This Recipe For

- stylized materials
- UV or triplanar driven surface effects
- custom lit objects
- animated surface shading

## Default File Set

- Shader: start from `../../assets/templates/urp-unlit-material.shader` or `../../assets/templates/urp-forward-lit.shader`
- Optional C# driver: add only if time/input/interaction needs runtime control

## Workflow

1. Pick `unlit` or `forward lit`.
2. Define the material properties first.
3. Mirror every per-material property inside `UnityPerMaterial`.
4. Port only the effect logic into the fragment function.
5. Keep geometry ownership local to the object unless the effect actually needs screen-space data.

## Unity Validation

- assign the shader to a material
- place on a test mesh
- verify texture transforms and property updates
- confirm no console compile errors

## Good Legacy Inputs

- `techniques/lighting-model.md`
- `techniques/texture-sampling.md`
- `techniques/color-palette.md`
