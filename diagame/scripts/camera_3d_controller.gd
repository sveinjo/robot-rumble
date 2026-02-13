extends Camera3D

# 3D camera controller with mouse rotation
var mouse_sensitivity: float = 0.003
var rotation_enabled: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var camera_rotation: Vector3 = Vector3.ZERO  # Pitch, Yaw, Roll

func _ready():
	# Position camera to view the 3D plane which is at z=0
	# Camera is at (0, 0, 15) looking at origin
	position = Vector3(0, 0, 15)
	look_at(Vector3.ZERO, Vector3.UP)
	
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
	
	# Rotate camera based on mouse movement
	if event is InputEventMouseMotion and rotation_enabled:
		var delta_mouse = event.relative
		
		# Yaw (left/right rotation around Y axis)
		camera_rotation.y -= delta_mouse.x * mouse_sensitivity
		
		# Pitch (up/down rotation around X axis)
		camera_rotation.x -= delta_mouse.y * mouse_sensitivity
		
		# Clamp pitch to avoid flipping
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)
		
		# Apply rotation
		rotation = camera_rotation

func reset_camera():
	"""Reset camera to initial position and rotation"""
	rotation = Vector3.ZERO
	camera_rotation = Vector3.ZERO
	print("Camera reset to initial position")

func _process(_delta):
	# Release mouse if escape is pressed
	if Input.is_action_just_pressed("ui_cancel") and rotation_enabled:
		rotation_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
