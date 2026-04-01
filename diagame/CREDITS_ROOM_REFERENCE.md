# Credits Room - Implementation Details

Complete documentation of the working credits room implementation for reference.

## File Inventory

### Scene Files
- `scenes/credits.tscn` - Main credits room scene (ROOT)
- `scenes/credit_fade_text.tscn` - Reusable fading text component
- `scenes/particle_star1.tscn` - Small fast star (speed 6×)
- `scenes/particle_star2.tscn` - Medium star (speed 4×)
- `scenes/particle_star3.tscn` - Large slow star (speed 2×)
- `scenes/particle_overlay.tscn` - Animated stripe overlay (not used in credits)

### Scripts
- `scripts/credit_main.gd` - Credits controller (scrolling text + particle spawning)
- `scripts/credit_fade_text.gd` - Fade in/out behavior for credit text
- `scripts/particle_star.gd` - Star particle movement (shared by all star types)
- `scripts/marker.gd` - Clockwise rotation for flare
- `scripts/marker2.gd` - Counter-clockwise rotation for flare
- `scripts/global.gd` - Autoload singleton for global data
- `scripts/music_manager.gd` - Autoload singleton for music control (not actively used)

### Assets
- `assets/sprites/Star1.png` - Smallest star sprite
- `assets/sprites/Star2.png` - Medium star sprite
- `assets/sprites/Star3.png` - Largest star sprite
- `assets/sprites/Flare.png` - Rotating marker sprite
- `assets/sounds/bgmusic.mp3` - Background music (looping)
- `assets/fonts/PressStart2P-Regular.ttf` - Arcade-style font

## Scene Hierarchy (credits.tscn)

```
Credits (Node2D)
│
├── Background (ColorRect)
│   ├── z_index: -200
│   ├── size: 1920×1080
│   └── color: Black (0,0,0,1)
│
├── Camera2D
│   └── offset: (960, 540)
│
├── CreditMain (Node2D)
│   ├── z_index: 200
│   ├── position: (640, 1388)  # Starts below screen for scrolling
│   └── script: credit_main.gd
│
├── Marker (Sprite2D)
│   ├── z_index: 50
│   ├── position: (960, 540)
│   ├── texture: Flare.png
│   └── script: marker.gd (rotation += 0.2)
│
├── Marker2 (Sprite2D)
│   ├── z_index: 50
│   ├── position: (960, 540)
│   ├── texture: Flare.png
│   └── script: marker2.gd (rotation -= 0.2)
│
├── AudioStreamPlayer
│   ├── stream: bgmusic.mp3
│   ├── volume_db: -6.0
│   ├── mix_target: 0
│   └── autoplay: true
│
├── CreditFadeText1 (instance of credit_fade_text.tscn)
│   ├── z_index: 100
│   ├── position: (640, 564)
│   └── credit_text: "Music by\nErlend Hofstad Langseth"
│
├── CreditFadeText2 (instance of credit_fade_text.tscn)
│   ├── z_index: 100
│   ├── position: (960, 444)
│   └── credit_text: "Art by\nAndreas Johansen"
│
└── CreditFadeText3 (instance of credit_fade_text.tscn)
    ├── z_index: 100
    ├── position: (1280, 564)
    └── credit_text: "Game design by\nSvein-Gunnar Johansen"
```

## Script Details

### credit_main.gd

**Purpose**: Scrolls story text upward and spawns star particles

**Key Variables**:
- `story_text: String` - Multi-line story text with embedded newlines
- `scroll_speed: float = 1.0` - Pixels per frame to scroll upward
- `star_spawn_timer: float` - Countdown timer for next particle
- `star_spawn_interval: float = 20.0 / 60.0` - Spawn every 20 frames (at 60 FPS)
- `arcade_font: Font` - Loaded from assets

**Preloaded Scenes**:
```gdscript
var particle_star1_scene = preload("res://core/fx/starfield/particle_star1.tscn")
var particle_star2_scene = preload("res://core/fx/starfield/particle_star2.tscn")
var particle_star3_scene = preload("res://core/fx/starfield/particle_star3.tscn")
```

**_ready()**:
- Loads arcade font
- Initializes spawn timer

**_process(delta)**:
- Moves position.y upward (decreasing Y)
- Loops position when scrolling too far (-1088 threshold)
- Decrements spawn timer
- Spawns star particles at intervals

**_draw()**:
- Draws multi-line story text with blue shadow effect
- Centers text horizontally (640px wide)
- Font size: 18
- Shadow offset: (+3, +3)

**create_star_particle()**:
- Randomly chooses star type (1, 2, or 3)
- Creates particle at random Y position
- Adds to scene tree

### credit_fade_text.gd

**Purpose**: Fades text in, holds visible, then fades out

**Key Variables**:
- `@export var credit_text: String = ""` - Text to display (editable in scene)
- `fade_timer: float = 0.0` - Tracks animation progress
- `fade_in_time: float = 1.0` - Duration of fade in
- `visible_time: float = 60.0` - Duration to stay visible
- `fade_out_time: float = 1.0` - Duration of fade out
- `arcade_font: Font` - Shared font reference

**_process(delta)**:
- Increments fade_timer
- Calculates alpha based on current phase:
  - 0-1s: Fade in (0 → 1)
  - 1-61s: Visible (1)
  - 61-62s: Fade out (1 → 0)
  - 62s+: Invisible (0)

**_draw()**:
- Draws credit text with blue shadow effect
- Centered horizontally
- Font size: 18

### particle_star.gd

**Purpose**: Moves star particle from right to left, shared by all star types

**Key Variables**:
- `var speed_multiplier: int = 4` - Speed factor (set per scene type)

**_ready()**:
- Applies global star size scale

**_process(delta)**:
- Moves left: `position.x += -Global.star_speed * speed_multiplier`
- Applies scale from Global settings
- Destroys self when off left edge of screen

**Speed Settings** (set in scene files):
- Star1: `speed_multiplier = 6` (smallest, fastest)
- Star2: `speed_multiplier = 4` (medium)
- Star3: `speed_multiplier = 2` (largest, slowest)

### marker.gd

**Purpose**: Rotates flare clockwise

```gdscript
extends Sprite2D

func _process(_delta):
    rotation_degrees += 0.2
```

### marker2.gd

**Purpose**: Rotates flare counter-clockwise

```gdscript
extends Sprite2D

func _process(_delta):
    rotation_degrees -= 0.2
```

### game_state.gd

**Purpose**: Singleton for global game data (like GameMaker's mainData)

**Key Variables**:
```gdscript
var star_speed: float = 2.0
var star_size: float = 1.0
var play_music: bool = true
var deploy_target: String = "win"

var arrayMissions: Array = []  # Resize to 10, use 1-9
var arrayHeroes: Array = []    # Resize to 6, use 1-5
var arrayEnemies: Array = []   # 2D array for enemy data

var intEventMarker: int = 0
var speechBubbles: bool = true

var arcade_font: Font
```

**_ready()**:
- Sets initial window mode to windowed
- Loads arcade font from assets/fonts/PressStart2P-Regular.ttf
- Initializes arrays

**_process(delta)**:
- Handles Alt+Enter fullscreen toggle

## Project Configuration (project.godot)

### Application
```ini
[application]
config/name="Robot Rumble"
run/main_scene="res://features/charge/scenes/charge.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")
```

### Autoloads
```ini
[autoload]
GameState="*res://autoload/state/game_state.gd"
MusicManager="*res://autoload/audio/music_manager.gd"
StarfieldManager="*res://autoload/fx/starfield_manager.gd"
```

### Display
```ini
[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="viewport"
window/vsync/vsync_mode=0  # CRITICAL: Disabled for clean audio
textures/canvas_textures/default_texture_filter=0  # Pixel-perfect rendering
```

### Audio (CRITICAL SETTINGS)
```ini
[audio]
driver/enable_input=true
driver/output_latency=15        # Prevents audio graininess
driver/output_latency.web=50
driver/mix_rate=44100           # Standard CD quality
```

### Input
```ini
[input]
toggle_fullscreen={
    "events": [Alt+Enter]
}
```

### Physics
```ini
[physics]
3d/physics_engine="Jolt Physics"
common/physics_ticks_per_second=60  # Matches GameMaker's room_speed
```

## Audio Import Settings

### bgmusic.mp3.import
```ini
[remap]
importer="mp3"
type="AudioStreamMP3"

[params]
loop=true           # CRITICAL: Music loops seamlessly
loop_offset=0
bpm=0
beat_count=0
bar_beats=4
```

## Behavior Details

### Scrolling Text
- **Initial position**: (640, 1388) - below viewport
- **Scroll speed**: 1 pixel per frame
- **Loop point**: Y ≤ -1088
- **Loop reset**: Y = 1088
- **Text width**: 640 pixels
- **Centered on**: X = 640 (relative to node position)

### Star Particles
- **Spawn interval**: Every 20 frames (0.333 seconds at 60 FPS)
- **Spawn position**: X = 1920 (right edge), Y = random 0-1080
- **Direction**: Left (decreasing X)
- **Cleanup**: queue_free() when X < 0
- **Parallax effect**: Smaller stars faster (inverted parallax)

### Rotating Flares
- **Position**: Center of viewport (960, 540)
- **Rotation speed**: ±0.2 degrees per frame
- **One clockwise**, **one counter-clockwise**
- **Z-index**: 50 (above stars, below text)

### Fading Credit Text
- **Phase 1** (0-1s): Fade in (alpha 0 → 1)
- **Phase 2** (1-61s): Visible (alpha = 1)
- **Phase 3** (61-62s): Fade out (alpha 1 → 0)
- **Phase 4** (62s+): Invisible (alpha = 0)

### Audio Playback
- **Volume**: -6 dB (prevents over-amplification)
- **Mix target**: 0 (stereo, no processing)
- **Autoplay**: True (starts on scene load)
- **Looping**: True (seamless background music)

## Known Working Values

These values are tested and work correctly:

### Audio
- V-sync: **DISABLED** (vsync_mode = 0)
- Output latency: **15ms**
- Mix rate: **44100 Hz**
- Volume: **-6dB**

### Parallax Speeds
- Small star: **6× base speed**
- Medium star: **4× base speed**
- Large star: **2× base speed**
- Base speed: **2.0** (set in Global)

### Scroll/Rotation
- Text scroll: **1.0 pixel/frame**
- Flare rotation: **±0.2 degrees/frame**

### Timings
- Particle spawn: **20 frames** (0.333s)
- Text fade in: **1 second**
- Text visible: **60 seconds**
- Text fade out: **1 second**

## Testing Checklist

When running the credits room, verify:

- [ ] Black background fills entire viewport
- [ ] Background music plays immediately and loops
- [ ] Story text scrolls upward smoothly
- [ ] Text loops back when scrolling off top
- [ ] Blue shadow appears offset from white text
- [ ] Star particles spawn from right edge
- [ ] Small stars move fastest, large stars slowest
- [ ] Particles disappear when off left edge
- [ ] Both flares rotate (one each direction)
- [ ] Credit text fades in, stays visible, fades out
- [ ] Alt+Enter toggles fullscreen
- [ ] No audio crackling or graininess
- [ ] Music volume is comfortable (not too loud)
- [ ] Runs at stable 60 FPS

## Common Issues & Solutions

### Audio is grainy/crackling
- **Solution**: Ensure `vsync_mode=0` in project.godot

### Audio is too loud
- **Solution**: Set `volume_db=-6.0` or lower in AudioStreamPlayer

### Music doesn't loop
- **Solution**: Set `loop=true` in bgmusic.mp3.import file

### Text not centered
- **Solution**: CreditMain node at X=640, text width=640, centered alignment

### Particles not spawning
- **Solution**: Check preload paths, verify create_star_particle() is called

### Rotations not smooth
- **Solution**: Ensure _process() is used, not _physics_process()

### Font looks wrong
- **Solution**: Verify arcade_font loaded in Global._ready()

## Next Steps for Future Rooms

When porting the next room, you can reuse:

1. **Global singleton pattern** - Already established
2. **Z-index layering scheme** - Background (-200), Objects (0-50), UI (100-200)
3. **Audio configuration** - Copy project.godot audio settings
4. **Component pattern** - credit_fade_text shows how to make reusable components
5. **Shadow rendering** - Use the blue shadow + white text pattern
6. **Particle spawning** - Preload + instantiate + add_child pattern
7. **Scene structure** - Node2D root with ColorRect/TextureRect background

**Suggested next room**: homeBase (hero management screen)
- Similar UI-focused design
- Can reuse text rendering patterns
- Will establish button/panel patterns for other rooms
