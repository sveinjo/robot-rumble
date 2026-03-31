extends Sprite2D

# Animated overlay stripe that moves across the screen
var fade: bool = true
var alpha_step_per_frame: float = 0.008

func _ready():
	# Set the large scale like in GameMaker
	centered = false
	scale = Vector2(40, 11)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	modulate.a = 1.0

func _process(delta):
	# Copy GameMaker step logic: pulse between alpha 1.0 and 0.5 in fixed increments.
	var alpha: float = clampf(modulate.a, 0.0, 1.0)
	var frame_scale: float = delta * 60.0

	if fade:
		if alpha > 0.0:
			alpha -= alpha_step_per_frame * frame_scale
		if alpha <= 0.5:
			fade = false
	else:
		if alpha < 1.0:
			alpha += alpha_step_per_frame * frame_scale
		if alpha >= 1.0:
			fade = true

	modulate.a = clampf(alpha, 0.0, 1.0)
