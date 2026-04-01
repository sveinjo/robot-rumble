extends Node2D

const SCREEN_WIDTH := 1920.0
const TOP_Y := 0.0
const BOTTOM_Y := 1080.0
const INITIAL_SPAWN_DELAY := 10.0 / 60.0
const SPAWN_INTERVAL := 5.0 / 60.0

var star_spawn_timer: float = INITIAL_SPAWN_DELAY
var star_texture: Texture2D = load("res://assets/sprites/Star1c_0.png")
var charge_star_script: Script = preload("res://features/charge/scripts/charge_star.gd")

@onready var star_container: Node2D = $StarContainer
@onready var center_glow: Sprite2D = $CenterGlow
@onready var marker_glow: Sprite2D = $MarkerGlow
@onready var mega_charge: Sprite2D = $MegaCharge

func _ready():
	# Charge uses its own directional star effect, so disable shared persistent stars.
	GameState.set_starfield_enabled(false)
	GameState.clear_starfield_particles()

	_spawn_directional_star()
	star_spawn_timer = INITIAL_SPAWN_DELAY

func _exit_tree():
	# Restore persistent stars for rooms that expect the shared starfield.
	GameState.set_starfield_enabled(true)

func _process(delta: float):
	# centerGlow image_angle += 0.1; marker2 image_angle -= 0.1
	center_glow.rotation_degrees += 0.1 * delta * 60.0
	marker_glow.rotation_degrees -= 0.1 * delta * 60.0

	star_spawn_timer -= delta
	while star_spawn_timer <= 0.0:
		_spawn_directional_star()
		star_spawn_timer += SPAWN_INTERVAL

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return
		if _is_over_mega_charge(event.position):
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file("res://features/credits/scenes/credits.tscn")

func _spawn_directional_star():
	var spawn_y := TOP_Y if randf() <= 0.5 else BOTTOM_Y
	var spawn_pos := Vector2(randf() * SCREEN_WIDTH, spawn_y)

	var star: Sprite2D = charge_star_script.new()
	star.texture = star_texture
	star.setup(spawn_pos)
	star_container.add_child(star)

func _is_over_mega_charge(mouse_pos: Vector2) -> bool:
	if mega_charge.texture == null:
		return false

	var sprite_size := mega_charge.texture.get_size() * mega_charge.scale
	var top_left := mega_charge.global_position
	if mega_charge.centered:
		top_left -= sprite_size * 0.5

	return Rect2(top_left, sprite_size).has_point(mouse_pos)
