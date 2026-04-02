# Troubleshooting

Quick index for common Godot-port issues in this repository.

## Symptom Index

- Parse error: `Cannot use "break" outside of a loop` / `Unexpected "for" in class body`
  - See [1) Indentation and Loop Scope Errors](#1-indentation-and-loop-scope-errors)
- Parse warning treated as error: `variable type is being inferred from a Variant value`
  - See [2) Variant Inference Warnings (Warnings-As-Errors)](#2-variant-inference-warnings-warnings-as-errors)
- Export differs from editor: fight-room stars show one type or lower count
  - See [3) Export vs Editor Starfield Mismatch](#3-export-vs-editor-starfield-mismatch)
- Warning on load: `ext_resource, invalid UID` in star particle scenes
  - See [4) Invalid Resource UID Warnings](#4-invalid-resource-uid-warnings)

## 1) Indentation and Loop Scope Errors

### Typical errors

- `Cannot use "break" outside of a loop`
- `Cannot use "continue" outside of a loop`
- `Unexpected "for" in class body`
- `Unindent doesn't match the previous indentation level`

### Root cause

A block inside a function drifted one indentation level too far left/right, so loop-only keywords were parsed outside loop scope.

### What to check

- `features/fight_room/scripts/fight_room.gd`
- Functions with nested loops/conditions:
  - `_load_mission_state`
  - `_build_fighter_lines`
  - `_apply_level_up_rewards`

### Fix pattern

- Ensure every nested block is indented consistently.
- Keep `break`/`continue` inside the nearest `for`/`while` block.
- Avoid mixed indentation style in the same function.

## 2) Variant Inference Warnings (Warnings-As-Errors)

### Typical error

- `The variable type is being inferred from a Variant value, so it will be typed as Variant. (Warning treated as error.)`

### Root cause

A declaration used inferred typing from a Variant-returning expression (for example, generic `max(...)`), and project settings treat warnings as errors.

### Fix pattern

- Prefer explicit types:
  - `var value: int = ...`
  - `var value: float = ...`
  - `var value: Vector2 = ...`
- Prefer typed math helpers where useful:
  - `maxf(...)`, `minf(...)` for floats
  - `maxi(...)`, `mini(...)` for ints

### Example used in this repo

In `autoload/fx/starfield_manager.gd`, changed:

- `var safe_interval := max(0.01, spawn_interval)`
- to `var safe_interval: float = maxf(0.01, spawn_interval)`

## 3) Export vs Editor Starfield Mismatch

### Typical symptoms

- Fight-room stars look different in export than in editor.
- One star type appears disproportionately.
- Active star count appears lower in export.

### Root causes addressed in this project

- Variant/type assignment relied on scene/script serialization assumptions.
- Spawn/motion behavior depended too strongly on per-frame timing.

### Fixes implemented

- Explicit star variant assignment from manager to spawned particle.
- Dedicated RNG usage in starfield manager.
- Frame-rate-independent spawning (catch-up loop).
- Frame-rate-independent star movement scale.

### Files involved

- `autoload/fx/starfield_manager.gd`
- `core/fx/starfield/particle_star.gd`

## 4) Invalid Resource UID Warnings

### Typical warning

- `ext_resource, invalid UID ... using text path instead`

### Impact

Usually non-blocking if the fallback path resolves correctly.

### Cleanup

- Open affected scenes in Godot and re-save them.
- Reimport affected textures if needed.
- Commit updated `.tscn` metadata after confirming no behavior change.

## Quick Diagnostic Command

Use Godot headless parse to catch script errors quickly:

```powershell
& 'f:\Dev\GODOT\Godot_v4.6-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'f:\Dev\robot-rumble\diagame' --quit
```

If parse errors are gone but runtime behavior still differs in export, compare fight-room star debug counters between editor and export builds.
