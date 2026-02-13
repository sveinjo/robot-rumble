extends Sprite2D

# Rotating flare marker
var rotation_speed: float = 0.02

func _ready():
	pass

func _process(delta):
	# Rotate continuously
	rotation += rotation_speed * delta * 60.0  # Multiply by 60 to match GameMaker's frame-based rotation
