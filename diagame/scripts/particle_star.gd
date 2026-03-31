extends Sprite2D

# Particle star that scrolls from right to left
# Speed multiplier for parallax effect - set per star type
var speed_multiplier: int = 4

const FIGHT_STAR1_PATH := "res://assets/sprites/Star1d_0.png"
const FIGHT_STAR2_PATH := "res://assets/sprites/Star2d_0.png"
const FIGHT_STAR3_PATH := "res://assets/sprites/Star3d_0.png"

func _ready():
	_apply_fight_room_texture_variant()
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

func _apply_fight_room_texture_variant():
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	if not String(current_scene.scene_file_path).ends_with("fight_room.tscn"):
		return

	var replacement_path := ""
	if speed_multiplier >= 4:
		replacement_path = FIGHT_STAR1_PATH
	elif speed_multiplier >= 2:
		replacement_path = FIGHT_STAR2_PATH
	else:
		replacement_path = FIGHT_STAR3_PATH

	if ResourceLoader.exists(replacement_path):
		var replacement: Texture2D = load(replacement_path)
		if replacement != null:
			texture = replacement
