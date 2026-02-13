extends Camera3D

# 3D camera controller with mouse rotation and keyboard movement
var mouse_sensitivity: float = 0.003
var movement_speed: float = 25.0
var rotation_enabled: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var camera_rotation: Vector3 = Vector3.ZERO  # Pitch, Yaw, Roll
var is_rotating: bool = false

func _ready():
	# Position camera to view the 3D plane which is at z=0
	# Camera is at (0, 0, 11.6) looking at origin
	position = Vector3(0, 0, 9.6)
	look_at(Vector3(0, 0, 0), Vector3.UP)
	
	# Store initial rotation
	camera_rotation = rotation
	
	# Start with mouse visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event):
	# Enable rotation when right mouse button is pressed
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotation_enabled = event.pressed
			if rotation_enabled:
				last_mouse_position = event.position
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if rotation_enabled else Input.MOUSE_MODE_VISIBLE
	
	# Reset camera to initial position with Home key
	if event is InputEventKey and event.keycode == KEY_HOME and event.pressed:
		reset_camera()
	
	# Rotate camera 90 degrees right with Page Down
	if event is InputEventKey and event.keycode == KEY_PAGEDOWN and event.pressed and not is_rotating:
		rotate_90_degrees_left()
	
	# Rotate camera 90 degrees left with Delete
	if event is InputEventKey and event.keycode == KEY_DELETE and event.pressed and not is_rotating:
		rotate_90_degrees_right()
	
	# Rotate camera based on mouse movement
	if event is InputEventMouseMotion and rotation_enabled:
		var delta_mouse = event.relative
		
		# Yaw (left/right rotation around Y axis)
		camera_rotation.y -= delta_mouse.x * mouse_sensitivity
		
		# Pitch (up/down rotation around X axis)
		camera_rotation.x -= delta_mouse.y * mouse_sensitivity
		
		# Clamp pitch to avoid flipping
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)

func reset_camera():
	"""Reset camera to initial position and rotation"""
	position = Vector3(0, 0, 9.6)
	rotation = Vector3.ZERO
	camera_rotation = Vector3.ZERO
	print("Camera reset to initial position")

func rotate_90_degrees_left():
	"""Rotate camera 90 degrees to the left with smooth animation"""
	if is_rotating:
		return  # Already rotating
	
	is_rotating = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)  # Quadratic easing for acceleration/deceleration
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var target_y = camera_rotation.y - PI / 2  # 90 degrees in radians (left)
	tween.tween_property(self, "camera_rotation:y", target_y, 1.0)  # 1 second duration
	
	# Connect to finished signal to reset flag
	tween.finished.connect(func(): is_rotating = false)

func rotate_90_degrees_right():
	"""Rotate camera 90 degrees to the right with smooth animation"""
	if is_rotating:
		return  # Already rotating
	
	is_rotating = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)  # Quadratic easing for acceleration/deceleration
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var target_y = camera_rotation.y + PI / 2  # 90 degrees in radians (right)
	tween.tween_property(self, "camera_rotation:y", target_y, 1.0)  # 1 second duration
	
	# Connect to finished signal to reset flag
	tween.finished.connect(func(): is_rotating = false)

func _process(delta):
	# Handle keyboard movement
	var move_vector = Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vector.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vector.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vector.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vector.x += 1
	if Input.is_key_pressed(KEY_Q):
		move_vector.y += 1
	if Input.is_key_pressed(KEY_E):
		move_vector.y -= 1
	
	# Normalize and apply movement
	if move_vector.length() > 0:
		move_vector = move_vector.normalized() * movement_speed * delta
		# Transform movement relative to camera orientation
		var forward = -transform.basis.z
		var right = transform.basis.x
		var up = transform.basis.y
		
		position += forward * move_vector.z + right * move_vector.x + up * move_vector.y
	
	# Apply current rotation
	rotation = camera_rotation
	
	# Release mouse if escape is pressed
	if Input.is_action_just_pressed("ui_cancel") and rotation_enabled:
		rotation_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
