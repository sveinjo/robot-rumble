# Robot Rumble - Godot 4 Port

This is a port of Robot Rumble from GameMaker Studio 1.x to Godot 4.6.

## Current Status

**Credits Room - COMPLETE ✓**
- Black background
- Press Start 2P font (arcade style) at size 18
- Horizontally centered scrolling story text with blue shadow effect
- Background starfield with three types of particle stars (inverted parallax effect)
  - Small stars move fastest (6× speed) - far background
  - Medium stars at normal speed (4× speed)
  - Large stars move slowest (2× speed) - closer foreground
- Two rotating flare markers (slow counter-rotation)
- Fading credit text (Music, Art, Game Design) - visible before scrolling starts
- Background music playback (bgmusic.mp3) with proper audio settings
- Alt+Enter fullscreen toggle

**Charge Room - PORTED (Legacy Intro Flow) ✓**
- MegaCharge splash art at original placement
- Clickable mega charge area transitions to Credits (matching GM room flow)
- Custom directional star streaks replicated from `starDirectional`:
  * Spawn from random x at top or bottom edge
  * Move toward screen center with accelerating speed (`* 1.03` per frame)
  * Stretch on x-axis as speed increases
  * Self-destroy when crossing the center y-band (520-560)
- Dedicated room star behavior runs with shared persistent starfield disabled
- Center flare pair spins in opposite directions at original cadence

**MissionSelect Room - PORTED (Gameplay Transition Stubs) ✓**
- 3x3 mission grid generated from hero levels (center slot is Home Base until overtaken)
- Mission card fade-in for newly generated missions
- Hover state shows mission XP reward like the GameMaker behavior
- Click mission card stores `Global.intMissionSelected` and attempts transition to play field
- Left-side hero roster with class/level/xp/ability summary
- Imported original GameMaker background, hero portraits, enemy portraits, and frame art

**PlayField Room - PORTED (Battle Execution) ✓**
- Hero roster on left (5 heroes, clickable)
- Enemy preview on top right (3 enemies from selected mission)
- Battle squad engagement slots in center (up to 3 heroes)
- Win chance calculation based on:
  * Base 50/3% per hero (~16.7%)
  * Counter bonus: +100/3% if hero ability matches enemy ability
  * Level modifier: 0x (3+ behind) → 1.5x (2+ ahead)
- Fight button transitions to fight_room battle scene
- Right-click returns to mission select without fighting

**FightRoom - PORTED (Animated Resolution) ✓**
- Loads selected heroes vs mission enemies in battle lanes
- Uses win chance from PlayField and resolves battle in room
- Animated strike sequence with dash, fade-out, and victory jump effects
- Starfield and flare ambience during combat
- XP reward and level-up applied on victory
- Mission cleared on victory and return button enabled at battle end

**HomeBase Room - PORTED (Legacy Stub Behavior) ✓**
- Restored original homeBase visual layout with backgroundBase and heading text
- Left-side roster cards + center utility 2x3 grid (CARBS/PROTEIN/FATS/FAST INSULIN/HERO/SLOW INSULIN)
- Ambient center markers and star particles
- CANCEL button and right-click both return to mission select
- Preserves original "HOME BASE NOT OPERATIONAL" behavior (no gameplay mechanics yet)

**Audio Settings Finalized:**
- V-sync disabled to prevent audio timing issues
- Output latency: 15ms (balances smoothness and delay)
- Mix rate: 44100 Hz (standard CD quality)
- Volume: -6dB to prevent over-amplification
- Looping enabled on background music

**✅ Ready for Repository** - This clean implementation serves as a baseline for porting additional rooms.

## Documentation Files

- **README.md** (this file) - Overview, methodology, and comprehensive porting guide
- **PORTING_REFERENCE.md** - Quick reference for GameMaker → Godot conversions
- **CREDITS_ROOM_REFERENCE.md** - Complete implementation details of the working credits room

## Porting Methodology

### Room Conversion Pattern (GMX → Godot)

Each GameMaker room becomes a Godot scene (`.tscn` file) following this structure:

1. **Root Node**: `Node2D` for 2D rooms
2. **Background**: `ColorRect` (solid color) or `TextureRect` (image) at z-index -200
3. **Camera**: `Camera2D` positioned at viewport center (960, 540)
4. **Visual Elements**: Sprites, particles, UI at appropriate z-index layers
5. **Room Script**: Attached to root or dedicated controller node

### GameMaker Event Mapping

| GameMaker Event | Godot Equivalent | Notes |
|----------------|------------------|-------|
| Create Event | `_ready()` | Runs once when node enters scene tree |
| Step Event | `_process(delta)` | Runs every frame, delta = time since last frame |
| Draw Event | `_draw()` | Called when node needs redrawing |
| Draw GUI Event | CanvasLayer with `_draw()` | Use CanvasLayer for UI overlay |
| Alarm[n] | Timer nodes or custom timers | Create Timer nodes or track time in _process |
| Mouse Event (Click) | Area2D + signals or `_input(event)` | Use Area2D.input_event for interactive objects |
| Mouse Event (Enter/Leave) | Area2D + mouse_entered/exited signals | |
| Collision Event | Area2D/CollisionObject2D signals | |

### Code Conversion Examples

**GameMaker (GML):**
```gml
// Create Event
image_alpha = 0.5;
hspeed = -2;
alarm[0] = 60;

// Step Event
if (x < 0) {
    instance_destroy();
}

// Draw Event
draw_sprite(sprite_index, image_index, x, y);
draw_text(x, y, "Hello");
```

**Godot (GDScript):**
```gdscript
# _ready() - equivalent to Create Event
func _ready():
    modulate.a = 0.5
    velocity.x = -2
    timer = 1.0  # 60 frames at 60 FPS = 1 second

# _process(delta) - equivalent to Step Event
func _process(delta):
    position.x += velocity.x
    timer -= delta
    
    if position.x < 0:
        queue_free()

# _draw() - equivalent to Draw Event
func _draw():
    # Sprite drawn automatically by Sprite2D node
    draw_string(font, Vector2(0, 0), "Hello")
```

### Key Differences & Conversions

#### Arrays
- **GameMaker**: 1-indexed in this codebase (`arrayHeroes[1]` = first hero)
- **Godot**: 0-indexed, but we keep index 0 unused for compatibility
- Use `array.resize(6)` then `array.fill(null)` to initialize

#### Instance Creation
```gml
// GameMaker
varStar = instance_create(x, y, particleStar1);
varStar.speed_multiplier = 6;
```
```gdscript
# Godot
var star = particle_star1_scene.instantiate()
star.position = Vector2(x, y)
star.speed_multiplier = 6
add_child(star)
```

#### Global Data
- **GameMaker**: `mainData` object (buttonMenu) persists across rooms
- **Godot**: Autoload singleton script (`global.gd`) declared in project settings
- Access via `Global.variable_name` from anywhere

#### Coordinate System
- Both use **top-left origin** (0, 0)
- GameMaker room: 1920×1080 (or taller for scrolling)
- Godot viewport: 1920×1080 with Camera2D for scrolling

#### Drawing with Shadows (Text/Sprites)
```gml
// GameMaker
draw_set_color(c_blue);
draw_text(x + 3, y + 3, "TEXT");  // Shadow
draw_set_color(c_white);
draw_text(x, y, "TEXT");          // Main
```
```gdscript
# Godot
draw_string(font, pos + Vector2(3, 3), "TEXT", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.BLUE)
draw_string(font, pos, "TEXT", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)
```

#### Colors
- GameMaker: `c_white`, `c_blue`, `c_red`, `make_color_rgb(r, g, b)`
- Godot: `Color.WHITE`, `Color.BLUE`, `Color.RED`, `Color(r, g, b, a)` (values 0-1)

#### Random Functions
- `random(n)` → `randf() * n` (float 0 to n)
- `irandom(n)` → `randi() % (n + 1)` (int 0 to n inclusive)
- `irandom_range(min, max)` → `randi_range(min, max)`
- `choose(a, b, c)` → `[a, b, c].pick_random()`

#### String Operations
- `string(value)` → `str(value)`
- `string_length(str)` → `str.length()`
- GameMaker uses `#` for newline → Godot uses `\n`

```
diagame/
├── assets/
│   ├── sprites/      # Star1.png, Star2.png, Star3.png, Flare.png
│   ├── sounds/       # bgmusic.mp3, sound1.wav
│   └── fonts/        # arcade.png (bitmap font)
├── scenes/
│   ├── credits.tscn              # Main credits scene
│   ├── mission_select.tscn       # Mission select room scene
│   ├── credit_fade_text.tscn     # Fading text component
│   ├── particle_star1.tscn       # Star particle type 1
│   ├── particle_star2.tscn       # Star particle type 2
│   └── particle_star3.tscn       # Star particle type 3
├── scripts/
│   ├── global.gd                 # Global singleton (like mainData)
│   ├── music_manager.gd          # Background music manager
│   ├── credit_main.gd            # Main credits controller
│   ├── credit_fade_text.gd       # Fading text behavior
│   ├── particle_star.gd          # Star particle movement
│   ├── marker.gd                 # Rotating flare (clockwise)
│   ├── marker2.gd                # Rotating flare (counter-clockwise)
│   └── mission_select.gd         # Mission select controller
└── project.godot                 # Project configuration
```

## How to Test

1. Open Godot 4.3+ (or 4.6 as configured)
2. Import the project by opening `F:\Dev\GODOT\diagame\project.godot`
3. Wait for Godot to import all assets
4. Press F5 or click the Play button to run the credits scene

## Expected Behavior

- Black background (space theme)
- Background music (bgmusic.mp3) plays on loop
- Story text scrolls upward continuously
- Star particles spawn from the right and move left at different speeds (parallax effect)
  - Star type 1: slowest (2x speed)
  - Star type 2: medium (4x speed)
  - Star type 3: fastest (6x speed)
- Two flares rotate in the center (one clockwise, one counter-clockwise)
- Credit text fades in, stays visible, then fades out
- Alt+Enter toggles fullscreen mode

## Key Differences from GameMaker

### Arrays
- GameMaker uses 1-indexed arrays: `arrayHeroes[1]`
- Godot uses 0-indexed arrays: `array_heroes[0]`

### Instance Creation
- GameMaker: `instance_create(x, y, object)`
- Godot: `scene.instantiate()` then `add_child(instance)`

### Event System
- GameMaker: Event-based (Create, Step, Draw, Alarm)
- Godot: Node lifecycle (`_ready()`, `_process()`, `_draw()`)

### Coordinate System
- Both use top-left origin (0,0)
- GameMaker room size: 1920×2160 (tall for scrolling)
- Godot viewport: 1920×1080 with camera

## Status Summary

✅ **Credits Room Complete**
- All visual elements working
- Music playback configured
- Particle effects functional
- Text scrolling and fading working properly
- Fullscreen toggle implemented

This clean implementation can serve as a template for porting additional GameMaker rooms to Godot 4.

## Next Steps

To complete the full port:
1. Port remaining rooms (homeBase, missionSelect, playField, fightRoom)
2. Convert global data systems (loadGlobalVariables.gml)
3. Implement hero and mission data structures
4. Port combat system (calculateWinChance.gml)
5. Create UI panels and buttons
6. Implement save/load system
7. Add bitmap font support (arcade.png)

## Testing Notes

If you encounter issues:
- Check the Godot console (Output tab) for errors
- Verify all assets imported correctly (green checkmarks in FileSystem)
- Ensure autoloads are configured (Project > Project Settings > Autoload)
- Music requires MP3 to be fully imported (may take a moment)
---

## Established Patterns & Technical Notes

### File Structure Conventions

**Assets Organization:**
```
assets/
├── sprites/          # PNG files with auto-generated .import
├── sounds/           # MP3 (music), WAV (effects)
├── fonts/            # TTF or bitmap fonts
└── backgrounds/      # Large background images
```

**Scene Naming:**
- Rooms: `room_name.tscn` (e.g., `credits.tscn`)
- Components: `component_name.tscn` (e.g., `credit_fade_text.tscn`)
- Particles: `particle_type_variant.tscn` (e.g., `particle_star1.tscn`)

**Script Naming:**
- Match scene name or describe singleton purpose
- Use `snake_case.gd`

### Z-Index Layering (Established)

| Layer | Z-Index | Purpose | Example |
|-------|---------|---------|---------|
| Background | -200 | Solid colors, images | ColorRect, TextureRect |
| Far Background | -100 | Distant particles | Star particles |
| Default | 0 | Game objects | Heroes, enemies |
| Effects | 50 | Visual effects | Rotating flares |
| UI Background | 100 | Panels, frames | Fade text backgrounds |
| UI Foreground | 200 | Text, buttons | Scrolling text |

### Audio Configuration (Working Settings)

**Project Settings (project.godot):**
```ini
[audio]
driver/enable_input=true
driver/output_latency=15          # Prevents graininess
driver/output_latency.web=50
driver/mix_rate=44100             # Standard quality

```

**AudioStreamPlayer Settings (in scene):**
```
volume_db = -6.0                  # Prevents over-amplification
mix_target = 0                    # Direct stereo (no processing)
autoplay = true                   # For background music
```

**Audio Import (.import files):**
```ini
loop=true                         # For background music
loop_offset=0
```

### Particle Effects Pattern

**Shared Script Approach:**
- Single script (`particle_star.gd`) shared by multiple scene variants
- Each scene sets `speed_multiplier` as exported variable
- Inverted parallax: smallest = fastest, largest = slowest

**Current Settings:**
- Star1 (small): speed_multiplier = 6 (fastest)
- Star2 (medium): speed_multiplier = 4
- Star3 (large): speed_multiplier = 2 (slowest)

**Spawn Pattern:**
```gdscript
var particle_scene = preload("res://scenes/particle_star1.tscn")
var particle = particle_scene.instantiate()
particle.position = Vector2(x, y)
add_child(particle)
```

### Text Rendering with Shadow Effect

**Pattern used in credit_main.gd:**
```gdscript
var font = Global.arcade_font if Global.arcade_font else ThemeDB.fallback_font
var font_size = 18
var text_pos = Vector2(0, 10)

# Blue shadow (+3, +3 offset)
draw_multiline_string(font, text_pos + Vector2(3, 3), text, 
                     HORIZONTAL_ALIGNMENT_CENTER, width, font_size, -1, Color(0, 0, 1))

# White main text
draw_multiline_string(font, text_pos, text, 
                     HORIZONTAL_ALIGNMENT_CENTER, width, font_size, -1, Color.WHITE)
```

### Rotation Pattern (Markers/Flares)

**Clockwise rotation (marker.gd):**
```gdscript
func _process(_delta):
    rotation_degrees += 0.2
```

**Counter-clockwise rotation (marker2.gd):**
```gdscript
func _process(_delta):
    rotation_degrees -= 0.2
```

### Global Singleton Pattern

**Declaration (project.godot):**
```ini
[autoload]
Global="*res://scripts/global.gd"
```

**Usage:**
```gdscript
# Set global data
Global.star_speed = 2.0
Global.arrayMissions[1] = mission_data

# Read global data
var speed = Global.star_speed
var mission = Global.arrayMissions[1]
```

**Global Arrays (1-indexed compatibility):**
```gdscript
# Initialize with index 0 unused
Global.arrayMissions.resize(10)  # Indices 1-9 used
Global.arrayMissions.fill(null)
```

### Scene Transition Pattern (Future)

**GameMaker:**
```gml
goToRoom(0, credits);
goToRoom(justShowPanel, roomName);
```

**Godot (to implement):**
```gdscript
# Simple transition
get_tree().change_scene_to_file("res://scenes/room_name.tscn")

# With fade/animation
SceneTransition.fade_to_scene("res://scenes/room_name.tscn")
```

### Component Reusability Pattern

Demonstrated by `credit_fade_text.tscn`:
1. Create base scene with script
2. Export configurable properties (`@export var credit_text: String`)
3. Instance in parent scene
4. Override exported properties in parent scene

### Critical Lessons Learned

1. **V-Sync and Audio**: V-sync MUST be disabled (vsync_mode=0) to prevent audio timing issues causing graininess
2. **Audio Latency**: 15ms output latency balances smoothness and responsiveness
3. **Audio Volume**: Set volume_db to -6.0 or lower to prevent unexpe over-amplification
4. **Parallax Direction**: Smaller/distant objects faster creates better depth perception
5. **Font Loading**: Store font in Global singleton for reuse across scenes
6. **UIDs in Scenes**: Godot auto-generates UIDs - don't edit manually, regenerate by reimporting if corrupted

### Performance Considerations

- Particle cleanup: Use `queue_free()` when off-screen
- Timer pattern: Track time with `timer -= delta` instead of creating many Timer nodes
- Preload static scenes: `var scene = preload("res://...")` at script level
- Autoplay music: Set in AudioStreamPlayer, not via code

### Next Room Port Priority

Based on game flow (`initializer` → `credits` → `homeBase` → `missionSelect` → `playField` → `fightRoom`):

1. **homeBase**: Hero management UI - moderate complexity
2. **missionSelect**: 3x3 grid of missions - UI + data display
3. **playField**: Hero deployment - drag-and-drop mechanics
4. **fightRoom**: Combat resolution - animation sequences

Each builds on patterns established in credits room.