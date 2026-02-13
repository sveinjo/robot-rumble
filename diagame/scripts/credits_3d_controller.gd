extends Node3D

# Script to project the viewport texture to all walls simultaneously

@onready var viewport = $SubViewport
@onready var screen_front = $Screen3D
@onready var screen_right = $Screen3D_Right
@onready var screen_left = $Screen3D_Left
@onready var screen_back = $Screen3D_Back

var walls = []

func _ready():
	# Load and instance the 2D credits scene into the viewport
	var credits_scene = load("res://scenes/credits.tscn")
	var credits_instance = credits_scene.instantiate()
	viewport.add_child(credits_instance)
	
	# Ensure viewport updates
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	walls = [screen_front, screen_right, screen_left, screen_back]
	
	# Set texture to all walls
	set_texture_to_all_walls()

func set_texture_to_all_walls():
	for wall in walls:
		var mat = wall.get_surface_override_material(0)
		if mat and viewport:
			mat.albedo_texture = viewport.get_texture()