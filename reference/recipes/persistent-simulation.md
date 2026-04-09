# Persistent Simulation Recipe

## Use This Recipe For

- fluids
- reaction-diffusion
- cellular automata
- temporal accumulation
- any effect that reads previous state each frame

## Default File Set

- Update shader: `../../assets/templates/urp-ping-pong-update.shader`
- Driver: `../../assets/templates/urp-ping-pong-simulation-driver.cs`

## Workflow

1. Fix the simulation resolution first.
2. Allocate two state textures.
3. Read from current, write into next.
4. Swap after each update.
5. Expose explicit reset conditions.

## Required Notes In Final Output

- simulation resolution
- texture format
- what each channel stores
- who consumes the current state

## Good Legacy Inputs

- `techniques/fluid-simulation.md`
- `techniques/cellular-automata.md`
- `techniques/simulation-physics.md`
- `techniques/multipass-buffer.md`
