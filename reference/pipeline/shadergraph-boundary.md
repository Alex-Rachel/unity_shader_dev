# Shader Graph Boundary

## Purpose

Use this file when the user request mentions Shader Graph, Custom Function, artist-authored graphs, or hybrid graph plus HLSL workflows.

## Default Position

- This skill is hand-written URP ShaderLab/HLSL first.
- Shader Graph is a secondary integration target, not the primary authored output.

## When This Skill Still Fits

- the user needs HLSL logic that can later be adapted into a Shader Graph Custom Function
- the user needs a reference implementation before rebuilding the effect in Shader Graph
- the project uses Shader Graph for material assembly but still needs a hand-written fullscreen pass or renderer feature

## When To Narrow The Answer

- If the user wants a full node-by-node Shader Graph authoring workflow, say that this skill is not a primary Shader Graph authoring guide.
- If the user wants graph screenshots, graph asset layout, or artist-facing graph UX, keep the answer at the boundary note level unless additional graph-specific references exist.

## Hybrid Workflow Guidance

For hybrid requests:

1. Separate graph-owned responsibilities from code-owned responsibilities.
2. Keep reusable math in HLSL-style helper form.
3. State whether the final deliverable is:
   - `hand-written shader`
   - `Shader Graph custom-function support code`
   - `renderer feature / fullscreen pass outside Shader Graph`

## Do Not Overclaim

- Do not claim a `.shadergraph` asset can be produced from the current templates.
- Do not present hand-written ShaderLab as if it were a full Shader Graph equivalent.
- Do not hide the fact that some requests are better served by a graph-first workflow outside this skill's main scope.
