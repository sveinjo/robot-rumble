extends Node2D

# Fading text for credits
@export_multiline var credit_text: String = ""
var text_alpha: float = 0.0
var fade_flag: int = 1  # 1 = fading in, 0 = fading out
var fade_timer: float = 0.0
var arcade_font: Font
const CREDITS_FONT_SIZE := 24

func _ready():
	# Load the arcade font
	arcade_font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	
	# Start fade-in after 200 frames (about 3.33 seconds at 60 FPS)
	fade_timer = 200.0 / 60.0
	text_alpha = 0.0  # Start invisible
	fade_flag = 1  # Start fading in

func _process(delta):
	# Handle fade timer
	if fade_timer > 0:
		fade_timer -= delta
		if fade_timer <= 0 and fade_flag == 1:
			fade_flag = 0  # Start fading out
	
	# Update alpha based on fade direction
	if fade_flag == 1:
		if text_alpha < 1.0:
			text_alpha += 0.01
	else:
		if text_alpha > 0.0:
			text_alpha -= 0.01
	
	queue_redraw()

func _draw():
	# Draw the credit text with arcade font
	if credit_text.is_empty():
		return
	
	var font = arcade_font if arcade_font else ThemeDB.fallback_font
	var font_size = CREDITS_FONT_SIZE
	
	# Calculate the actual width of the text block
	var lines = credit_text.split("\n")
	var max_width = 0
	for line in lines:
		var line_width = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		max_width = max(max_width, line_width)
	
	# Use draw_multiline_string with the actual text width for proper centering
	var text_pos = Vector2(-max_width * 0.5, -float(lines.size()) * (float(font_size) + 2.0) * 0.5 + float(font_size))
	var color = Color(1, 1, 1, text_alpha)  # White with alpha
	draw_multiline_string(font, text_pos, credit_text, HORIZONTAL_ALIGNMENT_CENTER, max_width + 20, font_size, -1, color)
