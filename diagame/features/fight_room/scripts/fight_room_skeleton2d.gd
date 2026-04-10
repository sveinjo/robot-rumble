extends Node3D

const BASE_CHARACTER_Y := 610.0
const CAMERA_START_POS := Vector3(0.0, 0.0, 9.84)
const CAMERA_START_ROT := Vector3(0.0, 0.0, 0.0)
const CAMERA_DRAG_SENSITIVITY := 0.0035

@onready var character_root: Node2D = $CharacterViewport/Character2D
@onready var torso_bone: Bone2D = $CharacterViewport/Character2D/Skeleton2D/RootBone/TorsoBone
@onready var head_bone: Bone2D = $CharacterViewport/Character2D/Skeleton2D/RootBone/TorsoBone/HeadBone
@onready var arm_bone: Bone2D = $CharacterViewport/Character2D/Skeleton2D/RootBone/ArmBone
@onready var camera: Camera3D = $Camera3D

var elapsed := 0.0
var camera_rotation := Vector3.ZERO
var camera_drag_active := false

func _ready() -> void:
	camera_rotation = CAMERA_START_ROT
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 40.0
	camera.near = 0.1
	camera.far = 200.0
	camera.current = true
	_update_camera_transform()

func _process(delta: float) -> void:
	elapsed += delta
	character_root.position.y = BASE_CHARACTER_Y + sin(elapsed * 1.8) * 14.0
	torso_bone.rotation = sin(elapsed * 1.8) * 0.12
	head_bone.rotation = sin(elapsed * 1.8 + 0.5) * 0.08
	arm_bone.rotation = sin(elapsed * 3.2) * 0.45
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
		if key_event.pressed and key_event.keycode == KEY_ESCAPE and camera_drag_active:
			camera_drag_active = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
