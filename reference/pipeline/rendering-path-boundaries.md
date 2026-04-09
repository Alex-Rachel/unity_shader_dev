# Rendering Path Boundaries

## Purpose

Use this file to decide whether the request fits the supported URP templates or must be narrowed.

## Well Supported

- hand-written URP material shaders
- renderer-feature based fullscreen effects in compatibility-style workflows
- RenderTexture or RTHandle history buffers with explicit ownership
- object-space raymarching inside a material shader

## Supported With Explicit Caution

### RenderGraph

- Do not present current renderer-feature templates as native RenderGraph implementations.
- If the project is RenderGraph-first, either:
  - narrow to a compatibility-style example, or
  - provide a boundary note instead of pretending the exact API shape is covered.

### Compute-heavy workflows

- This skill now ships a minimal compute starter, but not a full compute framework.
- For dense fluids, particle solvers, signed-distance baking, or multi-stage simulation graphs, say that the shipped compute template is only a single-kernel starter.
- If the request exceeds that scope, narrow to either:
  - the simpler compute starter path, or
  - the existing Blit/RenderTexture ping-pong path.

### XR

- XR-specific stereo handling, single-pass instancing details, and eye-dependent fullscreen paths are not a primary support area.
- Do not imply XR correctness unless the user supplies project-specific XR constraints and the answer stays narrow.

## Out of Primary Scope

- Built-in Render Pipeline production support
- HDRP custom pass or HDRP material model guidance
- compute-native simulation frameworks
- RenderGraph-first production architecture
- XR-optimized fullscreen or post-processing integration

## Required Boundary Behavior

When a request crosses these boundaries:

1. Name the unsupported area directly.
2. State what part of the request is still covered.
3. Offer the narrowest supported fallback.
4. Do not silently mix unsupported APIs into a claimed runnable solution.

## Example Boundary Statements

- `This skill covers the URP compatibility-style renderer feature path, not a native RenderGraph implementation.`
- `This request is simulation-heavy enough that a compute path would be more appropriate; the shipped templates only cover RenderTexture ping-pong updates.`
- `This effect can be prototyped in URP, but XR-specific stereo correctness is outside the current template coverage.`
