@tool
extends Node3D

const BASE_CHARACTER_Y := 790.0
const CAMERA_START_POS := Vector3(0.0, 0.0, 9.84)
const CAMERA_START_ROT := Vector3(0.0, 0.0, 0.0)
const CAMERA_DRAG_SENSITIVITY := 0.0035

@onready var character_root: Node2D = $CharacterViewport/Character2D
@onready var hip_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip
@onready var chest_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/Chest
@onready var head_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/Chest/Head
@onready var chin_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/Chest/Head/Chin
@onready var right_arm_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/Chest/RightArm
@onready var right_forearm_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/Chest/RightArm/RightForearm
@onready var left_arm_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/Chest/LeftArm
@onready var left_forearm_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/Chest/LeftArm/LeftForearm
@onready var left_leg_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/LeftLeg
@onready var left_lower_leg_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/LeftLeg/LeftLowerLeg
@onready var right_leg_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/RightLeg
@onready var right_lower_leg_bone: Bone2D = $CharacterViewport/Character2D/Sprite/Skeleton2D/Hip/RightLeg/RightLowerLeg
@onready var camera: Camera3D = $Camera3D
@onready var character_viewport: SubViewport = $CharacterViewport
@onready var character_screen: MeshInstance3D = $CharacterScreen
@onready var character_2d_root: Node2D = $CharacterViewport/Character2D
@onready var idle_animation_player: AnimationPlayer = $CharacterViewport/Character2D/IdleAnimationPlayer

var camera_rotation := Vector3.ZERO
var camera_drag_active := false
var _idle_time := 0.0
var _base_chest_rot := 0.0
var _base_head_rot := 0.0
var _base_chin_rot := 0.0
var _base_left_arm_rot := 0.0
var _base_right_arm_rot := 0.0

func _ready() -> void:
	set_process(true)
	camera_rotation = CAMERA_START_ROT
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 40.0
	camera.near = 0.1
	camera.far = 200.0
	camera.current = true
	_idle_time = 0.0
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
	_bind_character_viewport_texture()
	call_deferred("_play_editor_idle_animation")
	_update_camera_transform()

func _play_editor_idle_animation() -> void:
	if idle_animation_player == null:
		return
	idle_animation_player.root_node = NodePath("..")
	idle_animation_player.active = true
	idle_animation_player.speed_scale = 1.0
	if idle_animation_player.has_animation("idle_exact"):
		idle_animation_player.play("idle_exact")
		idle_animation_player.seek(0.0, true)

func _bind_character_viewport_texture() -> void:
	if character_screen == null or character_viewport == null:
		return
	var mat := character_screen.get_active_material(0)
	if mat == null or not (mat is StandardMaterial3D):
		mat = StandardMaterial3D.new()
		character_screen.set_surface_override_material(0, mat)
	var std_mat := mat as StandardMaterial3D
	std_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	std_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	std_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	std_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	std_mat.no_depth_test = false
	std_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	std_mat.albedo_texture = character_viewport.get_texture()

func _process(delta: float) -> void:
	character_root.position.y = BASE_CHARACTER_Y
	_idle_time += delta
	if idle_animation_player != null and idle_animation_player.has_animation("idle_exact") and not idle_animation_player.is_playing():
		idle_animation_player.play("idle_exact")
	if chest_bone != null:
		# Force visible idle motion every frame, even if AnimationPlayer state is stale.
		var wave := sin(_idle_time * TAU * 0.5)
		chest_bone.rotation = _base_chest_rot + deg_to_rad(8.0) * wave
		if head_bone != null:
			head_bone.rotation = _base_head_rot + deg_to_rad(10.0) * wave
		if chin_bone != null:
			chin_bone.rotation = _base_chin_rot - deg_to_rad(7.0) * wave
		if left_arm_bone != null:
			left_arm_bone.rotation = _base_left_arm_rot - deg_to_rad(12.0) * wave
		if right_arm_bone != null:
			right_arm_bone.rotation = _base_right_arm_rot + deg_to_rad(12.0) * wave
	_update_camera_transform()

func _update_camera_transform() -> void:
	camera.position = CAMERA_START_POS
	camera.rotation = camera_rotation

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var me: InputEventMouseButton = event
		if me.button_index == MOUSE_BUTTON_RIGHT:
			camera_drag_active = me.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if camera_drag_active else Input.MOUSE_MODE_VISIBLE
			return

	if event is InputEventMouseMotion and camera_drag_active:
		var mm: InputEventMouseMotion = event
		camera_rotation.y -= mm.relative.x * CAMERA_DRAG_SENSITIVITY
		camera_rotation.x -= mm.relative.y * CAMERA_DRAG_SENSITIVITY
		camera_rotation.x = clamp(camera_rotation.x, -PI / 2.0, PI / 2.0)
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and key_event.keycode == KEY_HOME:
			camera_rotation = CAMERA_START_ROT
			camera_drag_active = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
		if key_event.pressed and key_event.keycode == KEY_ESCAPE and camera_drag_active:
			camera_drag_active = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
