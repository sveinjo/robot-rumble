extends Sprite2D

# Rotating flare marker
var rotation_speed: float = 0.1

func _ready():
	pass

func _process(delta):
	# Rotate continuously (in degrees to match GameMaker centerGlow: image_angle += 0.1)
	rotation_degrees += rotation_speed * delta * 60.0  # Multiply by 60 to match GameMaker's frame-based rotation
