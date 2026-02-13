extends Sprite2D

# Counter-rotating flare marker
var rotation_speed: float = -0.02

func _ready():
	pass

func _process(delta):
	# Rotate continuously in opposite direction
	rotation += rotation_speed * delta * 60.0  # Multiply by 60 to match GameMaker's frame-based rotation
