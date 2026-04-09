# Unity URP Porting Rules

## Rule 1: Preserve the algorithm, replace the host environment

Most legacy snippets in this repository are useful because of their math, not because of their original API surface.

Port like this:

- keep the distance function
- keep the integration loop
- keep the shading logic
- replace the host-specific IO, uniforms, and render loop

## Rule 2: Choose the host before translating code

Do not translate raw snippets until you know the destination:

- Material shader
- Fullscreen effect
- Renderer feature pass
- Persistent simulation update shader

## Rule 3: Match Unity data ownership explicitly

Every port must answer:

- Who creates the texture or RTHandle?
- Who writes it?
- Who reads it?
- When is it resized?
- When is history reset?

## Rule 4: Prefer clean executable scaffolding over clever inline conversion

Start from a known-good template. Then inject the algorithm into the correct function.

Bad workflow:

- copy 300 lines of prototype GLSL
- rename types manually
- hope it compiles

Preferred workflow:

- choose template
- port one core function at a time
- compile-check mentally against ShaderLab/HLSL structure

## Rule 5: Use recipes for task shape

Task recipes define file layout and orchestration. Technique files define formulas. Do not reverse those roles.
