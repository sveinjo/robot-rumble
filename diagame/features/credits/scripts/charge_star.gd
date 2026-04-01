extends Sprite2D

const SCREEN_CENTER := Vector2(960.0, 540.0)

var speed: float = 3.0
var direction: Vector2 = Vector2.ZERO

func setup(spawn_pos: Vector2):
	position = spawn_pos
	direction = (SCREEN_CENTER - position).normalized()
	rotation = direction.angle()
	scale = Vector2(speed / 4.0, 1.0)

func _process(delta: float):
	var frame_scale := delta * 60.0
	position += direction * speed * frame_scale
	rotation = direction.angle()
	# Match GM step behavior: speed = speed * 1.03 once per frame.
	speed *= pow(1.03, frame_scale)
	scale.x = speed / 4.0

	if position.y >= 520.0 and position.y <= 560.0:
		queue_free()
