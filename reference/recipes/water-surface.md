# Water Surface Recipe

## Use This Recipe For

- stylized water
- reflective water planes
- animated normal-driven water
- shallow water with simple depth tint

## Default File Set

- Shader: `../../assets/templates/urp-forward-lit.shader`

## Workflow

1. Start with a lit surface shader.
2. Add wave displacement or normal animation in a controlled step.
3. Add fresnel and reflection after base lighting is stable.
4. Add depth-based tint only if the project has the required scene texture path.

## Required Final Notes

- whether the water is opaque, transparent, or alpha-clipped
- whether it relies on scene depth or opaque texture
- whether it uses vertex displacement, normal animation, or both

## Good Legacy Inputs

- `techniques/water-ocean.md`
- `techniques/lighting-model.md`
- `techniques/atmospheric-scattering.md`
