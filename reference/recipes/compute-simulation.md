# Compute Simulation Recipe

## Use This Recipe For

- kernel-based grid simulations
- lightweight compute-driven reaction-diffusion or cellular updates
- state updates that are awkward to express as fullscreen material passes
- requests that explicitly ask for a compute shader path

## Default File Set

- Compute shader: `../../assets/templates/compute-simulation.compute`
- Driver: `../../assets/templates/compute-simulation-driver.cs`

## Workflow

1. Fix the simulation resolution first.
2. Define one kernel that reads from current state and writes to next state.
3. Keep read and write targets separate.
4. Dispatch using thread-group counts derived from the chosen kernel size.
5. Swap buffers only after the dispatch completes.
6. Expose explicit reset conditions and format assumptions.

## Required Notes In Final Output

- simulation resolution
- render texture format
- kernel thread-group size
- what each texture channel stores
- who reads the current state after the compute step

## Good Legacy Inputs

- `techniques/fluid-simulation.md`
- `techniques/cellular-automata.md`
- `techniques/simulation-physics.md`
- `techniques/multipass-buffer.md`
