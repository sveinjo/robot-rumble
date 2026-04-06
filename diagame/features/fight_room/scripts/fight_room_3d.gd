extends Node3D

const SIDE_COLUMNS := 2
const ROWS_PER_COLUMN := 3
const LEFT_COLUMN_X: Array[float] = [-3.4, -1.9]
const RIGHT_COLUMN_X: Array[float] = [1.9, 3.4]
const ROW_Y: Array[float] = [1.55, 0.15, -1.25]
const ROW_Z: Array[float] = [0.0, -0.35, -0.7]
const ROW_SCALE: Array[float] = [1.0, 0.86, 0.74]
const ROW_X_SHIFT: Array[float] = [0.0, 0.22, 0.42]

const CARD_WORLD_SIZE := Vector2(1.76, 1.76)
const CAMERA_START_POS := Vector3(0.0, 0.0, 11.6)
const CAMERA_START_ROT := Vector3(0.0, 0.0, 0.0)
const CAMERA_YAW_MAX := 0.6
const CAMERA_PITCH_MAX := 0.3
const CAMERA_DRAG_SENSITIVITY := 0.0035

const START_DELAY := 40.0 / 60.0
const IMPACT_DELAY := 20.0 / 60.0
const CHAIN_DELAY := 60.0 / 60.0
const GROUP_FADE_DELAY := 20.0 / 60.0
const VICTORY_POST_DELAY := 60.0 / 60.0

const DRAMA_ZOOM_MIN := 0.8
const DRAMA_ZOOM_MAX := 2.2
const SPREAD_MIN := -260.0
const SPREAD_MAX := 260.0
const HOLD_ZOOM_SPEED := 0.9
const HOLD_SPREAD_SPEED := 240.0
const HOLD_VERTICAL_SPEED := 220.0
const POSITION_ZOOM_STRENGTH := 0.75
const AVG_DEPTH_WEIGHT := 0.72

@export var dramatic_zoom: float = 1.35
@export var horizontal_spread: float = 0.0
@export var vertical_spread: float = 0.0
@export var show_perspective_debug: bool = true

@onready var camera: Camera3D = $Camera3D
@onready var hero_root: Node3D = $Cards/HeroCards
@onready var enemy_root: Node3D = $Cards/EnemyCards
@onready var title_label: Label = $HUD/TitleLabel
@onready var banner_label: Label = $HUD/BannerLabel
@onready var debug_label: Label = $HUD/DebugLabel
@onready var return_button: Button = $HUD/ReturnButton

var card_mesh: QuadMesh
var arcade_font: Font
var flare_texture: Texture2D
var next_button_texture: Texture2D
var hero_textures: Dictionary = {}
var enemy_textures: Dictionary = {}

var selected_heroes: Array[int] = []
var mission_enemies: Array[int] = []
var mission_data: Dictionary = {}

var left_fighters: Array[Dictionary] = []
var right_fighters: Array[Dictionary] = []

var strike_index: int = 0
var enemies_left: int = 0
var win_flag: bool = false
var battle_started: bool = false
var battle_finished: bool = false
var return_visible: bool = false
var reward_visible: bool = false
var xp_reward: int = 0

var action_timer: float = 0.0
var hit_timer: float = 0.0
var post_victory_timer: float = 0.0
var pending_hit: bool = false
var pending_attack_from_left: bool = true
var pending_target_index: int = -1
var motion_step_accumulator: float = 0.0
var group_fade_timer: float = 0.0

var camera_rotation: Vector3 = Vector3.ZERO
var camera_drag_active: bool = false

func _ready():
	randomize()
	GameState.ensure_ported_data()
	arcade_font = GameState.arcade_font if GameState.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	flare_texture = load("res://assets/sprites/Flare.png")
	next_button_texture = load("res://assets/sprites/Next_0.png")

	card_mesh = QuadMesh.new()
	card_mesh.size = CARD_WORLD_SIZE

	_setup_3d_camera()
	_load_mission_state()
	_build_fighter_lines()
	_setup_overlay()
	_setup_ambient_fx()

	GameState.reset_starfield_defaults()
	GameState.clear_starfield_particles()
	GameState.set_starfield_spawn_interval(1.0 / 60.0)

	var roll: int = randi_range(0, 100)
	win_flag = roll <= int(round(GameState.intBattleWinChance))
	GameState.winFlag = 1 if win_flag else 0

	if win_flag:
		_apply_level_up_rewards()

	strike_index = 0
	enemies_left = right_fighters.size()
	action_timer = START_DELAY
	hit_timer = 0.0
	post_victory_timer = 0.0
	pending_hit = false
	group_fade_timer = 0.0
	battle_started = false
	_update_overlay()
	_sync_all_cards()

func _setup_3d_camera():
	camera.position = CAMERA_START_POS
	camera.rotation = CAMERA_START_ROT
	camera.current = true
	_update_camera_transform()

func _setup_overlay():
	return_button.visible = false
	return_button.pressed.connect(_return_to_mission_select)

func _load_mission_state():
	selected_heroes.clear()
	for i in range(1, 4):
		var slot: Variant = GameState.arrayEngageSlots[i]
		if slot == null:
			continue
		var hero_id: int = int(slot)
		if hero_id > 0:
			selected_heroes.append(hero_id)

	if selected_heroes.is_empty():
		get_tree().change_scene_to_file("res://features/play_field/scenes/play_field.tscn")
		return

	var raw_mission: Variant = GameState.arrayMissions[GameState.intMissionSelected]
	if raw_mission == null:
		get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")
		return
	mission_data = raw_mission
	xp_reward = int(mission_data.get("intXp", 0))

	mission_enemies.clear()
	var raw_enemies: Variant = mission_data.get("arrayEnemies", null)
	if raw_enemies != null:
		for v in raw_enemies:
			if v == null:
				continue
			var eid: int = int(v)
			if eid > 0:
				mission_enemies.append(eid)
			if mission_enemies.size() == 3:
				break
	while mission_enemies.size() < 3:
		mission_enemies.append(1)

func _build_fighter_lines():
	left_fighters.clear()
	right_fighters.clear()
	for child in hero_root.get_children():
		child.queue_free()
	for child in enemy_root.get_children():
		child.queue_free()

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
			var base := _make_base_position(true, col, row)
			var card := _create_card_node(hero_textures.get(hero_id, null), "Hero_%d_%d" % [row, col])
			hero_root.add_child(card)
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
				"node": card,
				"card_scale": ROW_SCALE[row],
				"depth": row + (col * 0.02),
			})

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
			var base := _make_base_position(false, col, row)
			var card := _create_card_node(enemy_textures.get(enemy_id, null), "Enemy_%d_%d" % [row, col])
			enemy_root.add_child(card)
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
				"node": card,
				"card_scale": ROW_SCALE[row],
				"depth": row + (col * 0.02),
			})

func _make_base_position(is_hero: bool, column: int, row: int) -> Vector3:
	var x_base: float = LEFT_COLUMN_X[column] if is_hero else RIGHT_COLUMN_X[column]
	var x_shift: float = ROW_X_SHIFT[row]
	var x: float = x_base + x_shift if is_hero else x_base - x_shift
	return Vector3(x, ROW_Y[row], ROW_Z[row])

func _create_card_node(texture: Texture2D, node_name: String) -> MeshInstance3D:
	var card := MeshInstance3D.new()
	card.name = node_name
	card.mesh = card_mesh
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.material_override = _make_card_material(texture)
	return card

func _make_card_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	return material

func _hero_for_row(row: int) -> int:
	if selected_heroes.is_empty():
		return 0
	if row < selected_heroes.size():
		return int(selected_heroes[row])
	return int(selected_heroes[selected_heroes.size() - 1])

func _enemy_for_row(row: int) -> int:
	if mission_enemies.is_empty():
		return 0
	if row < mission_enemies.size():
		return int(mission_enemies[row])
	return int(mission_enemies[mission_enemies.size() - 1])

func _process(delta: float):
	_update_runtime_tuning(delta)
	_update_battle_timeline(delta)
	_update_camera_transform()
	_update_motion(delta)
	_sync_all_cards()
	_update_overlay()

func _update_runtime_tuning(delta: float):
	var zoom_dir := 0.0
	if Input.is_key_pressed(KEY_PAGEUP):
		zoom_dir += 1.0
	if Input.is_key_pressed(KEY_PAGEDOWN):
		zoom_dir -= 1.0
	if not is_zero_approx(zoom_dir):
		dramatic_zoom = clamp(dramatic_zoom + zoom_dir * HOLD_ZOOM_SPEED * delta, DRAMA_ZOOM_MIN, DRAMA_ZOOM_MAX)

	var spread_dir := 0.0
	if Input.is_key_pressed(KEY_LEFT):
		spread_dir += 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		spread_dir -= 1.0
	if not is_zero_approx(spread_dir):
		horizontal_spread = clamp(horizontal_spread + spread_dir * HOLD_SPREAD_SPEED * delta, SPREAD_MIN, SPREAD_MAX)

	var vertical_dir := 0.0
	if Input.is_key_pressed(KEY_UP):
		vertical_dir += 1.0
	if Input.is_key_pressed(KEY_DOWN):
		vertical_dir -= 1.0
	if not is_zero_approx(vertical_dir):
		vertical_spread = clamp(vertical_spread + vertical_dir * HOLD_VERTICAL_SPEED * delta, SPREAD_MIN, SPREAD_MAX)

func _update_camera_transform():
	camera.rotation = camera_rotation

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		var me: InputEventMouseButton = event
		if me.button_index == MOUSE_BUTTON_RIGHT:
			camera_drag_active = me.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if camera_drag_active else Input.MOUSE_MODE_VISIBLE
			return

		if me.button_index == MOUSE_BUTTON_LEFT and me.pressed:
			if not battle_started:
				battle_started = true
				action_timer = START_DELAY
				return

	if event is InputEventMouseMotion and camera_drag_active:
		var mm: InputEventMouseMotion = event
		camera_rotation.y = clamp(camera_rotation.y - mm.relative.x * CAMERA_DRAG_SENSITIVITY, -CAMERA_YAW_MAX, CAMERA_YAW_MAX)
		camera_rotation.x = clamp(camera_rotation.x - mm.relative.y * CAMERA_DRAG_SENSITIVITY, -CAMERA_PITCH_MAX, CAMERA_PITCH_MAX)
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

func _recenter_camera_angle():
	camera_rotation = Vector3.ZERO

func _update_motion(delta: float):
	motion_step_accumulator += delta * 60.0
	var steps_to_run: int = mini(int(motion_step_accumulator), 8)
	if steps_to_run <= 0:
		return
	motion_step_accumulator -= float(steps_to_run)

	for _step in range(steps_to_run):
		_simulate_motion_step()

func _simulate_motion_step():
	for i in range(left_fighters.size()):
		var f: Dictionary = left_fighters[i]
		if bool(f.get("is_attacking", false)):
			_simulate_horizontal_bump(f)
		if bool(f.get("jump", false)):
			_simulate_vertical_jump(f)
		if bool(f.get("fade", false)):
			f["alpha"] = max(0.0, float(f.get("alpha", 1.0)) - 0.025)
			if float(f["alpha"]) <= 0.0:
				f["visible"] = false
		left_fighters[i] = f

	for i in range(right_fighters.size()):
		var g: Dictionary = right_fighters[i]
		if bool(g.get("is_attacking", false)):
			_simulate_horizontal_bump(g)
		if bool(g.get("fade", false)):
			g["alpha"] = max(0.0, float(g.get("alpha", 1.0)) - 0.025)
			if float(g["alpha"]) <= 0.0:
				g["visible"] = false
		right_fighters[i] = g

func _simulate_horizontal_bump(f: Dictionary):
	var pos: Vector3 = f["pos"]
	var base: Vector3 = f["base"]
	var hspd: float = float(f.get("hspd", 0.0))
	var attack_dir: int = int(f.get("attack_dir", 1))

	if not is_equal_approx(pos.x, base.x):
		hspd += -1.7

	for _px in range(int(abs(hspd))):
		if attack_dir > 0:
			if is_equal_approx(pos.x, base.x - 0.05):
				break
			pos.x += signf(hspd) * 0.05
		else:
			if is_equal_approx(pos.x, base.x + 0.05):
				break
			pos.x -= signf(hspd) * 0.05

	f["hspd"] = hspd
	f["pos"] = pos

	if absf(pos.x - base.x) <= 0.05 and hspd <= 0.0:
		f["pos"] = base
		f["hspd"] = 0.0
		f["is_attacking"] = false

func _simulate_vertical_jump(f: Dictionary):
	var pos: Vector3 = f["pos"]
	var base: Vector3 = f["base"]
	var vspd: float = float(f.get("vspd", 0.0))

	if not is_equal_approx(pos.y, base.y):
		vspd += 0.5
	else:
		vspd = -10.0

	for _py in range(int(abs(vspd))):
		if is_equal_approx(pos.y, base.y + 0.05):
			vspd = 0.0
			pos.y = base.y
			break
		pos.y += signf(vspd) * 0.05

	f["vspd"] = vspd
	f["pos"] = pos

func _sync_all_cards():
	for i in range(left_fighters.size()):
		_sync_card(left_fighters[i])
	for i in range(right_fighters.size()):
		_sync_card(right_fighters[i])

func _sync_card(entry: Dictionary):
	var node: MeshInstance3D = entry.get("node", null)
	if node == null:
		return
	var pos: Vector3 = _project_world_point(Vector3(entry.get("pos", Vector3.ZERO)), float(entry.get("card_scale", 1.0)))
	var scale_factor: float = float(entry.get("card_scale", 1.0)) * dramatic_zoom
	node.position = pos
	node.scale = Vector3.ONE * scale_factor
	node.visible = bool(entry.get("visible", true))
	node.modulate = Color(1.0, 1.0, 1.0, float(entry.get("alpha", 1.0)))
	node.look_at(camera.global_position, Vector3.UP)

func _project_world_point(source: Vector3, perspective_scale: float) -> Vector3:
	var centered_x: float = source.x
	var centered_y: float = source.y
	var depth_weight: float = lerp(0.42, 1.0, inverse_lerp(0.74, 1.0, perspective_scale))
	var zoom_delta: float = dramatic_zoom - 1.0
	var position_zoom_factor: float = 1.0 + (zoom_delta * POSITION_ZOOM_STRENGTH * depth_weight)
	var side_sign: float = 0.0
	if source.x < 0.0:
		side_sign = -1.0
	elif source.x > 0.0:
		side_sign = 1.0
	var depth_centered: float = depth_weight - AVG_DEPTH_WEIGHT
	return Vector3(
		centered_x * position_zoom_factor + (horizontal_spread * side_sign * depth_weight),
		centered_y * position_zoom_factor - (vertical_spread * depth_centered),
		source.z
	)

func _update_battle_timeline(delta: float):
	if not battle_started or battle_finished:
		if post_victory_timer > 0.0:
			post_victory_timer -= delta
			if post_victory_timer <= 0.0:
				reward_visible = true
				for i in range(left_fighters.size()):
					var f: Dictionary = left_fighters[i]
					if bool(f.get("visible", true)):
						f["jump"] = true
						left_fighters[i] = f
		return

	if pending_hit:
		hit_timer -= delta
		if hit_timer > 0.0:
			return
		_resolve_pending_hit()
		action_timer = CHAIN_DELAY
		pending_hit = false
		return

	if group_fade_timer > 0.0:
		group_fade_timer -= delta
		if group_fade_timer <= 0.0:
			for i in range(right_fighters.size()):
				var target: Dictionary = right_fighters[i]
				if bool(target.get("visible", true)):
					target["fade"] = true
					right_fighters[i] = target
			enemies_left = 0
			return_visible = true
			battle_finished = true
			post_victory_timer = VICTORY_POST_DELAY
		return

	action_timer -= delta
	if action_timer > 0.0:
		return

	if win_flag:
		_progress_win_sequence()
	else:
		_progress_lose_sequence()

func _progress_win_sequence():
	if strike_index < left_fighters.size() and strike_index < right_fighters.size():
		var attacker: Dictionary = left_fighters[strike_index]
		if bool(attacker.get("visible", true)):
			attacker["is_attacking"] = true
			attacker["hspd"] = 20.0
			attacker["attack_dir"] = 1
			left_fighters[strike_index] = attacker
		pending_hit = true
		hit_timer = IMPACT_DELAY
		pending_attack_from_left = true
		pending_target_index = strike_index
		return

	if enemies_left > 0:
		group_fade_timer = GROUP_FADE_DELAY
		return

	return_visible = true
	battle_finished = true
	post_victory_timer = VICTORY_POST_DELAY

func _progress_lose_sequence():
	if strike_index < right_fighters.size() and strike_index < left_fighters.size():
		var attacker: Dictionary = right_fighters[strike_index]
		if bool(attacker.get("visible", true)):
			attacker["is_attacking"] = true
			attacker["hspd"] = 20.0
			attacker["attack_dir"] = -1
			right_fighters[strike_index] = attacker
		pending_hit = true
		hit_timer = IMPACT_DELAY
		pending_attack_from_left = false
		pending_target_index = strike_index
		return

	_finish_battle(false)

func _resolve_pending_hit():
	if pending_attack_from_left:
		if pending_target_index >= 0 and pending_target_index < right_fighters.size():
			var target: Dictionary = right_fighters[pending_target_index]
			if bool(target.get("visible", true)):
				target["fade"] = true
				right_fighters[pending_target_index] = target
				enemies_left -= 1
		strike_index += 1
		if enemies_left <= 0:
			return_visible = true
			battle_finished = true
			post_victory_timer = VICTORY_POST_DELAY
	else:
		if pending_target_index >= 0 and pending_target_index < left_fighters.size():
			var victim: Dictionary = left_fighters[pending_target_index]
			if bool(victim.get("visible", true)):
				victim["fade"] = true
				left_fighters[pending_target_index] = victim
		strike_index += 1
		if strike_index >= left_fighters.size():
			_finish_battle(false)

func _finish_battle(player_won: bool):
	battle_finished = true
	return_visible = true
	reward_visible = false
	if player_won:
		post_victory_timer = VICTORY_POST_DELAY

func _apply_level_up_rewards():
	for i in range(1, 4):
		var hero_slot: Variant = GameState.arrayEngageSlots[i]
		if hero_slot == null:
			continue
		var hero_id: int = int(hero_slot)
		if hero_id <= 0:
			continue
		var raw_hero: Variant = GameState.arrayHeroes[hero_id]
		if raw_hero == null:
			continue
		var hero: Dictionary = raw_hero
		var new_xp: int = int(hero.get("intXp", 0)) + xp_reward
		hero["intXp"] = new_xp
		var level: int = int(hero.get("intLevel", 1))
		if level + 1 < GameState.arrayLevels.size() and new_xp >= int(GameState.arrayLevels[level + 1]):
			hero["intLevel"] = level + 1
		GameState.arrayHeroes[hero_id] = hero

	GameState.arrayMissions[GameState.intMissionSelected] = null

func _update_overlay():
	title_label.text = "BATTLE"

	if not battle_started:
		banner_label.text = "LEFT CLICK TO START"
		banner_label.modulate = Color(1.0, 0.95, 0.35)
	elif not battle_finished:
		banner_label.text = "RESOLVING..."
		banner_label.modulate = Color.WHITE
	else:
		banner_label.text = "VICTORY" if win_flag else "DEFEAT"
		banner_label.modulate = Color(0.2, 1.0, 0.2) if win_flag else Color(1.0, 0.2, 0.2)

	debug_label.text = "Zoom: %.2f\nHorizontal Spread: %.1f\nVertical Spread: %.1f" % [dramatic_zoom, horizontal_spread, vertical_spread]
	debug_label.visible = show_perspective_debug
	return_button.visible = return_visible
	return_button.disabled = not return_visible

func _setup_ambient_fx():
	pass

func _return_to_mission_select():
	GameState.reset_starfield_defaults()
	GameState.clear_starfield_particles()
	get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")