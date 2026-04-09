# Advanced Texture Mapping Detailed Reference

<!-- GENERATED:NOTICE:START -->
> Execution status: legacy deep reference.
> Treat code blocks in this file as algorithm-first GLSL notes unless a section explicitly says Unity URP Executable.
> For runnable Unity output, start from [the authoring contract](pipeline/authoring-contract.md) and the templates in [assets/templates](../assets/templates).
<!-- GENERATED:NOTICE:END -->

<!-- GENERATED:TOC:START -->
## Table of Contents

- [Unity URP Context](#unity-urp-context)
- [Prerequisites](#prerequisites)
- [Triplanar vs Biplanar Cost Analysis](#triplanar-vs-biplanar-cost-analysis)
  - [Weight Remapping Mathematics](#weight-remapping-mathematics)
  - [Gradient Propagation](#gradient-propagation)
- [Ray Differential Mathematics](#ray-differential-mathematics)
  - [Problem Statement](#problem-statement)
  - [Solution: Tangent Plane Intersection](#solution-tangent-plane-intersection)
  - [For Perspective Cameras (Common Case)](#for-perspective-cameras-common-case)
  - [Chain Rule for Texture Coordinates](#chain-rule-for-texture-coordinates)
- [Texture Repetition Theory](#texture-repetition-theory)
  - [Why Tiling is Visible](#why-tiling-is-visible)
  - [Breaking Repetition](#breaking-repetition)
<!-- GENERATED:TOC:END -->








## Unity URP Context
Read this reference as Unity URP support material. Compact snippets capture the core shading math; integrate them into ShaderLab + HLSL, feed state through material properties or C# scripts, and use renderer features, fullscreen passes, RTHandles, or RenderTextures whenever the technique depends on camera buffers, accumulation, or ping-pong state.

## Prerequisites
- Screen-space derivatives (`dFdx`, `dFdy`)
- `textureGrad()` function usage
- Basic ray marching

## Triplanar vs Biplanar Cost Analysis

| Aspect | Triplanar | Biplanar |
|--------|-----------|----------|
| Texture fetches | 3 | 2 |
| ALU operations | Lower | Higher (axis selection) |
| Bandwidth | Higher | Lower |
| Visual quality | Baseline | Equivalent (k�?) |
| Best for | Bandwidth-rich GPUs | Mobile, bandwidth-limited |

Modern GPUs are typically bandwidth-limited rather than ALU-limited, making biplanar the better default choice.

### Weight Remapping Mathematics

The biplanar weight formula `clamp((w - 0.5773) / (1.0 - 0.5773), 0, 1)` ensures:
- At normals aligned with one axis: weight = 1.0 (clean projection)
- At 45° diagonals where 2 axes are equal: smooth transition
- At the cube diagonal (1/�? �?0.5773): weight = 0.0, but this is the point where the third (discarded) projection would be needed �?biplanar's approximation error is maximal here but visually acceptable

### Gradient Propagation

Using `textureGrad()` instead of `texture()` is essential because:
1. Axis selection (`ma`, `me`) creates UV discontinuities at projection boundaries
2. Hardware `texture()` computes mip from implicit derivatives, which spike at discontinuities �?visible seams
3. `textureGrad()` with manually propagated `dFdx(p)`, `dFdy(p)` bypasses this, keeping gradients smooth across boundaries

## Ray Differential Mathematics

### Problem Statement
In rasterization, `dFdx`/`dFdy` of texture coordinates work naturally because adjacent pixels map to nearby surface points. In ray marching, adjacent pixels may hit completely different objects �?broken mip selection.

### Solution: Tangent Plane Intersection

Given:
- Primary ray hits surface at `pos` with normal `nor`
- Neighbor pixel ray `rd_neighbor` originates from `ro_neighbor`

The neighbor ray's intersection with the tangent plane at `pos`:
```
t_neighbor = dot(pos - ro_neighbor, nor) / dot(rd_neighbor, nor)
pos_neighbor = ro_neighbor + rd_neighbor * t_neighbor
```

The difference `pos_neighbor - pos` gives the world-space footprint of one pixel at the hit point.

### For Perspective Cameras (Common Case)
```
ro is the same for all pixels, only rd varies:
dposdx = t * (rdx * dot(rd, nor) / dot(rdx, nor) - rd)
dposdy = t * (rdy * dot(rd, nor) / dot(rdy, nor) - rd)
```
Where `rdx = rd + dFdx(rd)` and `rdy = rd + dFdy(rd)`.

### Chain Rule for Texture Coordinates
If texture mapping function is `uv = f(pos)`:
```
duvdx = Jacobian(f) × dposdx
duvdy = Jacobian(f) × dposdy
```
For simple planar mapping `uv = pos.xz`:
```
duvdx = dposdx.xz
duvdy = dposdy.xz
```

## Texture Repetition Theory

### Why Tiling is Visible
Human vision excels at detecting:
1. **Periodic patterns**: Regular grid alignment
2. **Unique features**: Distinctive spots/marks that repeat identically
3. **Phase alignment**: All tiles start at the same phase

### Breaking Repetition
Each method targets different cues:
- **Random offset** (Method A): Breaks phase alignment, 4 fetches
- **Voronoi blend**: Breaks grid structure entirely, 9 fetches (expensive)
- **Virtual pattern** (Method B): Breaks unique features cheaply, 2 fetches

Method B is preferred for real-time use �?the low-frequency index variation is cache-friendly and the two texture fetches share locality.
