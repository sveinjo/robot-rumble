extends Sprite2D

# Particle star that scrolls from right to left
# Speed multiplier for parallax effect - set per star type
@export var speed_multiplier: int = 4

const FIGHT_STAR1_PATH := "res://assets/sprites/Star1d_0.png"
const FIGHT_STAR2_PATH := "res://assets/sprites/Star2d_0.png"
const FIGHT_STAR3_PATH := "res://assets/sprites/Star3d_0.png"

func apply_star_variant(variant: int):
	# 0 = fast, 1 = mid, 2 = slow
	if variant == 2:
		speed_multiplier = 1
	elif variant == 1:
		speed_multiplier = 2
	else:
		speed_multiplier = 4

func _ready():
	_apply_fight_room_texture_variant()
	# Match GameMaker: starSize only affects horizontal scale (image_xscale).
	scale = Vector2(GameState.star_size, scale.y)

func _process(delta: float):
	# Move horizontally
	var hspeed = -GameState.star_speed * speed_multiplier
	var step_scale := delta * 60.0
	position.x += hspeed * step_scale
	
	# Apply horizontal-only scale change.
	scale.x = GameState.star_size
	
	# Destroy when off-screen
	var texture_width := float(texture.get_width()) if texture else 0.0
	if position.x <= -texture_width:
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
