extends Sprite2D

# Particle star that scrolls from right to left
# Speed multiplier for parallax effect - set per star type
var speed_multiplier: int = 4

func _ready():
	# Set initial horizontal speed (moving left)
	var hspeed = -Global.star_speed * speed_multiplier
	# Match GameMaker: starSize only affects horizontal scale (image_xscale).
	scale = Vector2(Global.star_size, scale.y)

func _process(delta):
	# Move horizontally
	var hspeed = -Global.star_speed * speed_multiplier
	position.x += hspeed
	
	# Apply horizontal-only scale change.
	scale.x = Global.star_size
	
	# Destroy when off-screen
	if position.x <= texture.get_width() if texture else 0:
		queue_free()
