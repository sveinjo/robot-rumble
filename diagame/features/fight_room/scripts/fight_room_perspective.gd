extends "res://features/fight_room/scripts/fight_room.gd"

const SIDE_COLUMNS := 2
const ROWS_PER_COLUMN := 3
const LEFT_COLUMN_X: Array[float] = [320.0, 560.0]
const RIGHT_COLUMN_X: Array[float] = [1600.0, 1360.0]
const ROW_Y: Array[float] = [650.0, 560.0, 485.0]
const ROW_SCALE: Array[float] = [1.0, 0.86, 0.74]
const ROW_X_TO_CENTER_SHIFT: Array[float] = [0.0, 55.0, 105.0]

const REWARD_Y_OFFSET := 84.0
const REWARD_X_OFFSET := 10.0

const CAMERA_CENTER_X := 960.0
const CAMERA_YAW_MAX := 0.6
const CAMERA_DRAG_SENSITIVITY := 0.0035
const CAMERA_DEPTH_SWAY := 260.0

const DRAMA_ZOOM_MIN := 0.8
const DRAMA_ZOOM_MAX := 2.2
const SPREAD_MIN := -260.0
const SPREAD_MAX := 260.0
const HOLD_ZOOM_SPEED := 0.9
const HOLD_SPREAD_SPEED := 240.0

var camera_yaw: float = 0.0
var camera_drag_active: bool = false

@export var dramatic_zoom: float = 1.35
@export var horizontal_spread: float = 0.0
@export var show_perspective_debug: bool = true

func _ready():
	# initialize but keep core behavior from parent
	super._ready()
	battle_started = false
	action_timer = START_DELAY
	dramatic_zoom = clamp(dramatic_zoom, DRAMA_ZOOM_MIN, DRAMA_ZOOM_MAX)
	horizontal_spread = clamp(horizontal_spread, SPREAD_MIN, SPREAD_MAX)

func _process(delta: float):
	super._process(delta)
	_update_runtime_tuning(delta)

func _update_runtime_tuning(delta: float):
	var zoom_dir := 0.0
	if Input.is_key_pressed(KEY_PAGEUP):
		zoom_dir += 1.0
	if Input.is_key_pressed(KEY_PAGEDOWN):
		zoom_dir -= 1.0
	if not is_zero_approx(zoom_dir):
		dramatic_zoom = clamp(dramatic_zoom + zoom_dir * HOLD_ZOOM_SPEED * delta, DRAMA_ZOOM_MIN, DRAMA_ZOOM_MAX)

	var spread_dir := 0.0
	# Symmetric spread: left arrow pushes heroes outward-left and enemies outward-right.
	if Input.is_key_pressed(KEY_LEFT):
		spread_dir += 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		spread_dir -= 1.0
	if not is_zero_approx(spread_dir):
		horizontal_spread = clamp(horizontal_spread + spread_dir * HOLD_SPREAD_SPEED * delta, SPREAD_MIN, SPREAD_MAX)

func _build_fighter_lines():
	left_fighters.clear()
	right_fighters.clear()

	# Build heroes: 2 columns, each column contains the same 3-hero lineup (6 total).
	for row in range(ROWS_PER_COLUMN):
		var hero_id: int = _hero_for_row(row)
		if hero_id <= 0:
			continue
		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		if not hero_textures.has(hero_id):
			hero_textures[hero_id] = load(str(hero.get("texture_path", "")))

		for col in range(SIDE_COLUMNS):
			var slot_scale: float = ROW_SCALE[row]
			var x_shift_to_center: float = ROW_X_TO_CENTER_SHIFT[row]
			var base: Vector2 = Vector2(LEFT_COLUMN_X[col] + x_shift_to_center, ROW_Y[row])
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
				"depth": row + (col * 0.02),
			})

	# Build enemies: 2 columns, each column contains the same 3-enemy lineup (6 total).
	for row in range(ROWS_PER_COLUMN):
		var enemy_id: int = _enemy_for_row(row)
		if enemy_id <= 0:
			continue
		var raw_enemy: Variant = GameState.arrayEnemies[enemy_id]
		if raw_enemy == null:
			continue
		var enemy: Dictionary = raw_enemy
		if not enemy_textures.has(enemy_id):
			enemy_textures[enemy_id] = load(str(enemy.get("texture_path", "")))

		for col in range(SIDE_COLUMNS):
			var slot_scale: float = ROW_SCALE[row]
			var x_shift_to_center: float = ROW_X_TO_CENTER_SHIFT[row]
			var base: Vector2 = Vector2(RIGHT_COLUMN_X[col] - x_shift_to_center, ROW_Y[row])
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
				"depth": row + (col * 0.02),
			})

func _hero_for_row(row: int) -> int:
	if selected_heroes.is_empty():
		return 0
	if row < selected_heroes.size():
		return int(selected_heroes[row])
	# Fallback safety if squad is short.
	return int(selected_heroes[selected_heroes.size() - 1])

func _enemy_for_row(row: int) -> int:
	if mission_enemies.is_empty():
		return 0
	if row < mission_enemies.size():
		return int(mission_enemies[row])
	# Fallback safety if mission enemy list is short.
	return int(mission_enemies[mission_enemies.size() - 1])

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

	if not battle_started:
		battle_started = true
		action_timer = START_DELAY
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
	return float(entity.get("card_scale", 1.0)) * dramatic_zoom

func _draw_result_banner():
	if arcade_font == null:
		return
	if not battle_started:
		_draw_centered_shadowed_text("LEFT CLICK TO START", Vector2(TEXT_CENTER_X, BANNER_Y), 24, Color(1.0, 0.95, 0.35))
		return
	super._draw_result_banner()

func _draw_star_debug_counts():
	super._draw_star_debug_counts()
	if not show_perspective_debug:
		return
	if arcade_font == null:
		return
	var zoom_info: String = "Perspective Zoom: %.2f (hold PageUp/PageDown)" % dramatic_zoom
	var spread_info: String = "Horizontal Spread: %.1f (hold Left/Right)" % horizontal_spread
	draw_string(arcade_font, Vector2(32, 126), zoom_info, HORIZONTAL_ALIGNMENT_LEFT, 980, 16, Color(1.0, 0.9, 0.45, 0.95))
	draw_string(arcade_font, Vector2(32, 146), spread_info, HORIZONTAL_ALIGNMENT_LEFT, 980, 16, Color(1.0, 0.9, 0.45, 0.95))

func _project_camera_point(source: Vector2, perspective_scale: float) -> Vector2:
	var centered_x: float = source.x - CAMERA_CENTER_X
	var depth_weight: float = lerp(0.42, 1.0, inverse_lerp(0.72, 1.0, perspective_scale))
	var swing: float = CAMERA_DEPTH_SWAY * camera_yaw * depth_weight

	var side_sign := 0.0
	if source.x < CAMERA_CENTER_X:
		side_sign = -1.0
	elif source.x > CAMERA_CENTER_X:
		side_sign = 1.0

	var projected_x: float = CAMERA_CENTER_X + centered_x + swing + (horizontal_spread * side_sign)
	var projected_y: float = source.y + absf(centered_x) * absf(camera_yaw) * 0.02
	return Vector2(projected_x, projected_y)
