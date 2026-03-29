extends Sprite2D

# Animated overlay stripe that moves across the screen
var fade: bool = true
var speed: float = -6.0  # Move left

func _ready():
	# Set the large scale like in GameMaker
	scale = Vector2(40, 11)

func _process(delta):
	# Handle fading animation
	var temp_alpha = clamp(modulate.a, 0.0, 1.0)

	if fade:
		if temp_alpha > 0:
			modulate.a -= 0.008
		if temp_alpha <= 0.5:
			fade = false
	else:
		if temp_alpha < 1:
			modulate.a += 0.008
		if temp_alpha >= 1:
			fade = true

	# Move the stripe
	position.x += speed

	# Destroy when off screen
	var tex_width: float = texture.get_width() if texture != null else 64.0
	if position.x <= -tex_width * scale.x:
		queue_free()
