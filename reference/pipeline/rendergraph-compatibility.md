# Unity 6 RenderGraph Compatibility Notes

## Purpose

Use this file when a request mentions Unity 6, RenderGraph, compatibility mode, or a renderer feature that may need a Unity 6 migration note.

## Baseline Position

- The shipped fullscreen templates are compatibility-style renderer feature scaffolds.
- They are acceptable as a conservative fallback for Unity 6 projects that still allow compatibility-mode style integration.
- They are not a source-of-truth native RenderGraph implementation.

## Required Behavior

When the project is Unity 6 or newer:

1. State whether the answer assumes compatibility mode.
2. Do not describe compatibility-mode templates as if they were native RenderGraph code.
3. If the user explicitly asks for native RenderGraph, narrow the answer to:
   - migration notes,
   - ownership notes,
   - or a boundary statement if the exact API shape is not covered.

## Safe Compatibility-Mode Guidance

It is safe to say:

- a fullscreen shader can still be authored independently from the renderer integration path
- a compatibility-style renderer feature may be used when the project enables that workflow
- material shaders remain the most stable path across URP versions

## Unsafe Overclaims

Do not claim:

- the current `urp-renderer-feature.cs` template is a native RenderGraph pass
- the skill fully covers Unity 6 RenderGraph APIs
- camera target access details are identical between compatibility mode and native RenderGraph flows

## Recommended Answer Pattern

- `Assumed Unity 6 URP compatibility-mode workflow for renderer integration.`
- `If the project is RenderGraph-first, keep the shader logic and re-home only the pass orchestration in the project's native RenderGraph path.`
