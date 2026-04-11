@tool
extends Node2D

const WEIGHTED_TEXTURE: Texture2D = preload("res://assets/sprites/gBot.png")
const DEMO_PLAYER_SCENE: PackedScene = preload("res://features/fight_room/resources/gbot_animation_source.tscn")
const REAPER_SCENE: PackedScene = preload("res://assets/SCML/reaper.tscn")
const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const STAR_SPAWN_INTERVAL := 1.0 / 60.0
const STAR_SPEED_MULTIPLIERS: Array[int] = [4, 2, 1]
const STAR_TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/Star1d_0.png"),
	preload("res://assets/sprites/Star2d_0.png"),
	preload("res://assets/sprites/Star3d_0.png"),
]

@onready var idle_animation_player: AnimationPlayer = $Character2D/IdleAnimationPlayer
@onready var skeleton_2d: Skeleton2D = $Character2D/Sprite/Skeleton2D
@onready var polygons_root: Node2D = $Character2D/Sprite/Polygons
@onready var body_weighted: Polygon2D = $Character2D/Sprite/Polygons/BodyWeighted
@onready var head_weighted: Polygon2D = $Character2D/Sprite/Polygons/HeadWeighted
@onready var chin_weighted: Polygon2D = $Character2D/Sprite/Polygons/ChinWeighted
@onready var left_arm_weighted: Polygon2D = $Character2D/Sprite/Polygons/LeftArmWeighted
@onready var right_arm_weighted: Polygon2D = $Character2D/Sprite/Polygons/RightArmWeighted
@onready var left_leg_weighted: Polygon2D = $Character2D/Sprite/Polygons/LeftLegWeighted
@onready var right_leg_weighted: Polygon2D = $Character2D/Sprite/Polygons/RightLegWeighted
@onready var hip_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip
@onready var chest_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/Chest
@onready var head_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/Chest/Head
@onready var chin_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/Chest/Head/Chin
@onready var left_arm_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/Chest/LeftArm
@onready var right_arm_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/Chest/RightArm
@onready var left_leg_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/LeftLeg
@onready var left_lower_leg_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/LeftLeg/LeftLowerLeg
@onready var left_foot_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/LeftLeg/LeftLowerLeg/LeftFoot
@onready var right_leg_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/RightLeg
@onready var right_lower_leg_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/RightLeg/RightLowerLeg
@onready var right_foot_bone: Bone2D = $Character2D/Sprite/Skeleton2D/Hip/RightLeg/RightLowerLeg/RightFoot
@onready var stars_root: Node2D = $Stars
@onready var character_2d: Node2D = $Character2D

@export var show_starfield: bool = true
@export var star_spawn_interval: float = STAR_SPAWN_INTERVAL
@export var star_speed: float = 2.0
@export var star_size: float = 1.0

var _idle_time := 0.0
var _base_hip_pos := Vector2.ZERO
var _base_chest_rot := 0.0
var _base_head_rot := 0.0
var _base_chin_rot := 0.0
var _base_left_arm_rot := 0.0
var _base_right_arm_rot := 0.0
var _available_animations: Array[StringName] = []
var _current_animation_index := -1
var _animation_label: Label = null
var _star_rng := RandomNumberGenerator.new()
var _star_spawn_timer: float = STAR_SPAWN_INTERVAL
var _reaper_instance: Node2D = null
var _reaper_animation_player: AnimationPlayer = null

func _ready() -> void:
	_setup_reaper_character()
	if Engine.is_editor_hint():
		set_process(false)
		set_process_input(false)
		return

	_setup_starfield()
	set_process(true)
	set_process_input(true)
	_ensure_animation_label()
	if _reaper_animation_player == null:
		if hip_bone != null:
			_base_hip_pos = hip_bone.position
		if chest_bone != null:
			_base_chest_rot = chest_bone.rotation
		if head_bone != null:
			_base_head_rot = head_bone.rotation
		if chin_bone != null:
			_base_chin_rot = chin_bone.rotation
		if left_arm_bone != null:
			_base_left_arm_rot = left_arm_bone.rotation
		if right_arm_bone != null:
			_base_right_arm_rot = right_arm_bone.rotation
		_normalize_leg_bone_scale()
		if polygons_root != null:
			polygons_root.visible = true
			_ensure_weighted_mesh_links()
		if idle_animation_player != null:
			idle_animation_player.root_node = NodePath("..")
			_import_demo_animations()
			_play_start_animation()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_starfield(delta)
	if _reaper_animation_player != null and not _reaper_animation_player.is_playing():
		_play_reaper_default_animation()
		return
	_idle_time += delta
	if idle_animation_player != null and _current_animation_index >= 0 and _current_animation_index < _available_animations.size() and not idle_animation_player.is_playing():
		var animation_name := _available_animations[_current_animation_index]
		idle_animation_player.play(animation_name)
		_set_animation_label(animation_name)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _reaper_animation_player != null:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_TAB:
			_next_animation()

func _setup_starfield() -> void:
	if stars_root == null:
		return

	_star_rng.randomize()
	_star_spawn_timer = maxf(0.01, star_spawn_interval)
	stars_root.z_index = -5
	_clear_starfield()
	stars_root.visible = show_starfield
	if not show_starfield:
		return

func _spawn_star(spawn_at_random_x: bool = false) -> void:
	if stars_root == null:
		return

	var star_tier: int = _star_rng.randi_range(0, 2)
	var speed_multiplier: float = STAR_SPEED_MULTIPLIERS[star_tier]

	var star := Sprite2D.new()
	star.texture = STAR_TEXTURES[star_tier]
	# Keep large/slow stars in the foreground; smaller tiers stay behind the robot.
	star.z_index = 10 if star_tier == 0 else 0
	star.scale = Vector2(star_size, star.scale.y)
	star.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = DESIGN_SIZE
	if spawn_at_random_x:
		star.position = Vector2(_star_rng.randf_range(0.0, viewport_size.x), _star_rng.randf_range(0.0, viewport_size.y))
	else:
		star.position = Vector2(viewport_size.x, _star_rng.randf_range(0.0, viewport_size.y))
	star.set_meta("speed_multiplier", speed_multiplier)
	stars_root.add_child(star)

func _update_starfield(delta: float) -> void:
	if stars_root == null:
		return

	if not show_starfield:
		stars_root.visible = false
		return

	stars_root.visible = true
	if star_speed < 14.0:
		star_speed = min(14.0, star_speed * 1.05)
	if star_size < 10.0:
		star_size = min(10.0, star_size * 1.05)

	_star_spawn_timer -= delta
	var safe_interval: float = maxf(0.01, star_spawn_interval)
	while _star_spawn_timer <= 0.0:
		_spawn_star(false)
		_star_spawn_timer += safe_interval

	var step_scale: float = delta * 60.0
	for star in stars_root.get_children():
		if not (star is Sprite2D):
			continue
		var star_sprite := star as Sprite2D
		var speed_multiplier: int = int(star_sprite.get_meta("speed_multiplier", 1))
		star_sprite.position.x += -star_speed * float(speed_multiplier) * step_scale
		star_sprite.scale.x = star_size
		var texture_width: float = float(star_sprite.texture.get_width()) if star_sprite.texture != null else 0.0
		if star_sprite.position.x <= -texture_width:
			star_sprite.queue_free()

func _clear_starfield() -> void:
	for child in stars_root.get_children():
		child.queue_free()

func _setup_reaper_character() -> void:
	if REAPER_SCENE == null:
		return
	if character_2d != null:
		character_2d.visible = false
	if _reaper_instance == null:
		_reaper_instance = get_node_or_null("ReaperActor") as Node2D
	if _reaper_instance == null:
		var instance := REAPER_SCENE.instantiate() as Node2D
		if instance == null:
			return
		instance.name = "ReaperActor"
		if character_2d != null:
			instance.position = character_2d.position
		add_child(instance)
		_reaper_instance = instance
	_reaper_animation_player = _reaper_instance.get_node_or_null("Skeleton/AnimationPlayer") as AnimationPlayer
	_play_reaper_default_animation()

func _play_reaper_default_animation() -> void:
	if _reaper_animation_player == null:
		return
	var preferred_candidates: Array[StringName] = [
		&"Laugh_loop",
		&"laugh_loop",
		&"scml/Laugh_loop",
		&"scml/laugh_loop",
	]
	var chosen_animation: StringName = &""
	for animation_name in preferred_candidates:
		if _reaper_animation_player.has_animation(animation_name):
			chosen_animation = animation_name
			break
	if chosen_animation == &"":
		for animation_name in _reaper_animation_player.get_animation_list():
			var animation_text := String(animation_name).to_lower()
			if animation_text.ends_with("/laugh_loop") or animation_text == "laugh_loop":
				chosen_animation = animation_name
				break
	if chosen_animation == &"":
		return
	var animation := _reaper_animation_player.get_animation(chosen_animation)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
	_reaper_animation_player.active = true
	_reaper_animation_player.play(chosen_animation)
	_set_animation_label(chosen_animation)

func _import_demo_animations() -> void:
	if idle_animation_player == null:
		return
	var demo_instance := DEMO_PLAYER_SCENE.instantiate()
	var demo_player := demo_instance.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if demo_player == null:
		demo_instance.free()
		return
	var source_library := _get_default_library(demo_player)
	var target_library := _get_or_create_default_library(idle_animation_player)
	if target_library == null:
		demo_instance.free()
		return
	_available_animations.clear()
	var source_animation_names: Array[StringName] = []
	if source_library != null:
		for animation_name in source_library.get_animation_list():
			source_animation_names.append(animation_name)
	else:
		for animation_name in demo_player.get_animation_list():
			source_animation_names.append(animation_name)

	for animation_name in source_animation_names:
		var source_animation: Animation = null
		if source_library != null:
			source_animation = source_library.get_animation(animation_name)
		else:
			source_animation = demo_player.get_animation(animation_name)
		if source_animation == null:
			continue
		var copied_animation := source_animation.duplicate(true) as Animation
		for track_idx in range(copied_animation.get_track_count() - 1, -1, -1):
			if copied_animation.track_get_key_count(track_idx) == 0:
				copied_animation.remove_track(track_idx)
		if target_library.has_animation(animation_name):
			target_library.remove_animation(animation_name)
		target_library.add_animation(animation_name, copied_animation)
	demo_instance.free()
	_available_animations.clear()
	for animation_name in idle_animation_player.get_animation_list():
		_available_animations.append(animation_name)
	_available_animations.sort()

func _get_default_library(player: AnimationPlayer) -> AnimationLibrary:
	if player == null:
		return null
	if player.has_animation_library(&""):
		return player.get_animation_library(&"")
	for library_name in player.get_animation_library_list():
		return player.get_animation_library(library_name)
	return null

func _get_or_create_default_library(player: AnimationPlayer) -> AnimationLibrary:
	if player == null:
		return null
	if player.has_animation_library(&""):
		return player.get_animation_library(&"")
	var default_library := AnimationLibrary.new()
	player.add_animation_library(&"", default_library)
	return default_library

func _play_start_animation() -> void:
	if idle_animation_player == null:
		return
	if idle_animation_player.has_animation(&"run"):
		_current_animation_index = _available_animations.find(&"run")
		if _current_animation_index == -1:
			_current_animation_index = 0
	elif idle_animation_player.has_animation(&"walk"):
		_current_animation_index = _available_animations.find(&"walk")
		if _current_animation_index == -1:
			_current_animation_index = 0
	elif idle_animation_player.has_animation(&"idle"):
		_current_animation_index = _available_animations.find(&"idle")
		if _current_animation_index == -1:
			_current_animation_index = 0
	elif _available_animations.size() > 0:
		_current_animation_index = 0
	else:
		_current_animation_index = -1
	if _current_animation_index >= 0 and _current_animation_index < _available_animations.size():
		var animation_name := _available_animations[_current_animation_index]
		idle_animation_player.play(animation_name)
		_set_animation_label(animation_name)

func _next_animation() -> void:
	if idle_animation_player == null or _available_animations.is_empty():
		return
	_current_animation_index = (_current_animation_index + 1) % _available_animations.size()
	var animation_name := _available_animations[_current_animation_index]
	idle_animation_player.play(animation_name)
	_set_animation_label(animation_name)
	print("[fight_room_skeleton2d_direct] Animation: ", animation_name)

func _ensure_animation_label() -> void:
	if Engine.is_editor_hint():
		return
	var hud := get_node_or_null("AnimationHud") as CanvasLayer
	if hud == null:
		hud = CanvasLayer.new()
		hud.name = "AnimationHud"
		add_child(hud)
	var label := hud.get_node_or_null("AnimationLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "AnimationLabel"
		hud.add_child(label)
		label.position = Vector2(12, 10)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 2)
	_animation_label = label
	_set_animation_label(&"-")

func _set_animation_label(animation_name: StringName) -> void:
	if _animation_label == null:
		return
	_animation_label.text = "Animation: %s" % String(animation_name)

func _ensure_weighted_mesh_links() -> void:
	if skeleton_2d == null:
		return
	var weighted: Array[Polygon2D] = [
		body_weighted,
		head_weighted,
		chin_weighted,
		left_arm_weighted,
		right_arm_weighted,
		left_leg_weighted,
		right_leg_weighted,
	]
	for mesh in weighted:
		if mesh == null:
			continue
		mesh.visible = true
		mesh.texture = WEIGHTED_TEXTURE
		mesh.modulate = Color(1, 1, 1, 1)
		mesh.skeleton = mesh.get_path_to(skeleton_2d)

func _normalize_leg_bone_scale() -> void:
	var leg_bones: Array[Bone2D] = [
		left_leg_bone,
		left_lower_leg_bone,
		left_foot_bone,
		right_leg_bone,
		right_lower_leg_bone,
		right_foot_bone,
	]
	for bone in leg_bones:
		if bone == null:
			continue
		bone.scale = Vector2.ONE
