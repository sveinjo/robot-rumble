extends Node3D

const SIDE_COLUMNS := 2
const ROWS_PER_COLUMN := 3
const LEFT_COLUMN_X_SCREEN: Array[float] = [320.0, 560.0]
const RIGHT_COLUMN_X_SCREEN: Array[float] = [1600.0, 1360.0]
const ROW_Y_SCREEN: Array[float] = [635.0, 560.0, 485.0]
const ROW_X_TO_CENTER_SHIFT_SCREEN: Array[float] = [55.0, 55.0, 55.0]
const ROW_Z: Array[float] = [0.0, -0.35, -0.7]
const ROW_SCALE: Array[float] = [1.0, 1.0, 1.0]

const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const WORLD_VIEW_SIZE := Vector2(19.2, 10.8)
const WORLD_PER_PIXEL_X := WORLD_VIEW_SIZE.x / DESIGN_SIZE.x
const WORLD_PER_PIXEL_Y := WORLD_VIEW_SIZE.y / DESIGN_SIZE.y

const CARD_WORLD_SIZE := Vector2(1.76, 1.76)
const CARD_FRAME_TEXTURE_PATH := "res://assets/sprites/Frame_0.png"
const CARD_FRAME_HQ_TEXTURE_PATH := "res://assets/sprites/HQ/Frame3.png"
const CARD_FRAME_INNER_HEIGHT_RATIO := 0.75
const CARD_FRAME_DEPTH_OFFSET := 0.018
const CARD_SHADOW_MODEL_Z_OFFSET := -0.015
const CARD_SHADOW_MODEL_FIT_RATIO := 0.95
const CENTER_CARD_MODEL_PATH := "res://assets/models/cards/Card.glb"
const DEPTH_MIN_BRIGHTNESS := 0.55
const DEPTH_MAX_BRIGHTNESS := 1.0
const CAMERA_START_POS := Vector3(0.0, 0.0, 9.84)
const CAMERA_START_ROT := Vector3(0.0, 0.0, 0.0)
const CAMERA_DRAG_SENSITIVITY := 0.0035
const CAMERA_MIN_Z := 2.0
const CAMERA_MAX_Z := 30.0
const STAR_LAYER_Z := -2.6
const STAR_COUNT := 180
const STAR_WORLD_SPEED_SCALE := 0.0065
const STAR_SPEED_MULTIPLIERS: Array[float] = [4.0, 2.0, 1.0]
const STAR_SIZE_BY_TIER: Array[float] = [1.0, 0.72, 0.5]
const STAR_X_SIZE_FACTOR := 0.09
const STAR_Y_BASE := 0.085
const STAR_Y_JITTER_MIN := 0.9
const STAR_Y_JITTER_MAX := 1.1
const STAR_GLOBAL_SCALE_MIN := 0.5
const STAR_GLOBAL_SCALE_MAX := 20.0
const STAR_GLOBAL_SCALE_STEP := 0.25

const START_DELAY := 40.0 / 60.0
const IMPACT_DELAY := 20.0 / 60.0
const CHAIN_DELAY := 60.0 / 60.0
const GROUP_FADE_DELAY := 20.0 / 60.0
const VICTORY_POST_DELAY := 60.0 / 60.0

const HOLD_ZOOM_SPEED := 0.45
const HOLD_SPREAD_SPEED := 36.0
const HOLD_VERTICAL_SPEED := 120.0
const LIGHT_MOVE_SPEED := 0.05
const FRONT_LIGHT_LEFT_BASE_X := -4.5
const FRONT_LIGHT_RIGHT_BASE_X := 4.5
const FRONT_LIGHT_BASE_Y := -3.75
const FRONT_LIGHT_BASE_Z := 5.20
const FRONT_LIGHT_SWAP_PERIOD := 8.0
const DEFAULT_DRAMATIC_ZOOM := 3.4
const DEFAULT_HORIZONTAL_SPREAD := -182.0
const DEFAULT_VERTICAL_SPREAD := 270.0
const AA_MODE_LINEAR := 0
const AA_MODE_POINT_SSAA := 1
const AA_MODE_NEAREST_NO_AA := 2
const AA_MODE_NEAREST_MIPMAP := 3
const AA_MODE_NEAREST_SSAA := 4
const AA_MODE_BILINEAR_NO_AA := 5
const SSAA_SAMPLE_OFFSETS: Array[Vector2] = [
	Vector2(-0.25, -0.25),
	Vector2(0.25, -0.25),
	Vector2(-0.25, 0.25),
	Vector2(0.25, 0.25),
]
const SSAA_SAMPLE_ALPHA := 0.25

@export var dramatic_zoom: float = 1.35
@export var horizontal_spread: float = 0.0
@export var vertical_spread: float = 0.0
@export var show_perspective_debug: bool = true

@onready var camera: Camera3D = $Camera3D
@onready var hero_root: Node3D = $Cards/HeroCards
@onready var enemy_root: Node3D = $Cards/EnemyCards
@onready var stars_root: Node3D = $Stars
@onready var title_label: Label = get_node_or_null("HUD/TitleLabel") as Label
@onready var banner_label: Label = get_node_or_null("HUD/BannerLabel") as Label
@onready var debug_label: Label = get_node_or_null("HUD/DebugLabel") as Label
@onready var return_button: Button = get_node_or_null("HUD/ReturnButton") as Button
@onready var front_light_left: OmniLight3D = get_node_or_null("FrontRowLightLeft") as OmniLight3D
@onready var front_light_right: OmniLight3D = get_node_or_null("FrontRowLightRight") as OmniLight3D

var card_mesh: Mesh
var frame_mesh_size: Vector2 = CARD_WORLD_SIZE
var arcade_font: Font
var flare_texture: Texture2D
var next_button_texture: Texture2D
var frame_texture: Texture2D
var hero_textures: Dictionary = {}
var enemy_textures: Dictionary = {}
var star_materials: Array[StandardMaterial3D] = []
var star_spawn_half_extents: Vector2 = Vector2(11.2, 5.1)
var star_global_scale: float = 1.0
var star_auto_scale: float = 1.0
var aa_mode: int = AA_MODE_BILINEAR_NO_AA
var light_y_offset: float = 0.0
var light_z_offset: float = 0.0
var light_swap_time: float = 0.0
var center_card_model: Node3D
var card_model_scene: PackedScene

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
	var viewport := get_viewport()
	if viewport != null:
		viewport.msaa_3d = Viewport.MSAA_4X
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	dramatic_zoom = DEFAULT_DRAMATIC_ZOOM
	horizontal_spread = DEFAULT_HORIZONTAL_SPREAD
	vertical_spread = DEFAULT_VERTICAL_SPREAD
	arcade_font = GameState.arcade_font if GameState.arcade_font else load("res://assets/fonts/PressStart2P-Regular.ttf")
	flare_texture = load("res://assets/sprites/Flare.png")
	next_button_texture = load("res://assets/sprites/Next_0.png")

	card_mesh = QuadMesh.new()
	card_mesh.size = CARD_WORLD_SIZE
	frame_texture = _load_frame_texture()
	frame_mesh_size = _compute_frame_mesh_size(frame_texture)
	card_model_scene = load(CENTER_CARD_MODEL_PATH) as PackedScene if ResourceLoader.exists(CENTER_CARD_MODEL_PATH) else null

	_setup_3d_camera()
	_load_mission_state()
	_setup_world_stars()
	_build_fighter_lines()
	_setup_overlay()
	_setup_ambient_fx()

	GameState.reset_starfield_defaults()
	GameState.clear_starfield_particles()
	GameState.set_starfield_enabled(false)
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
	_apply_viewport_aa_mode()
	_update_overlay()
	_sync_all_cards()

func _setup_3d_camera():
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 40.0
	camera.near = 0.1
	camera.far = 200.0
	camera.position = CAMERA_START_POS
	camera.rotation = CAMERA_START_ROT
	camera_rotation = CAMERA_START_ROT
	camera.current = true
	_update_camera_transform()

func _setup_world_stars():
	for child in stars_root.get_children():
		child.queue_free()
	star_materials.clear()
	star_spawn_half_extents = _compute_star_spawn_extents()

	var star_textures: Array[Texture2D] = [
		load("res://assets/sprites/Star1d_0.png"),
		load("res://assets/sprites/Star2d_0.png"),
		load("res://assets/sprites/Star3d_0.png")
	]
	star_auto_scale = _estimate_star_global_scale(star_textures)
	star_global_scale = star_auto_scale

	for _i in range(STAR_COUNT):
		var star := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2.ONE
		star.mesh = mesh
		star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var star_tier: int = randi() % 3
		var speed_multiplier: float = STAR_SPEED_MULTIPLIERS[star_tier]
		var tier_size: float = STAR_SIZE_BY_TIER[star_tier]
		var y_base: float = STAR_Y_BASE * tier_size * randf_range(STAR_Y_JITTER_MIN, STAR_Y_JITTER_MAX)
		# var y_scale: float = y_base * star_global_scale
		var y_scale: float = y_base * 2
		var x_scale: float = maxf(0.03, GameState.star_size * STAR_X_SIZE_FACTOR * tier_size * star_global_scale)
		star.scale = Vector3(x_scale, y_scale, 1.0)
		star.set_meta("star_tier", star_tier)
		star.set_meta("speed_multiplier", speed_multiplier)
		star.set_meta("tier_size", tier_size)
		star.set_meta("y_base", y_base)

		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# Disable wrap to prevent opposite-edge bleed on elongated star quads.
		mat.texture_repeat = 0
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		# Match 2D/perspective mapping: fast->Star1d, mid->Star2d, slow->Star3d.
		if speed_multiplier >= 4.0:
			mat.albedo_texture = star_textures[0]
		elif speed_multiplier >= 2.0:
			mat.albedo_texture = star_textures[1]
		else:
			mat.albedo_texture = star_textures[2]
		mat.albedo_color = Color(1.0, 1.0, 1.0, randf_range(0.18, 0.5))
		star.material_override = mat
		star_materials.append(mat)

		star.position = Vector3(
			randf_range(-star_spawn_half_extents.x, star_spawn_half_extents.x),
			randf_range(-star_spawn_half_extents.y, star_spawn_half_extents.y),
			STAR_LAYER_Z + randf_range(-0.1, 0.1)
		)
		stars_root.add_child(star)

func _compute_star_spawn_extents() -> Vector2:
	var aspect: float = DESIGN_SIZE.x / DESIGN_SIZE.y
	var depth_from_camera: float = maxf(0.1, CAMERA_START_POS.z - STAR_LAYER_Z)
	var half_height: float = tan(deg_to_rad(camera.fov * 0.5)) * depth_from_camera
	var half_width: float = half_height * aspect
	# Small margin avoids visible pop-in at edges while wrapping.
	return Vector2(half_width * 1.15, half_height * 1.15)

func _estimate_star_global_scale(star_textures: Array[Texture2D]) -> float:
	var samples := 0
	var width_sum := 0.0
	for tex in star_textures:
		if tex == null:
			continue
		var sz: Vector2 = tex.get_size()
		if sz.x <= 0.0:
			continue
		width_sum += sz.x
		samples += 1

	if samples <= 0:
		return 6.0

	# Convert average source texture width into world units using backdrop-design mapping.
	var avg_tex_width: float = width_sum / float(samples)
	var target_world_width: float = avg_tex_width * WORLD_PER_PIXEL_X
	var base_world_width: float = STAR_X_SIZE_FACTOR * STAR_SIZE_BY_TIER[0]
	if base_world_width <= 0.0001:
		return 6.0

	return clampf(target_world_width / base_world_width, STAR_GLOBAL_SCALE_MIN, STAR_GLOBAL_SCALE_MAX)

func _update_world_stars(delta: float):
	# Match perspective fight-room behavior: keep accelerating star speed until capped.
	if GameState.star_speed < 14.0:
		GameState.star_speed = min(14.0, GameState.star_speed * 1.05)
		GameState.star_size = min(10.0, GameState.star_size * 1.05)

	var step_world: float = maxf(0.01, GameState.star_speed * STAR_WORLD_SPEED_SCALE * delta * 60.0)
	for star in stars_root.get_children():
		if not (star is Node3D):
			continue
		var n: Node3D = star
		var speed_multiplier: float = float(n.get_meta("speed_multiplier", 1.0))
		var y_base: float = float(n.get_meta("y_base", STAR_Y_BASE))
		var tier_size: float = float(n.get_meta("tier_size", 1.0))
		n.position.x -= step_world * speed_multiplier
		n.scale.x = maxf(0.03, GameState.star_size * STAR_X_SIZE_FACTOR * tier_size * star_global_scale)
		# n.scale.y = y_base * star_global_scale
		if n.position.x < -star_spawn_half_extents.x:
			n.position.x = star_spawn_half_extents.x
			n.position.y = randf_range(-star_spawn_half_extents.y, star_spawn_half_extents.y)

func _setup_overlay():
	if return_button == null:
		pass
	else:
		return_button.visible = false
		if not return_button.pressed.is_connected(_return_to_mission_select):
			return_button.pressed.connect(_return_to_mission_select)

	if debug_label != null:
		debug_label.visible = true
		debug_label.modulate = Color(1.0, 0.92, 0.45, 0.95)

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
			hero_textures[hero_id] = _load_card_texture(str(hero.get("texture_path", "")))

		for col in range(SIDE_COLUMNS):
			var base := _make_base_position(true, col, row)
			var card := _create_card_node(hero_textures.get(hero_id, null), "Hero_%d_%d" % [row, col])
			var frame := _create_frame_node("HeroFrame_%d_%d" % [row, col])
			var shadow_box := _create_shadow_box_node("HeroShadow_%d_%d" % [row, col])
			hero_root.add_child(card)
			hero_root.add_child(frame)
			hero_root.add_child(shadow_box)
			var ssaa_nodes: Array[MeshInstance3D] = _create_ssaa_nodes(hero_textures.get(hero_id, null), "Hero_%d_%d" % [row, col], hero_root)
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
				"frame_node": frame,
				"shadow_box_node": shadow_box,
				"card_scale": ROW_SCALE[row],
				"side_sign": -1.0,
				"depth": row + (col * 0.02),
				"ssaa_nodes": ssaa_nodes,
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
			enemy_textures[enemy_id] = _load_card_texture(str(enemy.get("texture_path", "")))

		for col in range(SIDE_COLUMNS):
			var base := _make_base_position(false, col, row)
			var card := _create_card_node(enemy_textures.get(enemy_id, null), "Enemy_%d_%d" % [row, col])
			var frame := _create_frame_node("EnemyFrame_%d_%d" % [row, col])
			var shadow_box := _create_shadow_box_node("EnemyShadow_%d_%d" % [row, col])
			enemy_root.add_child(card)
			enemy_root.add_child(frame)
			enemy_root.add_child(shadow_box)
			var ssaa_nodes: Array[MeshInstance3D] = _create_ssaa_nodes(enemy_textures.get(enemy_id, null), "Enemy_%d_%d" % [row, col], enemy_root)
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
				"frame_node": frame,
				"shadow_box_node": shadow_box,
				"card_scale": ROW_SCALE[row],
				"side_sign": 1.0,
				"depth": row + (col * 0.02),
				"ssaa_nodes": ssaa_nodes,
			})

func _make_base_position(is_hero: bool, column: int, row: int) -> Vector3:
	var x_base: float = LEFT_COLUMN_X_SCREEN[column] if is_hero else RIGHT_COLUMN_X_SCREEN[column]
	var x_shift: float = ROW_X_TO_CENTER_SHIFT_SCREEN[row]
	var x_screen: float = x_base + x_shift if is_hero else x_base - x_shift
	var y_screen: float = ROW_Y_SCREEN[row]
	return _screen_to_world(Vector2(x_screen, y_screen), ROW_Z[row])

func _screen_to_world(screen_pos: Vector2, z_depth: float) -> Vector3:
	var centered: Vector2 = screen_pos - (DESIGN_SIZE * 0.5)
	var x_world: float = centered.x * (WORLD_VIEW_SIZE.x / DESIGN_SIZE.x)
	var y_world: float = -centered.y * (WORLD_VIEW_SIZE.y / DESIGN_SIZE.y)
	return Vector3(x_world, y_world, z_depth)

func _create_card_node(texture: Texture2D, node_name: String) -> MeshInstance3D:
	var card := MeshInstance3D.new()
	card.name = node_name
	card.mesh = card_mesh
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.material_override = _make_card_material(texture)
	return card

func _create_frame_node(node_name: String) -> MeshInstance3D:
	var frame := MeshInstance3D.new()
	frame.name = node_name
	var frame_mesh := QuadMesh.new()
	frame_mesh.size = frame_mesh_size
	frame.mesh = frame_mesh
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	frame.material_override = _make_frame_material(frame_texture)
	return frame

func _create_shadow_box_node(node_name: String) -> Node3D:
	var shadow_root := Node3D.new()
	shadow_root.name = node_name
	if card_model_scene == null:
		return shadow_root

	var model_node: Node = card_model_scene.instantiate()
	if not (model_node is Node3D):
		return shadow_root

	var model_root := model_node as Node3D
	shadow_root.add_child(model_root)
	_fit_model_to_frame(model_root)
	_set_shadow_mode_recursive(model_root)
	return shadow_root

func _fit_model_to_frame(model_root: Node3D):
	var bounds := _get_model_bounds(model_root)
	if not bool(bounds.get("valid", false)):
		return

	var min_v: Vector3 = bounds["min"]
	var max_v: Vector3 = bounds["max"]
	var size: Vector3 = max_v - min_v
	if size.x <= 0.0001 or size.y <= 0.0001:
		return

	var target_w: float = frame_mesh_size.x * CARD_SHADOW_MODEL_FIT_RATIO
	var target_h: float = frame_mesh_size.y * CARD_SHADOW_MODEL_FIT_RATIO
	var uniform_scale: float = minf(target_w / size.x, target_h / size.y)
	model_root.scale = Vector3.ONE * uniform_scale

	var center_local: Vector3 = (min_v + max_v) * 0.5
	model_root.position = -center_local * uniform_scale

func _set_shadow_mode_recursive(node: Node):
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		mesh_node.material_override = _make_shadow_box_material()
	for child in node.get_children():
		_set_shadow_mode_recursive(child)

func _get_model_bounds(root: Node3D) -> Dictionary:
	var bounds := {
		"valid": false,
		"min": Vector3(INF, INF, INF),
		"max": Vector3(-INF, -INF, -INF)
	}
	_accumulate_model_bounds(root, Transform3D.IDENTITY, bounds)
	return bounds

func _accumulate_model_bounds(node: Node, parent_xf: Transform3D, bounds: Dictionary):
	if not (node is Node3D):
		return
	var n3d := node as Node3D
	var current_xf: Transform3D = parent_xf * n3d.transform

	if n3d is MeshInstance3D:
		var mi := n3d as MeshInstance3D
		if mi.mesh != null:
			var aabb: AABB = mi.mesh.get_aabb()
			for corner in _aabb_corners(aabb):
				var p: Vector3 = current_xf * corner
				bounds["min"] = (bounds["min"] as Vector3).min(p)
				bounds["max"] = (bounds["max"] as Vector3).max(p)
				bounds["valid"] = true

	for child in n3d.get_children():
		_accumulate_model_bounds(child, current_xf, bounds)

func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p: Vector3 = aabb.position
	var s: Vector3 = aabb.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s,
	]

func _setup_center_card_model():
	if card_model_scene == null:
		return
	var instanced_model: Node = card_model_scene.instantiate()
	if not (instanced_model is Node3D):
		return

	center_card_model = instanced_model as Node3D
	center_card_model.name = "CenterCardModel"
	_fit_model_to_frame(center_card_model)
	center_card_model.position = _screen_to_world(Vector2(DESIGN_SIZE.x * 0.5, ROW_Y_SCREEN[1]), ROW_Z[1])
	center_card_model.rotation = Vector3.ZERO
	center_card_model.scale *= ROW_SCALE[1]
	add_child(center_card_model)

func _create_ssaa_nodes(texture: Texture2D, node_prefix: String, parent: Node3D) -> Array[MeshInstance3D]:
	var nodes: Array[MeshInstance3D] = []
	for i in range(SSAA_SAMPLE_OFFSETS.size()):
		var sample := _create_card_node(texture, "%s_SSAA_%d" % [node_prefix, i])
		sample.visible = false
		parent.add_child(sample)
		nodes.append(sample)
	return nodes

func _make_card_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_BACK
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.albedo_texture = texture
	return material

func _make_frame_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_BACK
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.albedo_texture = texture
	return material

func _make_shadow_box_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_BACK
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.0, 0.0, 0.0, 1.0)
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

func _load_card_texture(texture_path: String) -> Texture2D:
	if texture_path.is_empty():
		return null

	var hq_path := _resolve_hq_texture_path(texture_path)
	if not hq_path.is_empty() and ResourceLoader.exists(hq_path):
		return load(hq_path)

	if ResourceLoader.exists(texture_path):
		return load(texture_path)

	return null

func _resolve_hq_texture_path(texture_path: String) -> String:
	if texture_path.is_empty():
		return ""

	var file_name: String = texture_path.get_file()
	var base_name: String = file_name.get_basename().to_lower()
	if base_name.ends_with("_0"):
		base_name = base_name.substr(0, base_name.length() - 2)

	var candidates: Array[String] = [
		"res://assets/sprites/HQ/%s.%s" % [base_name, file_name.get_extension().to_lower()],
		"res://assets/sprites/HQ/%s.png" % base_name,
		"res://assets/sprites/HQ/%s.jpg" % base_name,
	]

	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			return candidate

	return ""

func _calculate_card_brightness(z_depth: float) -> float:
	var back_row_z: float = ROW_Z[ROWS_PER_COLUMN - 1]
	var front_row_z: float = ROW_Z[0]
	var z_range: float = front_row_z - back_row_z
	if z_range <= 0.0:
		return DEPTH_MAX_BRIGHTNESS
	var normalized: float = clamp((z_depth - back_row_z) / z_range, 0.0, 1.0)
	return lerp(DEPTH_MIN_BRIGHTNESS, DEPTH_MAX_BRIGHTNESS, normalized)

func _load_frame_texture() -> Texture2D:
	if ResourceLoader.exists(CARD_FRAME_HQ_TEXTURE_PATH):
		return load(CARD_FRAME_HQ_TEXTURE_PATH)
	if ResourceLoader.exists(CARD_FRAME_TEXTURE_PATH):
		return load(CARD_FRAME_TEXTURE_PATH)
	return null

func _compute_frame_mesh_size(texture: Texture2D) -> Vector2:
	if texture == null:
		return CARD_WORLD_SIZE

	var tex_size: Vector2 = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return CARD_WORLD_SIZE

	var aspect: float = tex_size.x / tex_size.y
	var frame_height: float = CARD_WORLD_SIZE.y / maxf(0.01, CARD_FRAME_INNER_HEIGHT_RATIO)
	return Vector2(frame_height * aspect, frame_height)

func _process(delta: float):
	light_swap_time = fposmod(light_swap_time + delta, FRONT_LIGHT_SWAP_PERIOD)
	_update_runtime_tuning(delta)
	_update_battle_timeline(delta)
	_update_camera_transform()
	_update_world_stars(delta)
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
		dramatic_zoom += zoom_dir * HOLD_ZOOM_SPEED * delta

	var spread_dir := 0.0
	if Input.is_key_pressed(KEY_LEFT):
		spread_dir += 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		spread_dir -= 1.0
	if not is_zero_approx(spread_dir):
		horizontal_spread += spread_dir * HOLD_SPREAD_SPEED * delta

	var vertical_dir := 0.0
	if Input.is_key_pressed(KEY_UP):
		vertical_dir += 1.0
	if Input.is_key_pressed(KEY_DOWN):
		vertical_dir -= 1.0
	if not is_zero_approx(vertical_dir):
		vertical_spread += vertical_dir * HOLD_VERTICAL_SPEED * delta

func _update_camera_transform():
	# Keep camera position stable; depth drama is expressed by row Z offsets in perspective.
	camera.position = CAMERA_START_POS
	camera.rotation = camera_rotation

	var light_center_x: float = (FRONT_LIGHT_LEFT_BASE_X + FRONT_LIGHT_RIGHT_BASE_X) * 0.5
	var light_amplitude: float = (FRONT_LIGHT_RIGHT_BASE_X - FRONT_LIGHT_LEFT_BASE_X) * 0.5
	var light_phase: float = TAU * (light_swap_time / maxf(0.001, FRONT_LIGHT_SWAP_PERIOD))
	var left_x: float = light_center_x - (cos(light_phase) * light_amplitude)
	var right_x: float = light_center_x + (cos(light_phase) * light_amplitude)
	
	if front_light_left != null:
		var left_pos: Vector3 = front_light_left.position
		left_pos.x = left_x
		left_pos.y = FRONT_LIGHT_BASE_Y + light_y_offset
		left_pos.z = FRONT_LIGHT_BASE_Z + light_z_offset
		front_light_left.position = left_pos
	if front_light_right != null:
		var right_pos: Vector3 = front_light_right.position
		right_pos.x = right_x
		right_pos.y = FRONT_LIGHT_BASE_Y + light_y_offset
		right_pos.z = FRONT_LIGHT_BASE_Z + light_z_offset
		front_light_right.position = right_pos

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
		# Debug orbit mode: yaw + pitch like credits camera.
		camera_rotation.y -= mm.relative.x * CAMERA_DRAG_SENSITIVITY
		camera_rotation.x -= mm.relative.y * CAMERA_DRAG_SENSITIVITY
		camera_rotation.x = clamp(camera_rotation.x, -PI / 2.0, PI / 2.0)
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed:
			if key_event.keycode == KEY_TAB:
				_toggle_aa_mode()
				return
			if key_event.keycode == KEY_HOME:
				_reset_to_defaults()
				return
			if key_event.keycode == KEY_ESCAPE and camera_drag_active:
				camera_drag_active = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				return
			if key_event.keycode == KEY_KP_8:
				light_y_offset += LIGHT_MOVE_SPEED
				return
			if key_event.keycode == KEY_KP_5:
				light_y_offset -= LIGHT_MOVE_SPEED
				return
			if key_event.keycode == KEY_INSERT:
				light_z_offset += LIGHT_MOVE_SPEED
				return
			if key_event.keycode == KEY_DELETE:
				light_z_offset -= LIGHT_MOVE_SPEED
				return
			if key_event.keycode == KEY_KP_ADD:
				star_global_scale = clampf(star_global_scale + STAR_GLOBAL_SCALE_STEP, STAR_GLOBAL_SCALE_MIN, STAR_GLOBAL_SCALE_MAX)
				return
			if key_event.keycode == KEY_KP_SUBTRACT:
				star_global_scale = clampf(star_global_scale - STAR_GLOBAL_SCALE_STEP, STAR_GLOBAL_SCALE_MIN, STAR_GLOBAL_SCALE_MAX)
				return

func _recenter_camera_angle():
	camera_rotation = CAMERA_START_ROT

func _reset_to_defaults():
	dramatic_zoom = DEFAULT_DRAMATIC_ZOOM
	horizontal_spread = DEFAULT_HORIZONTAL_SPREAD
	vertical_spread = DEFAULT_VERTICAL_SPREAD
	aa_mode = AA_MODE_BILINEAR_NO_AA
	light_y_offset = 0.0
	light_z_offset = 0.0
	light_swap_time = 0.0
	star_global_scale = star_auto_scale
	_recenter_camera_angle()
	camera_drag_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_apply_viewport_aa_mode()
	_apply_aa_mode_to_all_cards()
	_update_overlay()

func _toggle_aa_mode():
	aa_mode = (aa_mode + 1) % 6
	_apply_viewport_aa_mode()
	_apply_aa_mode_to_all_cards()
	_update_overlay()

func _apply_viewport_aa_mode():
	var viewport := get_viewport()
	if viewport == null:
		return

	if aa_mode == AA_MODE_NEAREST_NO_AA or aa_mode == AA_MODE_NEAREST_SSAA or aa_mode == AA_MODE_BILINEAR_NO_AA:
		viewport.msaa_3d = Viewport.MSAA_DISABLED
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	else:
		viewport.msaa_3d = Viewport.MSAA_4X
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

func _apply_aa_mode_to_all_cards():
	for entry in left_fighters:
		_apply_aa_mode_to_card(entry)
	for entry in right_fighters:
		_apply_aa_mode_to_card(entry)

func _apply_aa_mode_to_card(entry: Dictionary):
	var node: MeshInstance3D = entry.get("node", null)
	if node == null:
		return
	var ssaa_nodes: Array = entry.get("ssaa_nodes", [])
	if node.material_override is StandardMaterial3D:
		var material: StandardMaterial3D = node.material_override
		if aa_mode == AA_MODE_LINEAR:
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		elif aa_mode == AA_MODE_BILINEAR_NO_AA:
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		elif aa_mode == AA_MODE_NEAREST_MIPMAP:
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		else:
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	if aa_mode == AA_MODE_LINEAR:
		node.visible = bool(entry.get("visible", true))
		for sample_node in ssaa_nodes:
			if sample_node is MeshInstance3D:
				sample_node.visible = false
	elif aa_mode == AA_MODE_POINT_SSAA or aa_mode == AA_MODE_NEAREST_SSAA:
		node.visible = false
		for sample_node in ssaa_nodes:
			if sample_node is MeshInstance3D:
				sample_node.visible = bool(entry.get("visible", true))
	else:
		node.visible = bool(entry.get("visible", true))
		for sample_node in ssaa_nodes:
			if sample_node is MeshInstance3D:
				sample_node.visible = false

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
	var step_x: float = WORLD_PER_PIXEL_X

	if not is_equal_approx(pos.x, base.x):
		hspd += -1.7

	for _px in range(int(abs(hspd))):
		if attack_dir > 0:
			if is_equal_approx(pos.x, base.x - step_x):
				break
			pos.x += signf(hspd) * step_x
		else:
			if is_equal_approx(pos.x, base.x + step_x):
				break
			pos.x -= signf(hspd) * step_x

	f["hspd"] = hspd
	f["pos"] = pos

	if absf(pos.x - base.x) <= step_x and hspd <= 0.0:
		f["pos"] = base
		f["hspd"] = 0.0
		f["is_attacking"] = false

func _simulate_vertical_jump(f: Dictionary):
	var pos: Vector3 = f["pos"]
	var base: Vector3 = f["base"]
	var vspd: float = float(f.get("vspd", 0.0))
	var step_y: float = WORLD_PER_PIXEL_Y

	if not is_equal_approx(pos.y, base.y):
		vspd -= 0.5
	else:
		vspd = 10.0

	for _py in range(int(abs(vspd))):
		if is_equal_approx(pos.y, base.y - step_y):
			vspd = 0.0
			pos.y = base.y
			break
		pos.y += signf(vspd) * step_y

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
	var side_sign: float = float(entry.get("side_sign", 0.0))
	var pos: Vector3 = _project_world_point(Vector3(entry.get("pos", Vector3.ZERO)), side_sign)
	var scale_factor: float = float(entry.get("card_scale", 1.0))
	node.position = pos
	node.scale = Vector3.ONE * scale_factor
	node.visible = bool(entry.get("visible", true))
	var _alpha: float = float(entry.get("alpha", 1.0))
	var mat := node.material_override
	if mat != null and mat is StandardMaterial3D:
		var col: Color = mat.albedo_color
		col.a = _alpha
		mat.albedo_color = col
	else:
		var tmp := _make_card_material(null)
		tmp.albedo_color = Color(1.0, 1.0, 1.0, _alpha)
		node.material_override = tmp
	# Keep all cards at a consistent non-billboard angle.
	node.rotation = Vector3.ZERO

	var frame_node: MeshInstance3D = entry.get("frame_node", null)
	if frame_node != null:
		frame_node.position = pos + Vector3(0.0, 0.0, CARD_FRAME_DEPTH_OFFSET)
		frame_node.scale = Vector3.ONE * scale_factor
		frame_node.visible = bool(entry.get("visible", true))
		frame_node.rotation = Vector3.ZERO
		if frame_node.material_override is StandardMaterial3D:
			var frame_material: StandardMaterial3D = frame_node.material_override
			var frame_col: Color = frame_material.albedo_color
			frame_col.a = _alpha
			frame_material.albedo_color = frame_col

	var shadow_box_node: Node3D = entry.get("shadow_box_node", null)
	if shadow_box_node != null:
		shadow_box_node.position = pos + Vector3(0.0, 0.0, CARD_SHADOW_MODEL_Z_OFFSET)
		shadow_box_node.scale = Vector3.ONE * scale_factor
		shadow_box_node.visible = bool(entry.get("visible", true))
		shadow_box_node.rotation = Vector3.ZERO

	var ssaa_nodes: Array = entry.get("ssaa_nodes", [])
	for i in range(ssaa_nodes.size()):
		var sample_node: MeshInstance3D = ssaa_nodes[i]
		if sample_node == null:
			continue
		var sample_offset: Vector2 = SSAA_SAMPLE_OFFSETS[i] if i < SSAA_SAMPLE_OFFSETS.size() else Vector2.ZERO
		sample_node.position = pos + Vector3(sample_offset.x * WORLD_PER_PIXEL_X, -sample_offset.y * WORLD_PER_PIXEL_Y, 0.0)
		sample_node.scale = Vector3.ONE * scale_factor
		sample_node.rotation = Vector3.ZERO
		if sample_node.material_override is StandardMaterial3D:
			var sample_material: StandardMaterial3D = sample_node.material_override
			sample_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			var sample_alpha: float = SSAA_SAMPLE_ALPHA if aa_mode == AA_MODE_POINT_SSAA else _alpha
			var sample_col: Color = sample_material.albedo_color
			sample_col.a = sample_alpha
			sample_material.albedo_color = sample_col
		if aa_mode == AA_MODE_POINT_SSAA:
			sample_node.visible = bool(entry.get("visible", true))

func _project_world_point(source: Vector3, side_sign: float) -> Vector3:
	var spread_world_x: float = horizontal_spread * (WORLD_VIEW_SIZE.x / DESIGN_SIZE.x)
	var spread_world_y: float = vertical_spread * (WORLD_VIEW_SIZE.y / DESIGN_SIZE.y)
	# Center-anchored vertical spread: cards move away from/toward screen center symmetrically.
	var center_anchor_y: float = 0.0
	var rel_to_center: float = source.y - center_anchor_y
	var half_height: float = WORLD_VIEW_SIZE.y * 0.5
	var vertical_factor: float = spread_world_y / maxf(0.001, half_height)
	# Depth drama: anchor the furthest-back row and move only nearer rows toward camera.
	var back_row_z: float = ROW_Z[ROWS_PER_COLUMN - 1]
	var depth_offset: float = source.z - back_row_z
	var depth_scale: float = maxf(0.0, dramatic_zoom)
	var adjusted_z: float = back_row_z + (depth_offset * depth_scale)
	return Vector3(
		source.x + (spread_world_x * side_sign),
		source.y + (rel_to_center * vertical_factor),
		adjusted_z
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
	if title_label != null:
		title_label.text = "BATTLE"

	if banner_label != null:
		if not battle_started:
			banner_label.text = "LEFT CLICK TO START"
			banner_label.modulate = Color(1.0, 0.95, 0.35)
		elif not battle_finished:
			banner_label.text = "RESOLVING..."
			banner_label.modulate = Color.WHITE
		else:
			banner_label.text = "VICTORY" if win_flag else "DEFEAT"
			banner_label.modulate = Color(0.2, 1.0, 0.2) if win_flag else Color(1.0, 0.2, 0.2)

	if debug_label != null:
		var star_info := ""
		if GameState.has_node("/root/StarfieldManager"):
			var counts: Dictionary = GameState.get_node("/root/StarfieldManager").get_star_type_counts()
			star_info = "\nStars F/M/S: %d/%d/%d  Total:%d" % [int(counts.get("fast", 0)), int(counts.get("mid", 0)), int(counts.get("slow", 0)), int(counts.get("total", 0))]
		var aa_label := "Linear + Mipmaps + AA"
		if aa_mode == AA_MODE_POINT_SSAA:
			aa_label = "Point + Manual SSAA"
		elif aa_mode == AA_MODE_NEAREST_NO_AA:
			aa_label = "Nearest + No AA"
		elif aa_mode == AA_MODE_NEAREST_MIPMAP:
			aa_label = "Nearest + Mipmapping"
		elif aa_mode == AA_MODE_NEAREST_SSAA:
			aa_label = "Nearest + SSAA"
		elif aa_mode == AA_MODE_BILINEAR_NO_AA:
			aa_label = "Bilinear + No AA"
		var light_info := ""
		if front_light_left != null:
			light_info = "\nFront Lights Y/Z: %.2f / %.2f (Numpad 8/5, Insert/Delete)" % [front_light_left.position.y, front_light_left.position.z]
		var star_scale_info := "\nStar Scale: %.2f (Numpad +/-)" % star_global_scale

		debug_label.text = "Depth Drama: %.2f (PageUp/PageDown)\nHorizontal Spread: %.1f (Left/Right)\nVertical Spread: %.1f (Up/Down)\nAA Mode: %s (Tab)%s%s%s\nRMB drag: orbit  Home: reset" % [dramatic_zoom, horizontal_spread, vertical_spread, aa_label, light_info, star_scale_info, star_info]
		debug_label.visible = show_perspective_debug

	if return_button != null:
		return_button.visible = return_visible
		return_button.disabled = not return_visible

func _setup_ambient_fx():
	pass

func _return_to_mission_select():
	GameState.reset_starfield_defaults()
	GameState.clear_starfield_particles()
	get_tree().change_scene_to_file("res://features/mission_select/scenes/mission_select.tscn")

func _exit_tree():
	GameState.set_starfield_enabled(true)
	camera_drag_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
