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

func _ready():
	# Load the arcade font
	arcade_font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	GameState.star_speed = 2.0
	GameState.star_size = 1.0
	GameState.set_starfield_spawn_interval(20.0 / 60.0)
	GameState.set_starfield_enabled(true)
	
	# Credit fade texts are now added directly in the scene file
	# No need to create them dynamically
	
	# Shared persistent starfield now handled by StarfieldManager autoload.

func _process(_delta):
	# Scroll upward (y decreases)
	position.y -= scroll_speed
	
	# Loop when we've scrolled too far up
	if position.y <= -1088:
		position.y = 1088
	

func _input(event):
	# On left-click, go to mission select.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")

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
