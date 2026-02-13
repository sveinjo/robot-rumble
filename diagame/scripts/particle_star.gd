extends Sprite2D

# Particle star that scrolls from right to left
# Speed multiplier for parallax effect - set per star type
var speed_multiplier: int = 4

func _ready():
	# Set initial horizontal speed (moving left)
	var hspeed = -Global.star_speed * speed_multiplier
	scale = Vector2(Global.star_size, Global.star_size)

func _process(delta):
	# Move horizontally
	var hspeed = -Global.star_speed * speed_multiplier
	position.x += hspeed
	
	# Apply scale
	scale = Vector2(Global.star_size, Global.star_size)
	
	# Destroy when off-screen
	if position.x <= texture.get_width() if texture else 0:
		queue_free()
