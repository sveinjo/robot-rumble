# Robot Rumble - GameMaker to Godot Porting Reference

Quick reference for converting GameMaker Studio 1.x patterns to Godot 4.

## Quick Event Mapping

| GameMaker | Godot | Usage |
|-----------|-------|-------|
| Create Event | `_ready()` | Initialization |
| Step Event | `_process(delta)` | Every frame logic |
| Draw Event | `_draw()` | Custom rendering |
| Draw GUI Event | CanvasLayer + `_draw()` | UI overlay |
| Alarm[0] | Timer or `timer -= delta` | Delayed execution |
| Mouse Left Click | `_input(event)` or Area2D | Click detection |
| Mouse Enter | Area2D.mouse_entered signal | Hover start |
| Mouse Leave | Area2D.mouse_exited signal | Hover end |
| Collision | Area2D.area_entered signal | Touch detection |

## Common GML → GDScript Conversions

### Variables & Properties

| GML | GDScript | Notes |
|-----|----------|-------|
| `image_alpha` | `modulate.a` | Transparency (0-1) |
| `image_angle` | `rotation_degrees` | Rotation |
| `image_xscale/yscale` | `scale.x/y` | Scale |
| `x, y` | `position.x, position.y` | Position |
| `sprite_index` | `texture` (for Sprite2D) | Sprite asset |
| `visible` | `visible` | Visibility (same!) |
| `depth` | `z_index` | Layer ordering |
| `hspeed, vspeed` | `velocity.x, velocity.y` | Movement |

### Drawing Functions

| GML | GDScript |
|-----|----------|
| `draw_sprite(spr, ind, x, y)` | `draw_texture(texture, pos)` |
| `draw_text(x, y, str)` | `draw_string(font, pos, str, align, width, size, lines, color)` |
| `draw_text_ext(x, y, str, sep, w)` | `draw_multiline_string(font, pos, str, align, width, size, lines, color)` |
| `draw_set_color(c_white)` | Color passed to draw function |
| `draw_set_alpha(0.5)` | Color with alpha: `Color(1, 1, 1, 0.5)` |
| `draw_rectangle(x1, y1, x2, y2, outline)` | `draw_rect(Rect2(pos, size), color, filled)` |
| `draw_circle(x, y, r, outline)` | `draw_circle(pos, radius, color)` |

### Color Constants

| GML | GDScript |
|-----|----------|
| `c_white` | `Color.WHITE` |
| `c_black` | `Color.BLACK` |
| `c_red` | `Color.RED` |
| `c_blue` | `Color.BLUE` |
| `c_yellow` | `Color.YELLOW` |
| `make_color_rgb(r,g,b)` | `Color(r/255.0, g/255.0, b/255.0)` |

### Random Functions

| GML | GDScript |
|-----|----------|
| `random(n)` | `randf() * n` |
| `irandom(n)` | `randi() % (n + 1)` |
| `irandom_range(min, max)` | `randi_range(min, max)` |
| `choose(a, b, c)` | `[a, b, c].pick_random()` |

### String Functions

| GML | GDScript |
|-----|----------|
| `string(val)` | `str(val)` |
| `string_length(str)` | `str.length()` |
| `string_pos(substr, str)` | `str.find(substr) + 1` (GML is 1-indexed!) |
| `string_copy(str, ind, cnt)` | `str.substr(ind-1, cnt)` |
| `string_upper(str)` | `str.to_upper()` |
| `string_lower(str)` | `str.to_lower()` |
| `#` (newline in string) | `\n` |

### Math Functions

| GML | GDScript |
|-----|----------|
| `abs(n)` | `abs(n)` |
| `ceil(n)` | `ceil(n)` |
| `floor(n)` | `floor(n)` |
| `round(n)` | `round(n)` |
| `sqrt(n)` | `sqrt(n)` |
| `power(x, n)` | `pow(x, n)` |
| `sin/cos/tan(degrees)` | `sin/cos/tan(radians)` - use `deg_to_rad()` |
| `arcsin/arccos/arctan` | `asin/acos/atan` |
| `point_distance(x1,y1,x2,y2)` | `Vector2(x1,y1).distance_to(Vector2(x2,y2))` |
| `point_direction(x1,y1,x2,y2)` | `Vector2(x1,y1).angle_to_point(Vector2(x2,y2))` |

### Instance Functions

| GML | GDScript |
|-----|----------|
| `instance_create(x, y, obj)` | `scene.instantiate()` + `add_child()` |
| `instance_destroy()` | `queue_free()` |
| `instance_exists(obj)` | `get_tree().get_nodes_in_group("group")` |
| `instance_number(obj)` | `get_tree().get_nodes_in_group("group").size()` |
| `with(obj) { }` | `for node in get_tree().get_nodes_in_group("group"):` |

### Room/Scene Functions

| GML | GDScript |
|-----|----------|
| `room_goto(rm)` | `get_tree().change_scene_to_file("res://scenes/room.tscn")` |
| `room_restart()` | `get_tree().reload_current_scene()` |
| `room_width/height` | `get_viewport_rect().size.x/y` |
| `room_speed` | Set in Project Settings (60 FPS default) |

### Array Functions

| GML | GDScript |
|-----|----------|
| `array[0]` | `array[0]` (0-indexed in Godot!) |
| `array_length_1d(arr)` | `array.size()` |
| `array[i] = val` | `array[i] = val` |
| Creating 2D array | `var arr = []; arr.resize(10); for i in 10: arr[i] = []` |

**IMPORTANT**: GameMaker arrays in Robot Rumble are 1-indexed, Godot is 0-indexed!

### Data Structure Functions

| GML | GDScript |
|-----|----------|
| `ds_list_create()` | `var list = []` |
| `ds_list_add(list, val)` | `list.append(val)` |
| `ds_list_size(list)` | `list.size()` |
| `ds_map_create()` | `var map = {}` |
| `ds_map_add(map, key, val)` | `map[key] = val` |
| `ds_map_find_value(map, key)` | `map.get(key)` or `map[key]` |

### Keyboard/Mouse Input

| GML | GDScript |
|-----|----------|
| `keyboard_check(vk_left)` | `Input.is_action_pressed("ui_left")` |
| `keyboard_check_pressed(key)` | `Input.is_action_just_pressed("action")` |
| `mouse_check_button(mb_left)` | Check in `_input(event)` |
| `mouse_x, mouse_y` | `get_viewport().get_mouse_position()` |

## Room (Scene) Creation Pattern

### Step 1: Create Scene File

1. New Scene → Other Node → Node2D (for 2D rooms)
2. Save as `res://scenes/room_name.tscn`

### Step 2: Add Standard Components

```
RoomName (Node2D)
├── Background (ColorRect or TextureRect) - z_index: -200
├── Camera2D - position: (960, 540)
├── [Game objects, sprites, etc.] - z_index: 0-50
└── [UI elements] - z_index: 100-200
```

### Step 3: Attach Room Script

```gdscript
extends Node2D

func _ready():
    # Room start code (like GameMaker's room creation code)
    initialize_room()

func _process(delta):
    # Per-frame logic
    pass

func initialize_room():
    # Setup logic
    pass
```

### Step 4: Configure in project.godot

Set as main scene or link from other scenes via `change_scene_to_file()`

## Component (Object) Creation Pattern

### Step 1: Create Component Scene

1. New Scene → Node2D or Sprite2D or Area2D
2. Add child nodes as needed (Sprite2D, CollisionShape2D, etc.)
3. Save as `res://scenes/component_name.tscn`

### Step 2: Attach Script

```gdscript
extends Sprite2D  # or Node2D, Area2D, etc.

# Exported variables (editable in inspector)
@export var speed: float = 100.0
@export var custom_text: String = ""

# Internal variables
var timer: float = 0.0

func _ready():
    # Create event equivalent
    pass

func _process(delta):
    # Step event equivalent
    position.x += speed * delta
    timer -= delta

func _draw():
    # Draw event equivalent (custom rendering)
    pass
```

### Step 3: Instantiate in Room

**In scene editor**: Drag scene file into room

**In code**:
```gdscript
var component_scene = preload("res://scenes/component_name.tscn")
var component = component_scene.instantiate()
component.position = Vector2(x, y)
component.speed = 200.0
add_child(component)
```

## Global Data Pattern

### Create Singleton (global.gd)

```gdscript
extends Node

# Global variables (like mainData in GameMaker)
var star_speed: float = 2.0
var play_music: bool = true

# GameMaker-compatible arrays (1-indexed, 0 unused)
var arrayMissions: Array = []
var arrayHeroes: Array = []

func _ready():
    initialize_arrays()

func initialize_arrays():
    # Resize to leave index 0 unused (GameMaker compatibility)
    arrayMissions.resize(10)  # Indices 1-9
    arrayMissions.fill(null)
    
    arrayHeroes.resize(6)  # Indices 1-5
    arrayHeroes.fill(null)
```

### Register Autoload

Project → Project Settings → Autoload → Add `global.gd` as "Global"

### Access from Anywhere

```gdscript
# Set global data
Global.star_speed = 3.0
Global.arrayHeroes[1] = hero_data

# Read global data
var speed = Global.star_speed
var hero = Global.arrayHeroes[1]
```

## Audio Setup (Working Configuration)

### Project Settings (project.godot)

```ini
[audio]
driver/enable_input=true
driver/output_latency=15          # Critical for clean audio
driver/mix_rate=44100

[display]
window/vsync/vsync_mode=0         # MUST BE DISABLED for audio!
```

### AudioStreamPlayer in Scene

```
AudioStreamPlayer
├── stream: [your audio file]
├── volume_db: -6.0               # Prevent over-amplification
├── mix_target: 0                 # Direct stereo
├── autoplay: true                # For BGM
└── bus: "Master"
```

### Audio Import Settings (.import file)

For background music:
```ini
loop=true
loop_offset=0
```

## Common Patterns from Credits Room

### Shadow Text Effect

```gdscript
func _draw():
    var font = Global.arcade_font
    var pos = Vector2(100, 100)
    
    # Shadow (blue, offset +3,+3)
    draw_string(font, pos + Vector2(3, 3), "TEXT", 
               HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 0, 1))
    
    # Main (white)
    draw_string(font, pos, "TEXT", 
               HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
```

### Scrolling Background

```gdscript
var scroll_speed: float = 1.0

func _process(delta):
    position.y -= scroll_speed
    
    # Loop when off-screen
    if position.y <= -1088:
        position.y = 1088
```

### Rotating Sprite

```gdscript
func _process(_delta):
    rotation_degrees += 0.2  # Clockwise
    # rotation_degrees -= 0.2  # Counter-clockwise
```

### Fading In/Out

```gdscript
var fade_timer: float = 0.0
var fade_in_time: float = 1.0
var visible_time: float = 2.0
var fade_out_time: float = 1.0

func _process(delta):
    fade_timer += delta
    
    if fade_timer < fade_in_time:
        modulate.a = fade_timer / fade_in_time
    elif fade_timer < fade_in_time + visible_time:
        modulate.a = 1.0
    elif fade_timer < fade_in_time + visible_time + fade_out_time:
        var fade_progress = (fade_timer - fade_in_time - visible_time) / fade_out_time
        modulate.a = 1.0 - fade_progress
    else:
        modulate.a = 0.0
```

### Particle Spawning

```gdscript
var spawn_timer: float = 0.0
var spawn_interval: float = 20.0 / 60.0  # 20 frames at 60 FPS

var particle_scene = preload("res://scenes/particle.tscn")

func _process(delta):
    spawn_timer -= delta
    if spawn_timer <= 0:
        spawn_particle()
        spawn_timer = spawn_interval

func spawn_particle():
    var particle = particle_scene.instantiate()
    particle.position = Vector2(1920, randf() * 1080)
    add_child(particle)
```

## Debugging Tips

### Print to Console

```gdscript
print("Debug message")
print("Value:", variable_name)
print_debug("With stack trace")
```

### Check Node Properties

```gdscript
print("Position:", position)
print("Visible:", visible)
print("Children:", get_child_count())
```

### Verify Scene Loaded

```gdscript
func _ready():
    print(name, " ready called")
    print("Parent:", get_parent().name if get_parent() else "None")
```

---

## Credits Room Example Walkthrough

Full working example from the credits room implementation:

**Scene Structure:**
```
Credits (Node2D)
├── Background (ColorRect) - Black, z: -200
├── Camera2D - at (960, 540)
├── CreditMain (Node2D) - Scrolling text controller, z: 200
├── Marker (Sprite2D) - Rotating flare (clockwise), z: 50
├── Marker2 (Sprite2D) - Rotating flare (counter-clockwise), z: 50
├── AudioStreamPlayer - Background music
├── CreditFadeText1 (instance) - "Music by...", z: 100
├── CreditFadeText2 (instance) - "Art by...", z: 100
└── CreditFadeText3 (instance) - "Game design by...", z: 100
```

This pattern demonstrates:
- ✅ Background setup
- ✅ Camera configuration
- ✅ Layered z-index usage
- ✅ Component reuse (CreditFadeText instances)
- ✅ Audio playback
- ✅ Particle spawning (in CreditMain script)
- ✅ Rotation effects (Marker scripts)

Use this as a template for future rooms!
