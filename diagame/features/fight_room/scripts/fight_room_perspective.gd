extends "res://features/fight_room/scripts/fight_room.gd"

const LEFT_PERSPECTIVE_X: Array[float] = [300.0, 470.0, 640.0]
const RIGHT_PERSPECTIVE_X: Array[float] = [1620.0, 1450.0, 1280.0]
const PERSPECTIVE_Y: Array[float] = [650.0, 545.0, 455.0]
const PERSPECTIVE_SCALE: Array[float] = [1.0, 0.86, 0.74]
const CARD_DRAMA_ZOOM := 1.22
const REWARD_Y_OFFSET := 84.0
const REWARD_X_OFFSET := 10.0
const CAMERA_CENTER_X := 960.0
const CAMERA_YAW_MAX := 0.6
const CAMERA_DRAG_SENSITIVITY := 0.0035
const CAMERA_DEPTH_SWAY := 260.0

var camera_yaw: float = 0.0
var camera_drag_active: bool = false

func _build_fighter_lines():
	left_fighters.clear()
	right_fighters.clear()

	for i in range(selected_heroes.size()):
		var hero_id: int = selected_heroes[i]
		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		if not hero_textures.has(hero_id):
			hero_textures[hero_id] = load(str(hero.get("texture_path", "")))
		var slot_idx: int = mini(i, 2)
		var slot_scale: float = PERSPECTIVE_SCALE[slot_idx]
		var base: Vector2 = Vector2(LEFT_PERSPECTIVE_X[slot_idx], PERSPECTIVE_Y[slot_idx])
		left_fighters.append({
			"hero_id": hero_id,
			"base": base,
			"pos": base,
			"alpha": 1.0,
			"fade": false,
			"jump": false,
			"hspd": 0.0,
			"vspd": 0.0,
			"is_attacking": false,
			"attack_dir": 1,
			"visible": true,
			"tex": hero_textures.get(hero_id, null),
			"card_scale": slot_scale,
			"depth": slot_idx
		})

	for i in range(3):
		var enemy_id: int = mission_enemies[i]
		var raw_enemy: Variant = GameState.arrayEnemies[enemy_id]
		if raw_enemy == null:
			continue
		var enemy: Dictionary = raw_enemy
		if not enemy_textures.has(enemy_id):
			enemy_textures[enemy_id] = load(str(enemy.get("texture_path", "")))
		var slot_scale: float = PERSPECTIVE_SCALE[i]
		var base: Vector2 = Vector2(RIGHT_PERSPECTIVE_X[i], PERSPECTIVE_Y[i])
		right_fighters.append({
			"enemy_id": enemy_id,
			"base": base,
			"pos": base,
			"alpha": 1.0,
			"fade": false,
			"hspd": 0.0,
			"is_attacking": false,
			"attack_dir": -1,
			"visible": true,
			"tex": enemy_textures.get(enemy_id, null),
			"card_scale": slot_scale,
			"depth": i
		})

func _draw_lines():
	var drawables: Array[Dictionary] = []

	for i in range(left_fighters.size()):
		var f: Dictionary = left_fighters[i]
		if not bool(f.get("visible", true)):
			continue
		drawables.append({
			"side": "left",
			"index": i,
			"depth_key": float(f.get("depth", 0)),
		})

	for i in range(right_fighters.size()):
		var e: Dictionary = right_fighters[i]
		if not bool(e.get("visible", true)):
			continue
		drawables.append({
			"side": "right",
			"index": i,
			"depth_key": float(e.get("depth", 0)),
		})

	drawables.sort_custom(_compare_drawables_by_depth)

	for item in drawables:
		if String(item.get("side", "")) == "left":
			var i: int = int(item.get("index", 0))
			var fighter: Dictionary = left_fighters[i]
			_draw_single_card(fighter)
			if reward_visible:
				_draw_reward_label(fighter)
		else:
			var i2: int = int(item.get("index", 0))
			var enemy: Dictionary = right_fighters[i2]
			_draw_single_card(enemy)

func _draw_single_card(entity: Dictionary):
	var draw_scale: float = _get_effective_scale(entity)
	var draw_size: Vector2 = CARD_SIZE * draw_scale
	var center: Vector2 = _project_camera_point(Vector2(entity.get("pos", Vector2.ZERO)), draw_scale)
	var rect: Rect2 = Rect2(center - draw_size * 0.5, draw_size)
	var alpha: float = float(entity.get("alpha", 1.0))
	var tex: Texture2D = entity.get("tex", null)

	# Slight drop shadow helps sell depth in a pure 2D draw pipeline.
	draw_rect(Rect2(rect.position + Vector2(10, 12), rect.size), Color(0.0, 0.0, 0.0, 0.22 * alpha), true)

	if tex != null:
		draw_texture_rect(tex, rect, false, Color(1, 1, 1, alpha))
	else:
		draw_rect(rect, Color(0.3, 0.3, 0.3, alpha), true)

func _draw_reward_label(fighter: Dictionary):
	if arcade_font == null:
		return
	var draw_scale: float = _get_effective_scale(fighter)
	var base_pos: Vector2 = _project_camera_point(Vector2(fighter.get("base", Vector2.ZERO)), draw_scale)
	var width: float = CARD_SIZE.x * draw_scale
	var reward_anchor: Vector2 = base_pos + Vector2(-width * 0.5 + REWARD_X_OFFSET, REWARD_Y_OFFSET)
	var reward_text: String = "%d XP" % xp_reward
	draw_string(arcade_font, reward_anchor + Vector2(3, 3), reward_text, HORIZONTAL_ALIGNMENT_LEFT, 220, 24, Color(0, 0, 1))
	draw_string(arcade_font, reward_anchor, reward_text, HORIZONTAL_ALIGNMENT_LEFT, 220, 24, Color.WHITE)

func _compare_drawables_by_depth(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("depth_key", 0.0)) > float(b.get("depth_key", 0.0))

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		var me: InputEventMouseButton = event
		if me.button_index == MOUSE_BUTTON_RIGHT:
			camera_drag_active = me.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if camera_drag_active else Input.MOUSE_MODE_VISIBLE
			return

	if event is InputEventMouseMotion and camera_drag_active:
		var mm: InputEventMouseMotion = event
		camera_yaw = clamp(camera_yaw - mm.relative.x * CAMERA_DRAG_SENSITIVITY, -CAMERA_YAW_MAX, CAMERA_YAW_MAX)
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and key_event.keycode == KEY_HOME:
			_recenter_camera_angle()
			return
		if key_event.pressed and key_event.keycode == KEY_ESCAPE and camera_drag_active:
			camera_drag_active = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return

	if not (event is InputEventMouseButton) or not event.pressed:
		return

	var click: InputEventMouseButton = event
	if click.button_index != MOUSE_BUTTON_LEFT:
		return

	if not return_visible:
		return
	var local_p: Vector2 = to_local(click.position)
	if _get_return_button_rect().has_point(local_p):
		_return_to_mission_select()

func _recenter_camera_angle():
	camera_yaw = 0.0

func _exit_tree():
	camera_drag_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _get_effective_scale(entity: Dictionary) -> float:
	return float(entity.get("card_scale", 1.0)) * CARD_DRAMA_ZOOM

func _project_camera_point(source: Vector2, perspective_scale: float) -> Vector2:
	var centered_x: float = source.x - CAMERA_CENTER_X
	var depth_weight: float = lerp(0.42, 1.0, inverse_lerp(0.72, 1.0, perspective_scale))
	var swing: float = CAMERA_DEPTH_SWAY * camera_yaw * depth_weight
	var projected_x: float = CAMERA_CENTER_X + centered_x + swing
	var projected_y: float = source.y + absf(centered_x) * absf(camera_yaw) * 0.02
	return Vector2(projected_x, projected_y)
