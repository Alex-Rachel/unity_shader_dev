# Unity URP Compatibility Notes

## Purpose

Use this file as the high-level compatibility index. For concrete boundaries, load the linked pipeline references before committing to an API shape.

## Skill Boundary

This skill is intentionally URP-first and hand-written-shader-first.

## Read These Next

- `version-matrix.md` for Unity / URP support tiers
- `rendergraph-compatibility.md` for Unity 6 compatibility-mode versus RenderGraph guidance
- `rendering-path-boundaries.md` for RenderGraph, compute, XR, Built-in RP, and HDRP boundaries
- `shadergraph-boundary.md` for Shader Graph and hybrid graph-plus-HLSL requests

## Supported Well

- hand-written ShaderLab/HLSL materials in URP
- compatibility-style renderer-feature fullscreen passes
- RenderTexture-driven persistent simulations with explicit ownership

## Supported With Caution

- RTHandle workflows across URP versions
- custom lighting beyond the main-light baseline
- camera texture dependencies that vary by renderer settings
- Unity 6 projects that may expect RenderGraph-first guidance

## Boundary Summary

- RenderGraph: boundary-only unless narrowed to compatibility-style guidance
- Compute-heavy simulation: only a minimal compute starter is shipped; advanced frameworks remain outside primary scope
- XR-specific stereo handling: boundary-only
- Shader Graph: secondary integration target, not the primary authored output path
- Built-in RP and HDRP: outside primary scope

## Required Behavior

When user requirements rely on a boundary area, state the limitation, narrow the implementation to the supported URP path, or explicitly say that a different reference base is needed.
