extends Node2D

# Credits main controller - scrolls the story text upward
var story_text: String = """It's the future!




Mankind has evolved!




By infusing their biology with nano-machines and robotics, they have acquired fantastic powers.




However, this came at a price...




Everyone also acquired the 'power' of diabetes, and thus insulin became the world's most valuable resource.




Your stores of food and insulin have been taken, and you must get them back!"""

var scroll_speed: float = 1.0
var star_spawn_timer: float = 0.0
var star_spawn_interval: float = 20.0 / 60.0  # 20 frames at 60 FPS
var arcade_font: Font

# Preload particle scenes
var particle_star1_scene = preload("res://scenes/particle_star1.tscn")
var particle_star2_scene = preload("res://scenes/particle_star2.tscn")
var particle_star3_scene = preload("res://scenes/particle_star3.tscn")

func _ready():
	# Load the arcade font
	arcade_font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	
	# Credit fade texts are now added directly in the scene file
	# No need to create them dynamically
	
	# Start the star particle timer
	star_spawn_timer = star_spawn_interval

func _process(delta):
	# Scroll upward (y decreases)
	position.y -= scroll_speed
	
	# Loop when we've scrolled too far up
	if position.y <= -1088:
		position.y = 1088
	
	# Spawn star particles periodically
	star_spawn_timer -= delta
	if star_spawn_timer <= 0:
		create_star_particle()
		star_spawn_timer = star_spawn_interval

func _input(event):
	# On right-click, go to mission select.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		get_tree().change_scene_to_file("res://scenes/mission_select.tscn")

func _draw():
	# Draw the story text with a shadow effect, centered horizontally
	var font = arcade_font if arcade_font else ThemeDB.fallback_font
	var font_size = 18
	var text_width = 640
	# In GameMaker, text is centered on screen. For 1920px screen, center at 960px
	# Since text is 640px wide, left edge should be at 960 - 320 = 640
	# Node is at x=640, so relative position should be 0
	var text_pos = Vector2(0, 10)
	
	# Blue shadow
	draw_multiline_string(font, text_pos + Vector2(3, 3), story_text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size, -1, Color(0, 0, 1))
	
	# White main text
	draw_multiline_string(font, text_pos, story_text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size, -1, Color.WHITE)

func create_star_particle():
	"""Create a random star particle (equivalent to createStarParticle.gml)"""
	var range_val = 1080
	var star_line = randf() * range_val
	var star_type = randf() * 3
	var particle_scene
	
	# Choose particle type based on random value
	if star_type > 2:
		particle_scene = particle_star3_scene
	elif star_type > 1:
		particle_scene = particle_star2_scene
	else:
		particle_scene = particle_star1_scene
	
	# Place in lower portion of screen
	star_line = 1080 - 20 - range_val + star_line
	
	# Create and add to parent scene
	var particle = particle_scene.instantiate()
	particle.position = Vector2(1920, star_line)
	get_parent().add_child(particle)
