# Robot Rumble - Godot 4 Port Guidelines


## Project Overview
Porting Robot Rumble from GameMaker Studio 1.x to Godot 4.6. Reference [README.md](README.md) for methodology and [PORTING_REFERENCE.md](PORTING_REFERENCE.md) for GML→GDScript conversions.

## Code Style
- **Language**: GDScript (statically typed where beneficial)
- **Naming**: snake_case for variables/functions, PascalCase for classes/scenes
- **Example**: [scripts/credit_main.gd](scripts/credit_main.gd) demonstrates scrolling controller pattern
- **Indentation**: Tabs (Godot default)
- Comments reference original GameMaker behavior (e.g., `# Equivalent to createStarParticle.gml`)

## Architecture
- **Scene Structure**: Each GameMaker room → Godot scene (`.tscn`)
  - Root: `Node2D`, Background: `ColorRect` (z-index -200), Camera: centered at (960, 540)
  - See [CREDITS_ROOM_REFERENCE.md](CREDITS_ROOM_REFERENCE.md) for complete implementation pattern
- **Autoloads**: `Global` (game state), `MusicManager` (audio) in [project.godot](project.godot)
- **Event Mapping**: Create Event → `_ready()`, Step Event → `_process(delta)`, Draw Event → `_draw()`
- **Z-Index Layers**: Background (-200), Particles (100-300), UI (100), Effects (50), Default (0)

## Build and Test
```bash
# Open project in Godot 4.6
godot --editor project.godot

# Run project
godot --path . res://scenes/credits.tscn
```

## Project Conventions
- **Position Origin**: GameMaker top-left (0,0) → Godot uses per-node origins (Sprite2D centers by default)
- **Frame Timing**: Convert GameMaker frames to seconds: `60 frames = 1.0 second` at 60 FPS
- **Alpha Values**: GML uses 0-1 (same as Godot's `modulate.a`)
- **Particle Pattern**: Spawn periodically via timer in `_process()`, not particle system nodes (see [credit_main.gd](scripts/credit_main.gd#L50-L57))
- **Resource Loading**: Use `preload()` for scenes, `load()` for runtime resources
- **Input Handling**: Alt+Enter fullscreen toggle handled in [Global](scripts/global.gd#L48-L53) singleton

## Integration Points
- **Audio**: `AudioStreamPlayer` nodes in scenes, looping via `finished` signal reconnection ([music_manager.gd](scripts/music_manager.gd#L24-L30))
- **Font Loading**: Press Start 2P loaded in Global, referenced project-wide
- **Scene Transitions**: Via `get_tree().change_scene_to_file()` (stubbed in credits)

## Porting Workflow
1. Study original GML code behavior and visual reference
2. Create scene with proper hierarchy (Background → Camera → Elements)
3. Convert Create Event → `_ready()`, Step → `_process(delta)`, Draw → `_draw()` or node properties
4. Test z-index layering, particle timing, and visual accuracy against reference
5. Document implementation in room-specific reference file
