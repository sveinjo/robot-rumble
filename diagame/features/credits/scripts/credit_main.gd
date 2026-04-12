extends Node2D

# Credits main controller - scrolls the story text upward
var story_text: String = """It's the future!




Mankind has evolved!




By infusing their biology with nano-machines and robotics, they have acquired fantastic powers.




However, this came at a price...




Everyone also acquired the 'power' of diabetes, and thus insulin became the world's most valuable resource.




Your stores of food and insulin have been taken, and you must get them back!"""

var scroll_speed: float = 1.0
var arcade_font: Font
const CREDITS_FONT_SIZE := 24
const BASE_FPS := 60.0
const STAR_SPAWN_INTERVAL := 20.0 / 60.0
const STAR_SPEED := 2.0
const STAR_SIZE := 1.0

const STAR_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/Star1.png"),
	preload("res://assets/sprites/Star2.png"),
	preload("res://assets/sprites/Star3.png"),
]
const STAR_SPEED_MULTIPLIERS: Array[int] = [4, 2, 1]

var _star_spawn_timer: float = STAR_SPAWN_INTERVAL
var _star_rng := RandomNumberGenerator.new()

@onready var _local_stars: Node2D = get_node_or_null("../../LocalStars") as Node2D

func _ready():
	# Load the arcade font
	arcade_font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	_star_rng.randomize()
	_star_spawn_timer = STAR_SPAWN_INTERVAL
	if _local_stars != null:
		_local_stars.z_index = -100
		for child in _local_stars.get_children():
			child.queue_free()

	# Keep shared starfield disabled while credits runs, so projected walls don't interfere.
	GameState.set_starfield_enabled(false)
	GameState.clear_starfield_particles()
	
	# Credit fade texts are now added directly in the scene file
	# No need to create them dynamically
	
	# Credits now owns its own local starfield.

func _exit_tree() -> void:
	GameState.set_starfield_enabled(true)

func _process(delta: float):
	_update_local_starfield(delta)

	# Scroll upward (y decreases)
	position.y -= scroll_speed * delta * BASE_FPS
	
	# Loop when we've scrolled too far up
	if position.y <= -1088:
		position.y = 1088

func _update_local_starfield(delta: float) -> void:
	if _local_stars == null:
		return

	_star_spawn_timer -= delta
	while _star_spawn_timer <= 0.0:
		_spawn_local_star()
		_star_spawn_timer += STAR_SPAWN_INTERVAL

	var step_scale := delta * BASE_FPS
	for child in _local_stars.get_children():
		if not (child is Sprite2D):
			continue
		var star := child as Sprite2D
		var speed_multiplier := int(star.get_meta("speed_multiplier", 1))
		star.position.x += -STAR_SPEED * float(speed_multiplier) * step_scale
		star.scale.x = STAR_SIZE
		var texture_width := float(star.texture.get_width()) if star.texture != null else 0.0
		if star.position.x <= -texture_width:
			star.queue_free()

func _spawn_local_star() -> void:
	if _local_stars == null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1920.0, 1080.0)

	var star_type := _star_rng.randi_range(0, 2)
	var star := Sprite2D.new()
	star.texture = STAR_TEXTURES[star_type]
	star.position = Vector2(viewport_size.x, _star_rng.randf_range(0.0, viewport_size.y))
	star.scale = Vector2(STAR_SIZE, 1.0)
	star.set_meta("speed_multiplier", STAR_SPEED_MULTIPLIERS[star_type])
	_local_stars.add_child(star)
	

func _input(event):
	# On left-click, go to mission select.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")

func _draw():
	# Draw the story text with a shadow effect, centered horizontally
	var font = arcade_font if arcade_font else ThemeDB.fallback_font
	var font_size = CREDITS_FONT_SIZE
	var text_width = 640
	# In GameMaker, text is centered on screen. For 1920px screen, center at 960px
	# Since text is 640px wide, left edge should be at 960 - 320 = 640
	# Node is at x=640, so relative position should be 0
	var text_pos = Vector2(0, 10)
	
	# Blue shadow
	draw_multiline_string(font, text_pos + Vector2(3, 3), story_text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size, -1, Color(0, 0, 1))
	
	# White main text
	draw_multiline_string(font, text_pos, story_text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size, -1, Color.WHITE)
