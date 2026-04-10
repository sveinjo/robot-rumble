@tool
extends Node2D

const WEIGHTED_TEXTURE: Texture2D = preload("res://assets/sprites/gBot.png")
const DEMO_PLAYER_SCENE: PackedScene = preload("res://features/fight_room/resources/gbot_animation_source.tscn")

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

var _idle_time := 0.0
var _base_hip_pos := Vector2.ZERO
var _base_chest_rot := 0.0
var _base_head_rot := 0.0
var _base_chin_rot := 0.0
var _base_left_arm_rot := 0.0
var _base_right_arm_rot := 0.0
var _available_animations: Array[StringName] = []
var _current_animation_index := -1

func _ready() -> void:
	set_process(true)
	set_process_input(true)
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
	if polygons_root != null:
		polygons_root.visible = true
		_ensure_weighted_mesh_links()
	if idle_animation_player != null:
		idle_animation_player.root_node = NodePath("..")
		_import_demo_animations()
		_play_start_animation()

func _process(delta: float) -> void:
	_idle_time += delta
	if idle_animation_player != null and _current_animation_index >= 0 and _current_animation_index < _available_animations.size() and not idle_animation_player.is_playing():
		idle_animation_player.play(_available_animations[_current_animation_index])

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_TAB:
			_next_animation()

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
	if source_library == null or target_library == null:
		demo_instance.free()
		return
	_available_animations.clear()
	for animation_name in source_library.get_animation_list():
		var source_animation := source_library.get_animation(animation_name)
		if source_animation == null:
			continue
		var copied_animation := source_animation.duplicate(true) as Animation
		if target_library.has_animation(animation_name):
			target_library.remove_animation(animation_name)
		target_library.add_animation(animation_name, copied_animation)
		_available_animations.append(animation_name)
	demo_instance.free()
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
	if idle_animation_player.has_animation(&"idle"):
		_current_animation_index = _available_animations.find(&"idle")
		if _current_animation_index == -1:
			_current_animation_index = 0
	elif _available_animations.size() > 0:
		_current_animation_index = 0
	else:
		_current_animation_index = -1
	if _current_animation_index >= 0 and _current_animation_index < _available_animations.size():
		idle_animation_player.play(_available_animations[_current_animation_index])

func _next_animation() -> void:
	if idle_animation_player == null or _available_animations.is_empty():
		return
	_current_animation_index = (_current_animation_index + 1) % _available_animations.size()
	var animation_name := _available_animations[_current_animation_index]
	idle_animation_player.play(animation_name)
	print("[fight_room_skeleton2d_direct] Animation: ", animation_name)

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
