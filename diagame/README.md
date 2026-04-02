# Robot Rumble - Godot 4 Port

Godot port of the original GameMaker Robot Rumble prototype.

## Current Room Status

- Credits: ported (2D flow + charge room + optional 3D credits scenes)
- Mission Select: ported
- Play Field: ported
- Fight Room: ported
- Home Base: ported (legacy stub behavior retained)

## Documentation Index

- `README.md`: this overview and current structure
- `PORTING_REFERENCE.md`: GameMaker-to-Godot conversion patterns
- `CREDITS_ROOM_REFERENCE.md`: credits-room focused reference
- `TROUBLESHOOTING.md`: common errors and quick fixes

## Current Project Structure

```text
diagame/
├── assets/
│   ├── fonts/
│   ├── sounds/
│   └── sprites/
├── autoload/
│   ├── audio/
│   │   └── music_manager.gd
│   ├── fx/
│   │   └── starfield_manager.gd
│   └── state/
│       └── game_state.gd
├── core/
│   ├── fx/
│   │   ├── markers/
│   │   │   ├── marker.gd
│   │   │   └── marker2.gd
│   │   └── starfield/
│   │       ├── particle_overlay.gd
│   │       ├── particle_overlay.tscn
│   │       ├── particle_star.gd
│   │       ├── particle_star1.tscn
│   │       ├── particle_star2.tscn
│   │       └── particle_star3.tscn
│   └── ui/
│       └── common_menu/
│           └── common_menu.gd
├── features/
│   ├── credits/
│   │   ├── scenes/
│   │   │   ├── charge.tscn
│   │   │   ├── charge_megacharge1.tscn
│   │   │   ├── credit_fade_text.tscn
│   │   │   ├── credits.tscn
│   │   │   ├── credits_3d.tscn
│   │   │   └── credits_text_overlay.tscn
│   │   └── scripts/
│   │       ├── camera_3d_controller.gd
│   │       ├── charge_room.gd
│   │       ├── charge_star.gd
│   │       ├── credit_fade_text.gd
│   │       ├── credit_main.gd
│   │       ├── credits_3d_controller.gd
│   │       └── screen_3d_setup.gd
│   ├── fight_room/
│   │   ├── scenes/fight_room.tscn
│   │   └── scripts/fight_room.gd
│   ├── home_base/
│   │   ├── scenes/home_base.tscn
│   │   └── scripts/home_base.gd
│   ├── mission_select/
│   │   ├── scenes/mission_select.tscn
│   │   └── scripts/mission_select.gd
│   └── play_field/
│       ├── scenes/play_field.tscn
│       └── scripts/play_field.gd
├── CREDITS_ROOM_REFERENCE.md
├── PORTING_REFERENCE.md
└── project.godot
```

## Recent Fix Notes (April 2026)

### 1) Fight Room Parse Errors (indentation/scope)

Symptom:
- Errors like `Cannot use break outside of a loop`, `Unexpected for in class body`, and indentation mismatch in `fight_room.gd`.

Cause:
- A few loop blocks were accidentally over/under-indented, so `break` and `continue` were parsed outside loop scope.

Fix:
- Re-aligned loop bodies in:
  - `features/fight_room/scripts/fight_room.gd` (`_load_mission_state`)
  - `features/fight_room/scripts/fight_room.gd` (`_build_fighter_lines`)
  - `features/fight_room/scripts/fight_room.gd` (`_apply_level_up_rewards`)

### 2) Export-Only Starfield Behavior Drift

Symptom:
- Exported builds showed incorrect star variety/count versus editor runs.

Fixes applied:
- Explicit runtime star variant assignment during spawn (manager -> particle).
- Dedicated RNG usage in starfield manager.
- Frame-rate-independent spawn catch-up and movement scaling.
- Explicit float typing in starfield manager to satisfy warnings-as-errors parse rules.

## Framerate Configuration

Framerate controls are centralized in `autoload/state/game_state.gd` and applied at startup.

- `fps_cap`:
  - `0` = uncapped
  - `> 0` = max render FPS cap
- `physics_tick_rate`: fixed simulation tick rate (`Engine.physics_ticks_per_second`)
- `vsync_enabled`: toggles VSync (`DisplayServer.window_set_vsync_mode`)

Default values currently used:

- `fps_cap = 120`
- `physics_tick_rate = 60`
- `vsync_enabled = false`

Runtime helper methods are also available on `GameState`:

- `set_fps_cap(cap: int)`
- `set_physics_tick_rate(rate: int)`
- `set_vsync_enabled(enabled: bool)`

## Run and Validate

1. Open `diagame/project.godot` in Godot 4.6.x.
2. Run project and navigate to fight room.
3. (Optional) Enable fight-room star debug counts and compare editor vs export.

## Known Non-Blocking Warnings

Some star particle scenes reference stale `uid://...` texture IDs and fall back to resource paths at load time. This does not currently block gameplay, but can be cleaned up by re-saving affected scenes/resources in Godot.
